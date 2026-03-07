import Foundation
import HealthKit

// MARK: - HealthSnapshot
// A point-in-time summary of physiological signals.
// Built from rolling windows: 7-day avg for daily metrics, last night for sleep.

struct HealthSnapshot: Sendable {
    let date: Date

    // Recovery
    let avgHRV: Double?           // ms, SDNN — Oura morning reading
    let avgRHR: Double?           // bpm — resting heart rate
    let avgRespiratoryRate: Double? // breaths/min

    // Sleep (last night)
    let lastSleepHours: Double?   // total time in bed asleep
    let lastSleepDeepHours: Double?
    let lastSleepREMHours: Double?
    let avgSleepHours: Double?    // 7-day rolling average

    // Activity
    let avgDailySteps: Double?
    let avgActiveEnergy: Double?  // kcal/day

    // Fitness
    let vo2Max: Double?           // mL/kg/min — latest reading

    // Computed signals
    var recoverySignal: RecoverySignal {
        guard let hrv = avgHRV else { return .unknown }
        if hrv >= 50 { return .high }
        if hrv >= 30 { return .moderate }
        return .low
    }

    var sleepSignal: SleepSignal {
        guard let hours = avgSleepHours else { return .unknown }
        if hours >= 7.5 { return .optimal }
        if hours >= 6.5 { return .adequate }
        return .insufficient }
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

    // MARK: - Read types

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        let quantityIds: [HKQuantityTypeIdentifier] = [
            .heartRateVariabilitySDNN,
            .restingHeartRate,
            .respiratoryRate,
            .activeEnergyBurned,
            .stepCount,
            .vo2Max
        ]
        for id in quantityIds {
            if let t = HKObjectType.quantityType(forIdentifier: id) { types.insert(t) }
        }
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }
        return types
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        guard isAvailable else {
            authError = "HealthKit is not available on this device."
            return
        }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            await fetchCurrentSnapshot()
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Fetch current snapshot (last 7 days)

    func fetchCurrentSnapshot() async {
        let now = Date()
        snapshot = await buildSnapshot(endDate: now, days: 7)
    }

    // MARK: - Fetch monthly snapshots for Time Machine

    func fetchMonthlyHistory(months: Int = 24) async {
        let cal = Calendar.current
        let now = Date()
        var result: [Date: HealthSnapshot] = [:]

        await withTaskGroup(of: (Date, HealthSnapshot?).self) { group in
            for i in 0..<months {
                guard let monthStart = cal.date(byAdding: .month, value: -i, to: now.startOfMonth) else { continue }
                let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart) ?? now
                group.addTask {
                    let snap = await self.buildSnapshot(endDate: monthEnd, days: cal.range(of: .day, in: .month, for: monthStart)?.count ?? 30)
                    return (monthStart, snap)
                }
            }
            for await (date, snap) in group {
                if let snap { result[date] = snap }
            }
        }

        monthlySnapshots = result
    }

    // MARK: - Core builder

    private func buildSnapshot(endDate: Date, days: Int) async -> HealthSnapshot {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate

        async let hrv       = queryQuantityAvg(.heartRateVariabilitySDNN, unit: HKUnit.secondUnit(with: .milli), start: startDate, end: endDate)
        async let rhr       = queryQuantityAvg(.restingHeartRate, unit: HKUnit(from: "count/min"), start: startDate, end: endDate)
        async let respRate  = queryQuantityAvg(.respiratoryRate, unit: HKUnit(from: "count/min"), start: startDate, end: endDate)
        async let steps     = queryQuantitySum(.stepCount, unit: HKUnit.count(), start: startDate, end: endDate, divideByDays: days)
        async let energy    = queryQuantitySum(.activeEnergyBurned, unit: HKUnit.kilocalorie(), start: startDate, end: endDate, divideByDays: days)
        async let vo2       = queryQuantityLatest(.vo2Max, unit: HKUnit(from: "ml/kg/min"), start: startDate, end: endDate)
        async let sleep     = querySleep(start: startDate, end: endDate)

        let (hrvVal, rhrVal, respVal, stepsVal, energyVal, vo2Val, sleepResult) = await (hrv, rhr, respRate, steps, energy, vo2, sleep)

        return HealthSnapshot(
            date: endDate,
            avgHRV: hrvVal,
            avgRHR: rhrVal,
            avgRespiratoryRate: respVal,
            lastSleepHours: sleepResult.lastNight,
            lastSleepDeepHours: sleepResult.lastDeep,
            lastSleepREMHours: sleepResult.lastREM,
            avgSleepHours: sleepResult.average,
            avgDailySteps: stepsVal,
            avgActiveEnergy: energyVal,
            vo2Max: vo2Val
        )
    }

    // MARK: - Quantity queries

    private func queryQuantityAvg(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, stats, _ in
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func queryQuantitySum(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date,
        divideByDays: Int = 1
    ) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                guard let sum = stats?.sumQuantity()?.doubleValue(for: unit) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: divideByDays > 1 ? sum / Double(divideByDays) : sum)
            }
            store.execute(query)
        }
    }

    private func queryQuantityLatest(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    // MARK: - Sleep query

    private struct SleepResult {
        let lastNight: Double?
        let lastDeep: Double?
        let lastREM: Double?
        let average: Double?
    }

    private func querySleep(start: Date, end: Date) async -> SleepResult {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return SleepResult(lastNight: nil, lastDeep: nil, lastREM: nil, average: nil)
        }

        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: SleepResult(lastNight: nil, lastDeep: nil, lastREM: nil, average: nil))
                    return
                }

                // Group by night (calendar day of end date)
                let cal = Calendar.current
                var nightlyTotals: [Date: Double] = [:]
                var nightlyDeep:   [Date: Double] = [:]
                var nightlyREM:    [Date: Double] = [:]

                for sample in samples {
                    let night = cal.startOfDay(for: sample.endDate)
                    let hours = sample.endDate.timeIntervalSince(sample.startDate) / 3600

                    switch HKCategoryValueSleepAnalysis(rawValue: sample.value) {
                    case .asleep, .asleepUnspecified:
                        nightlyTotals[night, default: 0] += hours
                    case .asleepDeep:
                        nightlyDeep[night, default: 0] += hours
                        nightlyTotals[night, default: 0] += hours
                    case .asleepREM:
                        nightlyREM[night, default: 0] += hours
                        nightlyTotals[night, default: 0] += hours
                    case .asleepCore:
                        nightlyTotals[night, default: 0] += hours
                    default:
                        break
                    }
                }

                let sortedNights = nightlyTotals.keys.sorted(by: >)
                let lastNight = sortedNights.first

                let avgSleep = nightlyTotals.isEmpty ? nil :
                    nightlyTotals.values.reduce(0, +) / Double(nightlyTotals.count)

                continuation.resume(returning: SleepResult(
                    lastNight: lastNight.flatMap { nightlyTotals[$0] },
                    lastDeep:  lastNight.flatMap { nightlyDeep[$0] },
                    lastREM:   lastNight.flatMap { nightlyREM[$0] },
                    average:   avgSleep
                ))
            }
            store.execute(query)
        }
    }
}

// MARK: - Date helpers

private extension Date {
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }
}
