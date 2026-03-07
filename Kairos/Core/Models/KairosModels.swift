import Foundation
import SwiftData

// MARK: - KairosYear

@Model
final class KairosYear {
    var id: UUID
    var year: Int
    var intention: String

    @Relationship(deleteRule: .cascade, inverse: \KairosDomain.year)
    var domains: [KairosDomain]

    init(year: Int, intention: String = "") {
        self.id = UUID()
        self.year = year
        self.intention = intention
        self.domains = []
    }

    var sortedDomains: [KairosDomain] {
        domains.sorted { $0.sortOrder < $1.sortOrder }
    }

    var allKeyResults: [KairosKeyResult] {
        domains.flatMap { $0.objectives.flatMap { $0.keyResults } }
    }

    var overallProgress: Double {
        let krs = allKeyResults
        guard !krs.isEmpty else { return 0 }
        return krs.reduce(0.0) { $0 + $1.currentStatus.weight } / Double(krs.count)
    }
}

// MARK: - KairosDomain

@Model
final class KairosDomain {
    var id: UUID
    var name: String
    var emoji: String
    var identityStatement: String
    var sortOrder: Int
    var colorHex: String

    var year: KairosYear?

    @Relationship(deleteRule: .cascade, inverse: \KairosObjective.domain)
    var objectives: [KairosObjective]

    init(name: String, emoji: String, identityStatement: String = "", sortOrder: Int, colorHex: String) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.identityStatement = identityStatement
        self.sortOrder = sortOrder
        self.colorHex = colorHex
        self.objectives = []
    }

    var sortedObjectives: [KairosObjective] {
        objectives.sorted { $0.sortOrder < $1.sortOrder }
    }

    var allKeyResults: [KairosKeyResult] {
        objectives.flatMap { $0.keyResults }
    }

    var progress: Double {
        let krs = allKeyResults
        guard !krs.isEmpty else { return 0 }
        return krs.reduce(0.0) { $0 + $1.currentStatus.weight } / Double(krs.count)
    }

    var completedCount: Int {
        allKeyResults.filter { $0.currentStatus == .done }.count
    }
}

// MARK: - KairosObjective

@Model
final class KairosObjective {
    var id: UUID
    var title: String
    var sortOrder: Int

    var domain: KairosDomain?

    @Relationship(deleteRule: .cascade, inverse: \KairosKeyResult.objective)
    var keyResults: [KairosKeyResult]

    init(title: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.title = title
        self.sortOrder = sortOrder
        self.keyResults = []
    }

    var sortedKeyResults: [KairosKeyResult] {
        keyResults.sorted { $0.sortOrder < $1.sortOrder }
    }
}

// MARK: - KairosKeyResult

@Model
final class KairosKeyResult {
    var id: UUID
    var title: String
    var sortOrder: Int

    var objective: KairosObjective?

    @Relationship(deleteRule: .cascade, inverse: \KairosMonthlyEntry.keyResult)
    var entries: [KairosMonthlyEntry]

    init(title: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.title = title
        self.sortOrder = sortOrder
        self.entries = []
    }

    var latestEntry: KairosMonthlyEntry? {
        entries.sorted { ($0.year, $0.month) > ($1.year, $1.month) }.first
    }

    var currentStatus: KRStatus {
        latestEntry?.statusEnum ?? .notStarted
    }

    var latestCommentary: String {
        latestEntry?.commentary ?? ""
    }

    var latestRating: Int {
        latestEntry?.rating ?? 0
    }
}

// MARK: - KairosMonthlyEntry

@Model
final class KairosMonthlyEntry {
    var id: UUID
    var year: Int
    var month: Int
    var statusRaw: String
    var rating: Int
    var commentary: String

    var keyResult: KairosKeyResult?

    init(year: Int, month: Int, status: KRStatus = .notStarted, rating: Int = 0, commentary: String = "") {
        self.id = UUID()
        self.year = year
        self.month = month
        self.statusRaw = status.rawValue
        self.rating = rating
        self.commentary = commentary
    }

    var statusEnum: KRStatus {
        get { KRStatus(rawValue: statusRaw) ?? .notStarted }
        set { statusRaw = newValue.rawValue }
    }
}

// MARK: - KairosWeeklyPulse

@Model
final class KairosWeeklyPulse {
    var id: UUID
    var date: Date
    var energyLevel: Int
    var tagsRaw: String
    var transcription: String
    var note: String
    var sentimentScore: Double
    var audioFileName: String

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = date
        self.energyLevel = 0
        self.tagsRaw = "[]"
        self.transcription = ""
        self.note = ""
        self.sentimentScore = 0
        self.audioFileName = ""
    }

    var tags: [PulseTag] {
        get {
            guard let data = tagsRaw.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String].self, from: data) else { return [] }
            return decoded.compactMap { PulseTag(rawValue: $0) }
        }
        set {
            let strings = newValue.map { $0.rawValue }
            if let data = try? JSONEncoder().encode(strings),
               let str = String(data: data, encoding: .utf8) {
                tagsRaw = str
            }
        }
    }
}

// MARK: - KairosMonthlyReview

@Model
final class KairosMonthlyReview {
    var id: UUID
    var year: Int
    var month: Int
    var transcript: String
    var summaryPoint1: String
    var summaryPoint2: String
    var summaryPoint3: String
    var audioFileName: String
    var createdAt: Date

    init(year: Int, month: Int) {
        self.id = UUID()
        self.year = year
        self.month = month
        self.transcript = ""
        self.summaryPoint1 = ""
        self.summaryPoint2 = ""
        self.summaryPoint3 = ""
        self.audioFileName = ""
        self.createdAt = Date()
    }

    var summaryPoints: [String] {
        [summaryPoint1, summaryPoint2, summaryPoint3].filter { !$0.isEmpty }
    }
}

// MARK: - KRStatus

enum KRStatus: String, CaseIterable, Codable {
    case notStarted  = "not started"
    case initialized = "initialized"
    case inProgress  = "in progress"
    case done        = "done"
    case blocked     = "blocked"
    case paused      = "paused"

    var displayName: String {
        switch self {
        case .notStarted:  return "Not Started"
        case .initialized: return "Initialized"
        case .inProgress:  return "In Progress"
        case .done:        return "Done"
        case .blocked:     return "Blocked"
        case .paused:      return "Paused"
        }
    }

    /// Weighted score contribution (0–1) for progress calculation
    var weight: Double {
        switch self {
        case .notStarted:  return 0.0
        case .initialized: return 0.1
        case .inProgress:  return 0.6
        case .done:        return 1.0
        case .blocked:     return 0.0
        case .paused:      return 0.0
        }
    }
}

// MARK: - PulseTag

enum PulseTag: String, CaseIterable, Codable {
    case work          = "Work"
    case body          = "Body"
    case mind          = "Mind"
    case relationships = "Relationships"
    case uncertainty   = "Uncertainty"
}
