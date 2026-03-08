import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - IntelligenceEngine Protocol
//
// All AI calls in Kairos go through this protocol.
// Active engine: FoundationModelsEngine (on-device Apple Intelligence, macOS 26+)
// Fallback: StubEngine (shows placeholder copy, guides user to enable Apple Intelligence)

protocol IntelligenceEngine: Sendable {
    var isAvailable: Bool { get }
    var displayName: String { get }

    func complete(prompt: String, context: IntelligenceContext) async throws -> String
    func stream(prompt: String, context: IntelligenceContext) -> AsyncThrowingStream<String, Error>
}

// MARK: - IntelligenceContext

struct IntelligenceContext: Sendable {
    let year: Int
    let month: Int?
    let domainSummaries: [DomainSummary]
    let recentPulseNotes: [String]
    let healthSnapshot: HealthSnapshot?
    let persona: AIPersona?

    struct DomainSummary: Sendable {
        let name: String
        let progress: Double
        let recentCommentary: [String]
    }

    struct HealthSnapshot: Sendable {
        let avgHRV: Double?
        let avgSleepHours: Double?
        let avgRHR: Double?
        let vo2Max: Double?
    }
}

// MARK: - IntelligenceMode

enum IntelligenceMode: String, CaseIterable {
    case foundationModels = "On-Device (Apple Intelligence)"
    case api              = "API (Development)"
    case localMLX         = "Local MLX (Coming Soon)"
}

// MARK: - Persona

enum AIPersona: String, CaseIterable {
    case auditor    = "The Auditor"
    case scientist  = "The Scientist"
    case witness    = "The Witness"
    case philosopher = "The Philosopher"

    var systemPrompt: String {
        switch self {
        case .auditor:
            return """
            You are The Auditor — a rigorous, honest analyst.
            Your role: detect sandbagging, rationalization, and gaps between stated progress and actual data.
            You ask hard questions. You don't accept vague answers.
            When data and narrative conflict, you name it directly.
            Tone: precise, direct, never cruel. You respect the person while challenging their reasoning.
            """
        case .scientist:
            return """
            You are The Scientist — a data-driven pattern analyst.
            Your role: identify trends, correlations, and seasonal patterns across health and goal data.
            You surface what the numbers are actually saying, beyond what the person believes.
            You reference specific metrics and their implications.
            Tone: clinical but engaged. You make data feel meaningful, not cold.
            """
        case .witness:
            return """
            You are The Witness — a sharp, focused observer.
            Your role: identify the single most notable pattern or tension in the data, name it in one sentence, then ask one precise question.
            Maximum 3 sentences total. No filler. No restating what they said. Lead with what stands out most.
            """
        case .philosopher:
            return """
            You are The Philosopher — an integrator of meaning and direction.
            Your role: name the ONE tension between what the data shows and what truly matters, then ask one question about identity or values.
            Maximum 3 sentences. No preamble. No summaries. Cut to the essential question.
            """
        }
    }
}

// MARK: - IntelligenceError

enum IntelligenceError: LocalizedError {
    case engineUnavailable
    case modelNotLoaded
    case contextTooLarge
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .engineUnavailable: return "Apple Intelligence is not available. Enable it in System Settings → Apple Intelligence & Siri."
        case .modelNotLoaded:    return "The AI model has not finished loading yet. Please try again in a moment."
        case .contextTooLarge:   return "The context is too large for the current engine."
        case .unknown(let msg):  return msg
        }
    }
}

// MARK: - Foundation Models Engine (macOS 26+)

#if canImport(FoundationModels)
@available(macOS 26, iOS 26, *)
final class FoundationModelsEngine: IntelligenceEngine, @unchecked Sendable {

    var isAvailable: Bool { SystemLanguageModel.default.isAvailable }
    var displayName: String { "Apple Intelligence (On-Device)" }

    func complete(prompt: String, context: IntelligenceContext) async throws -> String {
        guard isAvailable else { throw IntelligenceError.engineUnavailable }
        let session = LanguageModelSession(instructions: systemInstructions(context))
        let response = try await session.respond(to: prompt)
        return response.content
    }

