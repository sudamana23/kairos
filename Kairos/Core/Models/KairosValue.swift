import Foundation
import SwiftData

@Model
final class KairosValue {
    var id: UUID = UUID()
    var name: String = ""           // e.g. "Presence"
    var reflection: String = ""     // why this matters, AI-guided
    var emoji: String = ""          // e.g. "🌿"
    var colorHex: String = ""       // e.g. "#4A9A6A"
    var sortOrder: Int = 0

    // Inverse: domains that serve this value
    @Relationship(deleteRule: .nullify, inverse: \KairosDomain.value)
    private var _domains: [KairosDomain]? = nil
    var domains: [KairosDomain] {
        get { _domains ?? [] }
        set { _domains = newValue }
    }

    init(name: String, reflection: String = "", emoji: String = "", colorHex: String = "", sortOrder: Int = 0) {
        self.name = name
        self.reflection = reflection
        self.emoji = emoji
        self.colorHex = colorHex
        self.sortOrder = sortOrder
    }
}
