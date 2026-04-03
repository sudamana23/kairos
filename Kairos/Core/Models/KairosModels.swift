import Foundation
import SwiftData

// MARK: - KairosYear

@Model
final class KairosYear {
    var id: UUID = UUID()
    var year: Int = 0
    var intention: String = ""
    var isArchived: Bool = false

    /// AI-generated one-sentence insight, refreshed once per month after a monthly review.
    var aiSummary: String = ""
    /// The year+month (e.g. 202603) when aiSummary was last generated.
    var aiSummaryGeneratedMonth: Int = 0

    // CloudKit requires to-many relationships to be optional ([T]?).
    // The computed `domains` wrapper keeps the public API non-optional.
    @Relationship(deleteRule: .nullify, inverse: \KairosDomain.year)
    private var _domains: [KairosDomain]? = nil
    var domains: [KairosDomain] {
        get { _domains ?? [] }
        set { _domains = newValue }
    }

    init(year: Int, intention: String = "") {
        self.year = year
        self.intention = intention
    }

    func deleteWithChildren(in context: ModelContext) {
        for domain in domains { domain.deleteWithChildren(in: context) }
        context.delete(self)
    }

    var sortedDomains: [KairosDomain] {
        domains.filter { !$0.isArchived }.sorted { $0.sortOrder < $1.sortOrder }
    }

    var allSortedDomains: [KairosDomain] {
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
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = ""
    var identityStatement: String = ""
    var sortOrder: Int = 0
    var colorHex: String = ""
    var isArchived: Bool = false

    var year: KairosYear?

    @Relationship(deleteRule: .nullify, inverse: \KairosObjective.domain)
    private var _objectives: [KairosObjective]? = nil
    var objectives: [KairosObjective] {
        get { _objectives ?? [] }
        set { _objectives = newValue }
    }

    init(name: String, emoji: String, identityStatement: String = "", sortOrder: Int, colorHex: String) {
        self.name = name
        self.emoji = emoji
        self.identityStatement = identityStatement
        self.sortOrder = sortOrder
        self.colorHex = colorHex
    }

    func deleteWithChildren(in context: ModelContext) {
        for objective in objectives { objective.deleteWithChildren(in: context) }
        context.delete(self)
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
    var id: UUID = UUID()
    var title: String = ""
    var sortOrder: Int = 0
    var isArchived: Bool = false

    var domain: KairosDomain?

    @Relationship(deleteRule: .nullify, inverse: \KairosKeyResult.objective)
    private var _keyResults: [KairosKeyResult]? = nil
    var keyResults: [KairosKeyResult] {
        get { _keyResults ?? [] }
        set { _keyResults = newValue }
    }

    init(title: String, sortOrder: Int = 0) {
        self.title = title
        self.sortOrder = sortOrder
    }

    func deleteWithChildren(in context: ModelContext) {
        for kr in keyResults { kr.deleteWithChildren(in: context) }
        context.delete(self)
    }

    var sortedKeyResults: [KairosKeyResult] {
        keyResults.sorted { $0.sortOrder < $1.sortOrder }
    }
}

// MARK: - KairosKeyResult

@Model
final class KairosKeyResult {
    var id: UUID = UUID()
    var title: String = ""
    var sortOrder: Int = 0
    var isArchived: Bool = false

    var objective: KairosObjective?

    @Relationship(deleteRule: .nullify, inverse: \KairosMonthlyEntry.keyResult)
    private var _entries: [KairosMonthlyEntry]? = nil
    var entries: [KairosMonthlyEntry] {
        get { _entries ?? [] }
        set { _entries = newValue }
    }

    init(title: String, sortOrder: Int = 0) {
        self.title = title
        self.sortOrder = sortOrder
    }

    func deleteWithChildren(in context: ModelContext) {
        for entry in entries { context.delete(entry) }
        context.delete(self)
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
    var id: UUID = UUID()
    var year: Int = 0
    var month: Int = 0
    var statusRaw: String = KRStatus.notStarted.rawValue
    var rating: Int = 0
    var commentary: String = ""

    var keyResult: KairosKeyResult?

    init(year: Int, month: Int, status: KRStatus = .notStarted, rating: Int = 0, commentary: String = "") {
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
    var id: UUID = UUID()
    var date: Date = Date()
    var energyLevel: Int = 0
    var tagsRaw: String = "[]"
    var transcription: String = ""
    var note: String = ""
    var sentimentScore: Double = 0
    var audioFileName: String = ""
    var isArchived: Bool = false

    init(date: Date = Date()) {
        self.date = date
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
    var id: UUID = UUID()
    var year: Int = 0
    var month: Int = 0
    var transcript: String = ""
    var summaryPoint1: String = ""
    var summaryPoint2: String = ""
    var summaryPoint3: String = ""
    var audioFileName: String = ""
    var createdAt: Date = Date()
    var isArchived: Bool = false

    init(year: Int, month: Int) {
        self.year = year
        self.month = month
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
