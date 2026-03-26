import Foundation

// MARK: - HealthSnapshot
// A point-in-time summary of physiological signals.
// Built from rolling windows: 7-day avg for daily metrics, last night for sleep.

struct HealthSnapshot: Sendable {
    let date: Date

    // Recovery
    let avgHRV: Double?
    let avgRHR: Double?
    let avgRespiratoryRate: Double?

    // Sleep (last night)
    let lastSleepHours: Double?
    let lastSleepDeepHours: Double?
    let lastSleepREMHours: Double?
    let avgSleepHours: Double?

    // Activity
    let avgDailySteps: Double?
    let avgActiveEnergy: Double?

    // Fitness
    let vo2Max: Double?

    // Readiness (Oura only — 0–100)
    let readinessScore: Int?

    var recoverySignal: RecoverySignal {
        if let hrv = avgHRV {
            if hrv >= 50 { return .high }
            if hrv >= 30 { return .moderate }
            return .low
        }
        if let score = readinessScore {
            if score >= 70 { return .high }
            if score >= 50 { return .moderate }
            return .low
        }
        return .unknown
    }

    var sleepSignal: SleepSignal {
        guard let hours = avgSleepHours else { return .unknown }
        if hours >= 7.5 { return .optimal }
        if hours >= 6.5 { return .adequate }
        return .insufficient
    }
}

enum RecoverySignal: String {
    case high     = "High"
    case moderate = "Moderate"
    case low      = "Low"
    case unknown  = "—"

    var color: String {
        switch self {
        case .high:     return "#4A9A6A"
        case .moderate: return "#AA9A4A"
        case .low:      return "#9A4A4A"
        case .unknown:  return "#55556A"
        }
    }
}

enum SleepSignal: String {
    case optimal      = "Optimal"
    case adequate     = "Adequate"
    case insufficient = "Insufficient"
    case unknown      = "—"
}

// MARK: - HealthKitManager

#if os(iOS)
import HealthKit

