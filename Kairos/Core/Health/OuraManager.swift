import Foundation

// MARK: - OuraManager
//
// Single source of truth for Oura API data.
// Token stored in macOS Keychain via OuraKeychain.
// HealthPanel and IntelligenceEngine prefer this over HealthKit.

@MainActor
final class OuraManager: ObservableObject {
    static let shared = OuraManager()

    @Published var isAuthorized: Bool = false
    @Published var snapshot: HealthSnapshot?
    @Published var monthlySnapshots: [Date: HealthSnapshot] = [:]
    @Published var isFetching: Bool = false
    @Published var fetchError: String?

    private init() {
        isAuthorized = OuraKeychain.load() != nil
    }

    // MARK: - Token management

    func saveToken(_ raw: String) {
        let token = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else { return }
        OuraKeychain.save(token)
        isAuthorized = true
        fetchError = nil
        Task { await fetchCurrentSnapshot() }
    }

    func revoke() {
        OuraKeychain.delete()
        isAuthorized = false
        snapshot = nil
        monthlySnapshots = [:]
        fetchError = nil
    }

    // MARK: - Fetch

    func fetchCurrentSnapshot() async {
        guard let token = OuraKeychain.load() else { return }
        let end   = Date()
        let start = Calendar.current.date(byAdding: .day, value: -7, to: end) ?? end
        await fetch(from: start, to: end, token: token) { self.snapshot = $0 }
    }

    func fetchMonthlyHistory(months: Int = 24) async {
        guard let token = OuraKeychain.load() else { return }
        let cal = Calendar.current
        let now = Date()
        var result: [Date: HealthSnapshot] = [:]

        await withTaskGroup(of: (Date, HealthSnapshot?).self) { group in
            for i in 0..<months {
                guard let mStart = cal.date(byAdding: .month, value: -i, to: now.startOfMonth)
                else { continue }
                let mEnd = cal.date(byAdding: .month, value: 1, to: mStart) ?? now
                group.addTask {
                    let snap = try? await OuraAPIClient(token: token).buildSnapshot(from: mStart, to: mEnd)
                    return (mStart, snap)
                }
            }
            for await (date, snap) in group {
                if let snap { result[date] = snap }
            }
        }
        monthlySnapshots = result
    }

    // MARK: - Private

    private func fetch(from start: Date, to end: Date, token: String, assign: @escaping (HealthSnapshot) -> Void) async {
        isFetching = true
        fetchError = nil
        do {
            let snap = try await OuraAPIClient(token: token).buildSnapshot(from: start, to: end)
            assign(snap)
        } catch {
            fetchError = error.localizedDescription
        }
        isFetching = false
    }
}

private extension Date {
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }
}
