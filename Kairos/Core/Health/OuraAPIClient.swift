import Foundation
import Security

// MARK: - Keychain (multi-key)

enum OuraKeychain {
    static let service = "com.damianspendel.kairos"

    static func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        let q: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecValueData: data
        ]
        SecItemDelete(q as CFDictionary)
        SecItemAdd(q as CFDictionary, nil)
    }

    static func load(forKey key: String) -> String? {
        let q: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(forKey key: String) {
        let q: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        SecItemDelete(q as CFDictionary)
    }
}

// MARK: - Token response (from /oauth/token)

struct OuraTokenResponse: Decodable {
    let accessToken:  String
    let tokenType:    String
    let expiresIn:    Int?
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case tokenType    = "token_type"
        case expiresIn    = "expires_in"
        case refreshToken = "refresh_token"
    }
}

// MARK: - Oura API v2 data models (private)

private struct OuraPaginated<T: Decodable>: Decodable { let data: [T] }

// /v2/usercollection/sleep — detailed session data (raw metrics, durations)
// Use this, NOT daily_sleep which only contains score/contributor percentages.
private struct OuraSleepItem: Decodable {
    let day:                String
    let type:               String  // "long_sleep" | "short_sleep" | "deleted"
    let totalSleepDuration: Int?    // seconds
    let deepSleepDuration:  Int?
    let remSleepDuration:   Int?
    let averageHrv:         Int?    // RMSSD ms
    let lowestHeartRate:    Int?    // resting HR
    let averageBreath:      Double? // breaths/min

    var isMainSleep: Bool { type == "long_sleep" }

    enum CodingKeys: String, CodingKey {
        case day
        case type
        case totalSleepDuration = "total_sleep_duration"
        case deepSleepDuration  = "deep_sleep_duration"
        case remSleepDuration   = "rem_sleep_duration"
        case averageHrv         = "average_hrv"
        case lowestHeartRate    = "lowest_heart_rate"
        case averageBreath      = "average_breath"
    }
}

// /v2/usercollection/daily_readiness — overall recovery score + HRV balance
private struct OuraReadinessItem: Decodable {
    let day:   String
    let score: Int?

    enum CodingKeys: String, CodingKey {
        case day
        case score
    }
}

private struct OuraActivityItem: Decodable {
    let day:            String
    let steps:          Int?
    let activeCalories: Int?

    enum CodingKeys: String, CodingKey {
        case day
        case steps
        case activeCalories = "active_calories"
    }
}

private struct OuraVo2MaxItem: Decodable {
    let day:    String
    let vo2Max: Double?

    enum CodingKeys: String, CodingKey {
        case day
        case vo2Max = "vo2_max"
    }
}

// MARK: - Errors

enum OuraError: LocalizedError {
    case httpError(Int)
    case notAuthorized
    case noCredentials

    var errorDescription: String? {
        switch self {
        case .httpError(401): return "Oura authorization expired — reconnect in the Body panel."
        case .httpError(let c): return "Oura API error (HTTP \(c))."
        case .notAuthorized: return "Not connected to Oura."
        case .noCredentials: return "Oura credentials not configured."
        }
    }
}

// MARK: - API Client (data fetching only — auth handled by OuraManager)

struct OuraAPIClient {
    private let base: String = "https://api.ouraring.com/v2/usercollection"
    let accessToken: String

    private func get<T: Decodable>(_ endpoint: String, start: String, end: String) async throws -> [T] {
        var comps = URLComponents(string: "\(base)/\(endpoint)")!
        comps.queryItems = [
            URLQueryItem(name: "start_date", value: start),
            URLQueryItem(name: "end_date",   value: end)
        ]
        var req = URLRequest(url: comps.url!)
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw OuraError.httpError(http.statusCode)
        }
        return try JSONDecoder().decode(OuraPaginated<T>.self, from: data).data
    }

    // Optional endpoint — returns empty array instead of throwing
    private func safeGet<T: Decodable>(_ endpoint: String, start: String, end: String) async -> [T] {
        (try? await get(endpoint, start: start, end: end)) ?? []
    }

    // MARK: Build HealthSnapshot

    func buildSnapshot(from start: Date, to end: Date) async throws -> HealthSnapshot {
        let s = ouraDateFmt.string(from: start)
        let e = ouraDateFmt.string(from: end)

        // Use /sleep (raw sessions) not /daily_sleep (score summaries only).
        // safeGet for optional endpoints so one failure doesn't block the rest.
        async let sleepTask:     [OuraSleepItem]      = get("sleep",             start: s, end: e)
        async let activityTask:  [OuraActivityItem]   = get("daily_activity",    start: s, end: e)
        async let readinessTask: [OuraReadinessItem]  = safeGet("daily_readiness", start: s, end: e)
        async let vo2Task:       [OuraVo2MaxItem]     = safeGet("vo2_max",       start: s, end: e)

        let allSleep = try await sleepTask
        let activity = try await activityTask
        let readiness = await readinessTask
        let vo2       = await vo2Task

        // Only main sleep sessions (exclude naps, deleted entries)
        let sleep = allSleep.filter { $0.isMainSleep }

        let hrvVals  = sleep.compactMap { $0.averageHrv.map(Double.init) }
        let avgHRV   = hrvVals.isEmpty  ? nil : hrvVals.reduce(0, +)  / Double(hrvVals.count)

        let rhrVals  = sleep.compactMap { $0.lowestHeartRate.map(Double.init) }
        let avgRHR   = rhrVals.isEmpty  ? nil : rhrVals.reduce(0, +)  / Double(rhrVals.count)

        let respVals = sleep.compactMap { $0.averageBreath }
        let avgResp  = respVals.isEmpty ? nil : respVals.reduce(0, +) / Double(respVals.count)

        // Last night = most recent long_sleep entry
        let sorted    = sleep.sorted { $0.day > $1.day }
        let last      = sorted.first
        let lastTotal = last?.totalSleepDuration.map { Double($0) / 3600 }
        let lastDeep  = last?.deepSleepDuration.map  { Double($0) / 3600 }
        let lastREM   = last?.remSleepDuration.map   { Double($0) / 3600 }

        let sleepHrs = sleep.compactMap { $0.totalSleepDuration.map { Double($0) / 3600 } }
        let avgSleep = sleepHrs.isEmpty ? nil : sleepHrs.reduce(0, +) / Double(sleepHrs.count)

        let stepsVals = activity.compactMap { $0.steps.map(Double.init) }
        let avgSteps  = stepsVals.isEmpty ? nil : stepsVals.reduce(0, +) / Double(stepsVals.count)

        let calVals  = activity.compactMap { $0.activeCalories.map(Double.init) }
        let avgCals  = calVals.isEmpty  ? nil : calVals.reduce(0, +)  / Double(calVals.count)

        let latestVo2       = vo2.sorted { $0.day > $1.day }.first?.vo2Max
        let latestReadiness = readiness.sorted { $0.day > $1.day }.first?.score

        return HealthSnapshot(
            date:               end,
            avgHRV:             avgHRV,
            avgRHR:             avgRHR,
            avgRespiratoryRate: avgResp,
            lastSleepHours:     lastTotal,
            lastSleepDeepHours: lastDeep,
            lastSleepREMHours:  lastREM,
            avgSleepHours:      avgSleep,
            avgDailySteps:      avgSteps,
            avgActiveEnergy:    avgCals,
            vo2Max:             latestVo2,
            readinessScore:     latestReadiness
        )
    }
}

// MARK: - Date formatter

private let ouraDateFmt: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = .current
    return f
}()
