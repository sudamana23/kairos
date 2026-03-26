#if os(iOS)
import Foundation
import WidgetKit

// MARK: - KairosWidgetBridge
//
// Writes a lightweight snapshot of current app data into the shared App Group
// UserDefaults so the iOS widget can read it without touching SwiftData directly.
// Call write() whenever data the widget displays could have changed.

enum KairosWidgetBridge {

    static func write(years: [KairosYear], pulses: [KairosWeeklyPulse]) {
        let currentYear = years
            .filter { !$0.isArchived }
            .sorted { $0.year > $1.year }
            .first

        let domains: [KairosWidgetData.DomainSummary] = (currentYear?.sortedDomains ?? [])
            .prefix(4)
            .map {
                KairosWidgetData.DomainSummary(
                    name:     $0.name,
                    emoji:    $0.emoji,
                    colorHex: $0.colorHex,
                    progress: $0.progress
                )
            }

        let lastPulse = pulses
            .filter { !$0.isArchived }
            .sorted { $0.date > $1.date }
            .first

        let data = KairosWidgetData(
            yearProgress:    currentYear?.overallProgress ?? 0,
            currentYear:     currentYear?.year ?? Calendar.current.component(.year, from: Date()),
            intention:       currentYear?.intention ?? "",
            domains:         domains,
            lastPulseDate:   lastPulse?.date,
            lastPulseEnergy: lastPulse?.energyLevel ?? 0,
            updatedAt:       Date()
        )

        data.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - KairosWidgetData
//
// Lightweight Codable snapshot — Foundation only, no SwiftData.
// Must stay in sync with the copy in KairosWidget/KairosWidgetData.swift.

struct KairosWidgetData: Codable {
    var yearProgress:    Double
    var currentYear:     Int
    var intention:       String
    var domains:         [DomainSummary]
    var lastPulseDate:   Date?
    var lastPulseEnergy: Int        // 0–5
    var updatedAt:       Date

    struct DomainSummary: Codable {
        var name:     String
        var emoji:    String
        var colorHex: String
        var progress: Double
    }

    static let suiteName      = "group.com.damianspendel.kairos"
    static let userDefaultsKey = "kairos.widgetData"

    func save() {
        guard
            let defaults = UserDefaults(suiteName: KairosWidgetData.suiteName),
            let encoded  = try? JSONEncoder().encode(self)
        else { return }
        defaults.set(encoded, forKey: KairosWidgetData.userDefaultsKey)
    }
}
#endif