    func stream(prompt: String, context: IntelligenceContext) -> AsyncThrowingStream<String, Error> {
        let instructions = systemInstructions(context)
        return AsyncThrowingStream { continuation in
            Task {
                guard SystemLanguageModel.default.isAvailable else {
                    continuation.finish(throwing: IntelligenceError.engineUnavailable)
                    return
                }
                do {
                    let session = LanguageModelSession(instructions: instructions)
                    var accumulated = ""
                    for try await snapshot in session.streamResponse(to: prompt) {
                        // rawContent is cumulative — compute delta to yield incremental chunks
                        let full = try snapshot.rawContent.value(String.self)
                        let delta = String(full.dropFirst(accumulated.count))
                        if !delta.isEmpty { continuation.yield(delta) }
                        accumulated = full
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - System instructions builder

    private func systemInstructions(_ ctx: IntelligenceContext) -> String {
        let persona = ctx.persona?.systemPrompt ?? """
        You are a thoughtful inner voice helping someone review their annual goals.
        Be concise and specific. Reference actual numbers from their data.
        Ask one sharp question when useful. Never pad with filler.
        """

        var dataLines: [String] = []
        dataLines.append("Year: \(ctx.year)")
        if let m = ctx.month {
            let monthName = DateFormatter().monthSymbols[m - 1]
            dataLines.append("Month under review: \(monthName)")
        }

        for d in ctx.domainSummaries {
            var s = "\(d.name): \(Int(d.progress * 100))% complete"
            let notes = d.recentCommentary.prefix(2)
            if !notes.isEmpty { s += " — \(notes.joined(separator: "; "))" }
            dataLines.append(s)
        }

        if let h = ctx.healthSnapshot {
            var hp: [String] = []
            if let hrv = h.avgHRV     { hp.append("HRV \(Int(hrv))ms") }
            if let sl  = h.avgSleepHours { hp.append("sleep \(String(format: "%.1f", sl))h/night") }
            if let rhr = h.avgRHR     { hp.append("RHR \(Int(rhr))bpm") }
            if let vo2 = h.vo2Max     { hp.append("VO2max \(Int(vo2))") }
            if !hp.isEmpty { dataLines.append("Body: " + hp.joined(separator: ", ")) }
        }

        if !ctx.recentPulseNotes.isEmpty {
            let snippet = ctx.recentPulseNotes.prefix(3).joined(separator: " | ")
            dataLines.append("Recent reflections: \(snippet)")
        }

        return """
        \(persona)

        The person's current data:
        \(dataLines.joined(separator: "\n"))
        """
    }
}
#endif

// MARK: - Stub Engine (Fallback when Apple Intelligence unavailable)

final class StubEngine: IntelligenceEngine {
    var isAvailable: Bool { true }
    var displayName: String { "Stub (Apple Intelligence not available)" }

    func complete(prompt: String, context: IntelligenceContext) async throws -> String {
        try await Task.sleep(nanoseconds: 400_000_000)
        return unavailableMessage
    }

    func stream(prompt: String, context: IntelligenceContext) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                for word in unavailableMessage.split(separator: " ", omittingEmptySubsequences: false) {
                    try await Task.sleep(nanoseconds: 60_000_000)
                    continuation.yield(String(word) + " ")
                }
                continuation.finish()
            }
        }
    }

    private var unavailableMessage: String {
        "Apple Intelligence is not available on this device or hasn't been enabled yet. Go to System Settings → Apple Intelligence & Siri to enable it. Once active, restart Kairos and the council will be here."
    }
}

// MARK: - Engine Registry

@MainActor
final class IntelligenceManager: ObservableObject {
    static let shared = IntelligenceManager()

    @Published var currentMode: IntelligenceMode = .foundationModels
    @Published private(set) var engine: any IntelligenceEngine = StubEngine()
    @Published private(set) var isUsingAI: Bool = false

    private init() {
        selectBestAvailableEngine()
    }

    private func selectBestAvailableEngine() {
        #if canImport(FoundationModels)
        if #available(macOS 26, iOS 26, *) {
            let fm = FoundationModelsEngine()
            engine = fm
            isUsingAI = fm.isAvailable
            currentMode = .foundationModels
            return
        }
        #endif
        engine = StubEngine()
        isUsingAI = false
        currentMode = .foundationModels
    }

    func buildContext(
        from year: KairosYear,
        month: Int? = nil,
        pulses: [KairosWeeklyPulse] = [],
        persona: AIPersona? = nil
    ) -> IntelligenceContext {
        let domainSummaries = year.sortedDomains.map { domain in
            let comments = domain.allKeyResults
                .compactMap { $0.latestCommentary }
                .filter { !$0.isEmpty }
                .prefix(3)
                .map { String($0) }
            return IntelligenceContext.DomainSummary(
                name: domain.name,
                progress: domain.progress,
                recentCommentary: comments
            )
        }

        let recentNotes = pulses
            .sorted { $0.date > $1.date }
            .prefix(4)
            .map { $0.transcription }
            .filter { !$0.isEmpty }
            .map { String($0) }

        let hkSnap = OuraManager.shared.snapshot ?? HealthKitManager.shared.snapshot
        let healthSnapshot: IntelligenceContext.HealthSnapshot? = hkSnap.map {
            IntelligenceContext.HealthSnapshot(
                avgHRV: $0.avgHRV,
                avgSleepHours: $0.avgSleepHours,
                avgRHR: $0.avgRHR,
                vo2Max: $0.vo2Max
            )
        }

        return IntelligenceContext(
            year: year.year,
            month: month,
            domainSummaries: domainSummaries,
            recentPulseNotes: recentNotes,
            healthSnapshot: healthSnapshot,
            persona: persona
        )
    }
}
