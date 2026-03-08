import Foundation
import AppKit

// MARK: - OuraManager
//
// OAuth 2.0 authorization_code flow for Oura API v2.
//
// Setup (one-time):
//   1. Register at cloud.ouraring.com/oauth/applications
//   2. Set redirect URI: kairos://oauth/callback
//   3. Paste client_id + client_secret into the Body panel
//
// After setup, tap "Authorize" — browser opens, user approves,
// macOS delivers kairos://oauth/callback?code=… to the app,
// tokens are exchanged and stored in Keychain.
// Access tokens are auto-refreshed before expiry.

@MainActor
final class OuraManager: ObservableObject {
    static let shared = OuraManager()

    @Published var isConfigured: Bool = false   // has client_id + client_secret
    @Published var isAuthorized: Bool = false   // has stored access token
    @Published var snapshot: HealthSnapshot?
    @Published var monthlySnapshots: [Date: HealthSnapshot] = [:]
    @Published var isFetching: Bool = false
    @Published var fetchError: String?

    static let redirectURI = "kairos://oauth/callback"
    private static let authURL   = "https://cloud.ouraring.com/oauth/authorize"
    private static let tokenURL  = "https://api.ouraring.com/oauth/token"
    private static let scope     = "daily heartrate personal"

    private static let kClientId     = "oura-client-id"
    private static let kClientSecret = "oura-client-secret"
    private static let kAccessToken  = "oura-access-token"
    private static let kRefreshToken = "oura-refresh-token"
    private static let kTokenExpiry  = "oura-token-expiry"

    private init() {
        isConfigured = OuraKeychain.load(forKey: OuraManager.kClientId) != nil
        isAuthorized = OuraKeychain.load(forKey: OuraManager.kAccessToken) != nil
    }

    // MARK: - Credential setup

    func saveCredentials(clientId: String, clientSecret: String) {
        let id  = clientId.trimmingCharacters(in: .whitespacesAndNewlines)
        let sec = clientSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty, !sec.isEmpty else { return }
        OuraKeychain.save(id,  forKey: OuraManager.kClientId)
        OuraKeychain.save(sec, forKey: OuraManager.kClientSecret)
        isConfigured = true
    }

    // MARK: - OAuth: step 1 — open browser

    func startAuthorization() {
        guard let clientId = OuraKeychain.load(forKey: OuraManager.kClientId) else { return }
        let state = UUID().uuidString
        UserDefaults.standard.set(state, forKey: "oura-oauth-state")

        var comps = URLComponents(string: OuraManager.authURL)!
        comps.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id",     value: clientId),
            URLQueryItem(name: "redirect_uri",  value: OuraManager.redirectURI),
            URLQueryItem(name: "scope",         value: OuraManager.scope),
            URLQueryItem(name: "state",         value: state)
        ]
        guard let url = comps.url else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - OAuth: step 2 — handle callback from kairos://oauth/callback

    func handleCallback(url: URL) async {
        guard url.scheme?.lowercased() == "kairos",
              url.host == "oauth",
              url.path == "/callback"
        else { return }

        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        let params = Dictionary(
            (comps.queryItems ?? []).compactMap { item in item.value.map { (item.name, $0) } },
            uniquingKeysWith: { first, _ in first }
        )

        guard let code  = params["code"],
              let state = params["state"],
              state == UserDefaults.standard.string(forKey: "oura-oauth-state")
        else {
            fetchError = "OAuth callback was invalid or state mismatch."
            return
        }

        UserDefaults.standard.removeObject(forKey: "oura-oauth-state")
        await exchangeCode(code)
    }

    // MARK: - Token exchange

    private func exchangeCode(_ code: String) async {
        guard let clientId     = OuraKeychain.load(forKey: OuraManager.kClientId),
              let clientSecret = OuraKeychain.load(forKey: OuraManager.kClientSecret)
        else { return }

        let params: [String: String] = [
            "grant_type":    "authorization_code",
            "code":          code,
            "redirect_uri":  OuraManager.redirectURI,
            "client_id":     clientId,
            "client_secret": clientSecret
        ]
        await performTokenRequest(params)
    }

    // MARK: - Token refresh

    private func refreshTokens() async throws -> String {
        guard let refresh      = OuraKeychain.load(forKey: OuraManager.kRefreshToken),
              let clientId     = OuraKeychain.load(forKey: OuraManager.kClientId),
              let clientSecret = OuraKeychain.load(forKey: OuraManager.kClientSecret)
        else { throw OuraError.noCredentials }

        let params: [String: String] = [
            "grant_type":    "refresh_token",
            "refresh_token": refresh,
            "client_id":     clientId,
            "client_secret": clientSecret
        ]
        var req = URLRequest(url: URL(string: OuraManager.tokenURL)!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = formEncode(params).data(using: .utf8)

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw OuraError.httpError(http.statusCode)
        }
        let token = try JSONDecoder().decode(OuraTokenResponse.self, from: data)
        storeTokens(token)
        return token.accessToken
    }

