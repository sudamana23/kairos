import Foundation

// MARK: - KairosWidgetData
//
// Lightweight Codable snapshot read by the widget from the shared App Group.

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

    static let suiteName       = "group.com.damianspendel.kairos"
    static let userDefaultsKey = "kairos.widgetData"

    // Reads the latest snapshot written by the main app.
    static func load() -> KairosWidgetData? {
        guard
            let defaults = UserDefaults(suiteName: suiteName),
            let data     = defaults.data(forKey: userDefaultsKey)
        else { return nil }
        return try? JSONDecoder().decode(KairosWidgetData.self, from: data)
    }

    func save() {
        guard
            let defaults = UserDefaults(suiteName: KairosWidgetData.suiteName),
            let encoded  = try? JSONEncoder().encode(self)
        else { return }
        defaults.set(encoded, forKey: KairosWidgetData.userDefaultsKey)
    }

    // MARK: - Sample data for Xcode previews and placeholder

    static var placeholder: KairosWidgetData {
        KairosWidgetData(
            yearProgress:    0.42,
            currentYear:     2026,
            intention:       "Be relentless in your focus",
            domains: [
                DomainSummary(name: "Health",        emoji: "🏋️", colorHex: "#4ADE80", progress: 0.75),
                DomainSummary(name: "Work",           emoji: "💻", colorHex: "#60A5FA", progress: 0.55),
                DomainSummary(name: "Relationships",  emoji: "❤️", colorHex: "#F472B6", progress: 0.35),
                DomainSummary(name: "Learning",       emoji: "📚", colorHex: "#A78BFA", progress: 0.20),
            ],
            lastPulseDate:   Date().addingTimeInterval(-3 * 86_400),
            lastPulseEnergy: 4,
            updatedAt:       Date()
        )
    }
}