@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    @Published var isAvailable: Bool = false
    @Published var isAuthorized: Bool = false
    @Published var snapshot: HealthSnapshot?
    @Published var monthlySnapshots: [Date: HealthSnapshot] = [:]
    @Published var authError: String?

    private init() {
        isAvailable = HKHealthStore.isHealthDataAvailable()
    }

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        let quantityIds: [HKQuantityTypeIdentifier] = [
            .heartRateVariabilitySDNN, .restingHeartRate, .respiratoryRate,
            .activeEnergyBurned, .stepCount, .vo2Max
        ]
        for id in quantityIds {
            if let t = HKObjectType.quantityType(forIdentifier: id) { types.insert(t) }
        }
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }
        return types
    }

    func requestAuthorization() async {
        guard isAvailable else { authError = "HealthKit is not available on this device."; return }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            await fetchCurrentSnapshot()
        } catch {
            authError = error.localizedDescription
        }
    }

    func fetchCurrentSnapshot() async {
        snapshot = await buildSnapshot(endDate: Date(), days: 7)
    }

    func fetchMonthlyHistory(months: Int = 24) async {
        let cal = Calendar.current
        let now = Date()
        var result: [Date: HealthSnapshot] = [:]
        await withTaskGroup(of: (Date, HealthSnapshot?).self) { group in
            for i in 0..<months {
                guard let monthStart = cal.date(byAdding: .month, value: -i, to: now.startOfMonth) else { continue }
                let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart) ?? now
                group.addTask {
                    let snap = await self.buildSnapshot(
                        endDate: monthEnd,
                        days: cal.range(of: .day, in: .month, for: monthStart)?.count ?? 30
                    )
                    return (monthStart, snap)
                }
            }
            for await (date, snap) in group {
                if let snap { result[date] = snap }
            }
        }
        monthlySnapshots = result
    }

    private nonisolated func buildSnapshot(endDate: Date, days: Int) async -> HealthSnapshot {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        async let hrv      = queryQuantityAvg(.heartRateVariabilitySDNN, unit: HKUnit.secondUnit(with: .milli), start: startDate, end: endDate)
        async let rhr      = queryQuantityAvg(.restingHeartRate, unit: .count().unitDivided(by: .minute()), start: startDate, end: endDate)
        async let respRate = queryQuantityAvg(.respiratoryRate, unit: .count().unitDivided(by: .minute()), start: startDate, end: endDate)
        async let steps    = queryQuantitySum(.stepCount, unit: HKUnit.count(), start: startDate, end: endDate, divideByDays: days)
        async let energy   = queryQuantitySum(.activeEnergyBurned, unit: HKUnit.kilocalorie(), start: startDate, end: endDate, divideByDays: days)
        async let vo2      = queryQuantityLatest(.vo2Max, unit: .literUnit(with: .milli).unitDivided(by: HKUnit.gramUnit(with: .kilo)).unitDivided(by: .minute()), start: startDate, end: endDate)
        async let sleep    = querySleep(start: startDate, end: endDate)
        let (hrvVal, rhrVal, respVal, stepsVal, energyVal, vo2Val, sleepResult) = await (hrv, rhr, respRate, steps, energy, vo2, sleep)
        return HealthSnapshot(date: endDate, avgHRV: hrvVal, avgRHR: rhrVal, avgRespiratoryRate: respVal,
            lastSleepHours: sleepResult.lastNight, lastSleepDeepHours: sleepResult.lastDeep,
            lastSleepREMHours: sleepResult.lastREM, avgSleepHours: sleepResult.average,
            avgDailySteps: stepsVal, avgActiveEnergy: energyVal, vo2Max: vo2Val, readinessScore: nil)
    }

    private nonisolated func queryQuantityAvg(_ id: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: HKQuery.predicateForSamples(withStart: start, end: end), options: .discreteAverage) { _, s, _ in
                cont.resume(returning: s?.averageQuantity()?.doubleValue(for: unit))
            }
            store.execute(q)
        }
    }

    private nonisolated func queryQuantitySum(_ id: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date, divideByDays: Int = 1) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: HKQuery.predicateForSamples(withStart: start, end: end), options: .cumulativeSum) { _, s, _ in
                guard let sum = s?.sumQuantity()?.doubleValue(for: unit) else { cont.resume(returning: nil); return }
                cont.resume(returning: divideByDays > 1 ? sum / Double(divideByDays) : sum)
            }
            store.execute(q)
        }
    }

    private nonisolated func queryQuantityLatest(_ id: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: HKQuery.predicateForSamples(withStart: start, end: end), limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, _ in
                cont.resume(returning: (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit))
            }
            store.execute(q)
        }
    }

    private struct SleepResult { let lastNight, lastDeep, lastREM, average: Double? }

    private nonisolated func querySleep(start: Date, end: Date) async -> SleepResult {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return SleepResult(lastNight: nil, lastDeep: nil, lastREM: nil, average: nil)
        }
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: sleepType, predicate: HKQuery.predicateForSamples(withStart: start, end: end), limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    cont.resume(returning: SleepResult(lastNight: nil, lastDeep: nil, lastREM: nil, average: nil)); return
                }
                let cal = Calendar.current
                var totals: [Date: Double] = [:], deep: [Date: Double] = [:], rem: [Date: Double] = [:]
                for s in samples {
                    let night = cal.startOfDay(for: s.endDate)
                    let hours = s.endDate.timeIntervalSince(s.startDate) / 3600
                    switch HKCategoryValueSleepAnalysis(rawValue: s.value) {
                    case .asleep, .asleepUnspecified: totals[night, default: 0] += hours
                    case .asleepDeep: deep[night, default: 0] += hours; totals[night, default: 0] += hours
                    case .asleepREM:  rem[night, default: 0] += hours;  totals[night, default: 0] += hours
                    case .asleepCore: totals[night, default: 0] += hours
                    default: break
                    }
                }
                let last = totals.keys.sorted(by: >).first
                let avg = totals.isEmpty ? nil : totals.values.reduce(0, +) / Double(totals.count)
                cont.resume(returning: SleepResult(lastNight: last.flatMap { totals[$0] }, lastDeep: last.flatMap { deep[$0] }, lastREM: last.flatMap { rem[$0] }, average: avg))
            }
            store.execute(q)
        }
    }
}

private extension Date {
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }
}

#else

// MARK: - macOS stub (HealthKit is iOS-only in this app)

@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    @Published var isAvailable: Bool = false
    @Published var isAuthorized: Bool = false
    @Published var snapshot: HealthSnapshot? = nil
    @Published var monthlySnapshots: [Date: HealthSnapshot] = [:]
    @Published var authError: String? = nil
    private init() {}
    func requestAuthorization() async {}
    func fetchCurrentSnapshot() async {}
    func fetchMonthlyHistory(months: Int = 24) async {}
}

#endif