    // MARK: - Valid access token (auto-refreshes)

    func validAccessToken() async throws -> String {
        if let expiryStr = OuraKeychain.load(forKey: OuraManager.kTokenExpiry),
           let expiryTS  = Double(expiryStr) {
            let expiry = Date(timeIntervalSince1970: expiryTS)
            if expiry < Date().addingTimeInterval(60) {
                return try await refreshTokens()
            }
        }
        guard let token = OuraKeychain.load(forKey: OuraManager.kAccessToken) else {
            throw OuraError.notAuthorized
        }
        return token
    }

    // MARK: - Revoke

    /// Clears tokens only — keeps credentials so user can re-authorize without re-entering client_id/secret
    func disconnectTokens() {
        for key in [OuraManager.kAccessToken, OuraManager.kRefreshToken, OuraManager.kTokenExpiry] {
            OuraKeychain.delete(forKey: key)
        }
        isAuthorized = false
        snapshot = nil
        fetchError = nil
    }

    /// Clears everything — user must re-enter client_id/secret
    func resetAll() {
        for key in [OuraManager.kClientId, OuraManager.kClientSecret,
                    OuraManager.kAccessToken, OuraManager.kRefreshToken, OuraManager.kTokenExpiry] {
            OuraKeychain.delete(forKey: key)
        }
        isConfigured = false
        isAuthorized = false
        snapshot = nil
        monthlySnapshots = [:]
        fetchError = nil
    }

    // MARK: - Fetch

    func fetchCurrentSnapshot() async {
        do {
            let token = try await validAccessToken()
            let end   = Date()
            let start = Calendar.current.date(byAdding: .day, value: -30, to: end) ?? end
            isFetching = true
            fetchError = nil
            snapshot = try await OuraAPIClient(accessToken: token).buildSnapshot(from: start, to: end)
        } catch {
            fetchError = error.localizedDescription
            if case OuraError.httpError(401) = error { disconnectTokens() }
        }
        isFetching = false
    }

    func fetchMonthlyHistory(months: Int = 24) async {
        guard let token = try? await validAccessToken() else { return }
        let client = OuraAPIClient(accessToken: token)
        let cal    = Calendar.current
        let now    = Date()
        var result: [Date: HealthSnapshot] = [:]

        await withTaskGroup(of: (Date, HealthSnapshot?).self) { group in
            for i in 0..<months {
                guard let mStart = cal.date(byAdding: .month, value: -i, to: now.startOfMonth) else { continue }
                let mEnd = cal.date(byAdding: .month, value: 1, to: mStart) ?? now
                group.addTask {
                    let snap = try? await client.buildSnapshot(from: mStart, to: mEnd)
                    return (mStart, snap)
                }
            }
            for await (date, snap) in group {
                if let snap { result[date] = snap }
            }
        }
        monthlySnapshots = result
    }

    // MARK: - Private helpers

    private func performTokenRequest(_ params: [String: String]) async {
        var req = URLRequest(url: URL(string: OuraManager.tokenURL)!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = formEncode(params).data(using: .utf8)

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                fetchError = "Token exchange failed (HTTP \(http.statusCode))."
                return
            }
            let token = try JSONDecoder().decode(OuraTokenResponse.self, from: data)
            storeTokens(token)
            isAuthorized = true
            fetchError = nil
            await fetchCurrentSnapshot()
        } catch {
            fetchError = "Token exchange failed: \(error.localizedDescription)"
        }
    }

    private func storeTokens(_ response: OuraTokenResponse) {
        OuraKeychain.save(response.accessToken, forKey: OuraManager.kAccessToken)
        if let refresh = response.refreshToken {
            OuraKeychain.save(refresh, forKey: OuraManager.kRefreshToken)
        }
        if let expiresIn = response.expiresIn {
            let expiry = Date().addingTimeInterval(Double(expiresIn))
            OuraKeychain.save(String(expiry.timeIntervalSince1970), forKey: OuraManager.kTokenExpiry)
        }
    }
}

// MARK: - Helpers

private func formEncode(_ params: [String: String]) -> String {
    let safe = CharacterSet.alphanumerics.union(.init(charactersIn: "-._~"))
    return params.map { key, value in
        let k = key.addingPercentEncoding(withAllowedCharacters: safe) ?? key
        let v = value.addingPercentEncoding(withAllowedCharacters: safe) ?? value
        return "\(k)=\(v)"
    }.joined(separator: "&")
}

private extension Date {
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }
}
