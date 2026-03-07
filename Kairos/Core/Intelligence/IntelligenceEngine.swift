import Foundation

// MARK: - IntelligenceEngine Protocol
//
// All AI calls in Kairos go through this protocol.
// Today: FoundationModelsEngine (on-device, macOS 15+) or APIEngine (dev/testing).
// Future: MLXEngine (local Llama, pre-App Store refactor).
// No other file knows which engine is active.

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
    case foundationModels = "On-Device (Foundation Models)"
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
            You are The Witness — a compassionate, non-judgmental mirror.
            Your role: reflect back what you hear without interpretation or advice.
            You notice what is present and what is conspicuously absent.
            You name emotional subtext without projecting.
            Tone: warm, slow, spacious. You ask one question at a time. You listen more than you speak.
            """
        case .philosopher:
            return """
            You are The Philosopher — an integrator of meaning and direction.
            Your role: examine whether goals align with values, whether effort connects to purpose.
            You reference psychology, philosophy, and contemplative traditions when relevant.
            You ask about identity, not just outcomes.
            Tone: reflective, unhurried, occasionally provocative. You invite depth.
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
        case .engineUnavailable: return "The intelligence engine is not available on this system."
        case .modelNotLoaded:    return "The AI model has not been loaded yet."
        case .contextTooLarge:   return "The context is too large for the current engine."
        case .unknown(let msg):  return msg
        }
    }
}

// MARK: - Stub Engine (Development Placeholder)
// Replace with FoundationModelsEngine when targeting macOS 15+

final class StubEngine: IntelligenceEngine {
    var isAvailable: Bool { true }
    var displayName: String { "Stub (Development)" }

    func complete(prompt: String, context: IntelligenceContext) async throws -> String {
        // Simulate a brief delay
        try await Task.sleep(nanoseconds: 800_000_000)
        return """
        [Stub response — replace with real engine]

        You asked about \(context.year), month \(context.month ?? 0).
        Overall progress across domains is visible in your dashboard.

        To enable real AI responses, configure an IntelligenceEngine in Settings.
        """
    }

    func stream(prompt: String, context: IntelligenceContext) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let words = ["Stub", " response.", " Configure", " an", " engine", " in", " Settings."]
                for word in words {
                    try await Task.sleep(nanoseconds: 150_000_000)
                    continuation.yield(word)
                }
                continuation.finish()
            }
        }
    }
}

// MARK: - Engine Registry

@MainActor
final class IntelligenceManager: ObservableObject {
    static let shared = IntelligenceManager()

    @Published var currentMode: IntelligenceMode = .foundationModels
    @Published private(set) var engine: any IntelligenceEngine = StubEngine()

    private init() {
        selectBestAvailableEngine()
    }

    private func selectBestAvailableEngine() {
        // TODO: Check for Foundation Models availability (macOS 15+)
        // TODO: Fall back to API engine if configured
        // For now: use stub
        engine = StubEngine()
        currentMode = .foundationModels
    }

    func buildContext(from year: KairosYear, month: Int? = nil, pulses: [KairosWeeklyPulse] = []) -> IntelligenceContext {
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

        return IntelligenceContext(
            year: year.year,
            month: month,
            domainSummaries: domainSummaries,
            recentPulseNotes: recentNotes,
            healthSnapshot: nil  // TODO: populate from HealthKit
        )
    }
}
