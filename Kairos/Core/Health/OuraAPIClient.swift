import Foundation
import Security

// MARK: - Keychain

enum OuraKeychain {
    private static let service = "com.damianspendel.kairos"
    private static let account = "oura-pat"

    static func save(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData:   data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load() -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete() {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Oura API v2 Response Models

private struct OuraPaginated<T: Decodable>: Decodable {
    let data: [T]
}

private struct OuraSleepItem: Decodable {
    let day: String
    let totalSleepDuration: Int?
    let deepSleepDuration:  Int?
    let remSleepDuration:   Int?
    let averageHrv:         Int?     // RMSSD in ms
    let lowestHeartRate:    Int?     // resting HR
    let averageBreath:      Double?  // breaths/min

    enum CodingKeys: String, CodingKey {
        case day
        case totalSleepDuration = "total_sleep_duration"
        case deepSleepDuration  = "deep_sleep_duration"
        case remSleepDuration   = "rem_sleep_duration"
        case averageHrv         = "average_hrv"
        case lowestHeartRate    = "lowest_heart_rate"
        case averageBreath      = "average_breath"
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

    var errorDescription: String? {
        switch self {
        case .httpError(401): return "Invalid token — check your Oura Personal Access Token."
        case .httpError(let c): return "Oura API error (HTTP \(c))."
        }
    }
}

// MARK: - API Client

struct OuraAPIClient {
    private let base  = "https://api.ouraring.com/v2/usercollection"
    let token: String

    // Throwing fetch — used for required endpoints (sleep, activity)
    private func get<T: Decodable>(_ endpoint: String, start: String, end: String) async throws -> [T] {
        var comps = URLComponents(string: "\(base)/\(endpoint)")!
        comps.queryItems = [
            URLQueryItem(name: "start_date", value: start),
            URLQueryItem(name: "end_date",   value: end)
        ]
        var req = URLRequest(url: comps.url!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw OuraError.httpError(http.statusCode)
        }
        return try JSONDecoder().decode(OuraPaginated<T>.self, from: data).data
    }

    // Silent fetch — used for optional endpoints (vo2_max — not all rings support it)
    private func safeGet<T: Decodable>(_ endpoint: String, start: String, end: String) async -> [T] {
        (try? await get(endpoint, start: start, end: end)) ?? []
    }

    // MARK: - Build HealthSnapshot

    func buildSnapshot(from start: Date, to end: Date) async throws -> HealthSnapshot {
        let s = ouraDateFmt.string(from: start)
        let e = ouraDateFmt.string(from: end)

        // Kick off all three requests in parallel
        async let sleepTask:    [OuraSleepItem]    = get("daily_sleep",    start: s, end: e)
        async let activityTask: [OuraActivityItem] = get("daily_activity", start: s, end: e)
        async let vo2Task:      [OuraVo2MaxItem]   = safeGet("vo2_max",    start: s, end: e)

        let sleep    = try await sleepTask
        let activity = try await activityTask
        let vo2      = await vo2Task

        // HRV — average RMSSD across the period
        let hrvVals = sleep.compactMap { $0.averageHrv.map(Double.init) }
        let avgHRV  = hrvVals.isEmpty ? nil : hrvVals.reduce(0, +) / Double(hrvVals.count)

        // Resting HR — average lowest_heart_rate from sleep sessions
        let rhrVals = sleep.compactMap { $0.lowestHeartRate.map(Double.init) }
        let avgRHR  = rhrVals.isEmpty ? nil : rhrVals.reduce(0, +) / Double(rhrVals.count)

        // Respiratory rate — average breath per minute during sleep
        let respVals = sleep.compactMap { $0.averageBreath }
        let avgResp  = respVals.isEmpty ? nil : respVals.reduce(0, +) / Double(respVals.count)

        // Sleep — most recent entry = last night
        let sorted        = sleep.sorted { $0.day > $1.day }
        let last          = sorted.first
        let lastTotal     = last?.totalSleepDuration.map { Double($0) / 3600 }
        let lastDeep      = last?.deepSleepDuration.map  { Double($0) / 3600 }
        let lastREM       = last?.remSleepDuration.map   { Double($0) / 3600 }

        // Sleep — 7-day rolling average
        let sleepHrs = sleep.compactMap { $0.totalSleepDuration.map { Double($0) / 3600 } }
        let avgSleep = sleepHrs.isEmpty ? nil : sleepHrs.reduce(0, +) / Double(sleepHrs.count)

        // Activity
        let stepsVals = activity.compactMap { $0.steps.map(Double.init) }
        let avgSteps  = stepsVals.isEmpty ? nil : stepsVals.reduce(0, +) / Double(stepsVals.count)

        let calVals  = activity.compactMap { $0.activeCalories.map(Double.init) }
        let avgCals  = calVals.isEmpty ? nil : calVals.reduce(0, +) / Double(calVals.count)

        // VO2 Max — most recent reading
        let latestVo2 = vo2.sorted { $0.day > $1.day }.first?.vo2Max

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
            vo2Max:             latestVo2
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
