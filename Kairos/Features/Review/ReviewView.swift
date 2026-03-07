import SwiftUI
import SwiftData

struct ReviewView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \KairosMonthlyReview.createdAt, order: .reverse) private var reviews: [KairosMonthlyReview]
    @Query(sort: \KairosYear.year, order: .reverse) private var years: [KairosYear]
    @Query(sort: \KairosWeeklyPulse.date, order: .reverse) private var pulses: [KairosWeeklyPulse]

    @StateObject private var intelligence = IntelligenceManager.shared
    @State private var isInInterview = false
    @State private var transcript: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isThinking = false
    @State private var streamingResponse = ""

    private var currentMonthReview: KairosMonthlyReview? {
        let cal = Calendar.current
        let now = Date()
        return reviews.first {
            $0.year == cal.component(.year, from: now) &&
            $0.month == cal.component(.month, from: now)
        }
    }

    private var currentYear: KairosYear? { years.first { $0.year == 2026 } }

    var body: some View {
        HStack(spacing: 0) {
            // Main content
            VStack(spacing: 0) {
                if isInInterview {
                    interviewView
                } else {
                    overviewView
                }
            }
            .frame(maxWidth: .infinity)

            // Past reviews sidebar
            if !reviews.isEmpty && !isInInterview {
                KairosDivider().frame(width: 1).frame(maxHeight: .infinity)
                pastReviewsSidebar
                    .frame(width: 260)
            }
        }
        .background(KairosTheme.Colors.background)
    }

    // MARK: - Overview

    private var overviewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                    KairosLabel(text: "Monthly Review")
                    Text(monthTitle)
                        .font(KairosTheme.Typography.displayMedium)
                        .foregroundStyle(KairosTheme.Colors.textPrimary)
                }

                // Data preview cards (feeds the interview)
                if let year = currentYear {
                    reviewDataPreview(year)
                }

                // Start / resume
                if currentMonthReview != nil {
                    resumeCard
                } else {
                    startCard
                }
            }
            .padding(KairosTheme.Spacing.xl)
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    private func reviewDataPreview(_ year: KairosYear) -> some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
            KairosLabel(text: "What the council will see")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: KairosTheme.Spacing.sm) {
                ForEach(year.sortedDomains) { domain in
                    HStack {
                        Text(domain.emoji)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(domain.name)
                                .font(KairosTheme.Typography.caption)
                                .foregroundStyle(KairosTheme.Colors.textSecondary)
                            Text("\(Int(domain.progress * 100))% · \(domain.allKeyResults.count) KRs")
                                .font(KairosTheme.Typography.monoSmall)
                                .foregroundStyle(KairosTheme.Colors.textMuted)
                        }
                        Spacer()
                        Circle()
                            .trim(from: 0, to: domain.progress)
                            .stroke(KairosTheme.Colors.domain(domain.name), lineWidth: 2)
                            .rotationEffect(.degrees(-90))
                            .frame(width: 20, height: 20)
                    }
                    .padding(KairosTheme.Spacing.sm)
                    .background(KairosTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
                }
            }

            // Pulse summary
            let recentPulses = pulses.prefix(4)
            if !recentPulses.isEmpty {
                HStack(spacing: KairosTheme.Spacing.md) {
                    Image(systemName: "waveform")
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                    Text("\(recentPulses.count) pulse entries this period")
                        .font(KairosTheme.Typography.caption)
                        .foregroundStyle(KairosTheme.Colors.textSecondary)
                    let avgEnergy = recentPulses.map { Double($0.energyLevel) }.reduce(0, +) / Double(recentPulses.count)
                    Text("Avg energy: \(String(format: "%.1f", avgEnergy))/10")
                        .font(KairosTheme.Typography.monoSmall)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                }
                .padding(KairosTheme.Spacing.sm)
                .background(KairosTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
            }
        }
    }

    private var startCard: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.md) {
            Text("Ready for your monthly interview?")
                .font(KairosTheme.Typography.headline)
                .foregroundStyle(KairosTheme.Colors.textPrimary)
            Text("The council will lead. You respond. Expect 20–30 minutes. Voice or text — your choice.")
                .font(KairosTheme.Typography.body)
                .foregroundStyle(KairosTheme.Colors.textSecondary)

            Button {
                startInterview()
            } label: {
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Begin \(monthTitle) Review")
                        .font(KairosTheme.Typography.headline)
                }
                .foregroundStyle(KairosTheme.Colors.background)
                .frame(maxWidth: .infinity)
                .padding(KairosTheme.Spacing.md)
                .background(KairosTheme.Colors.accent)
                .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
            }
            .buttonStyle(.plain)
        }
        .padding(KairosTheme.Spacing.lg)
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
                .stroke(KairosTheme.Colors.border, lineWidth: 1)
        )
    }

    private var resumeCard: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(KairosTheme.Colors.status(.done))
                Text("Review complete for \(monthTitle)")
                    .font(KairosTheme.Typography.headline)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
            }
            if let review = currentMonthReview, !review.summaryPoints.isEmpty {
                VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                    KairosLabel(text: "Executive Summary")
                    ForEach(Array(review.summaryPoints.enumerated()), id: \.offset) { i, point in
                        HStack(alignment: .top, spacing: KairosTheme.Spacing.sm) {
                            Text("\(i + 1).")
                                .font(KairosTheme.Typography.mono)
                                .foregroundStyle(KairosTheme.Colors.accent)
                                .frame(width: 16)
                            Text(point)
                                .font(KairosTheme.Typography.body)
                                .foregroundStyle(KairosTheme.Colors.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(KairosTheme.Spacing.lg)
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
    }

    // MARK: - Interview View

    private var interviewView: some View {
        VStack(spacing: 0) {
            // Chat area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: KairosTheme.Spacing.md) {
                        ForEach(transcript) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                        if isThinking || !streamingResponse.isEmpty {
                            ChatBubble(message: ChatMessage(
                                role: .ai,
                                persona: .witness,
                                content: streamingResponse.isEmpty ? "…" : streamingResponse
                            ))
                            .id("streaming")
                        }
                    }
                    .padding(KairosTheme.Spacing.xl)
                }
                .onChange(of: transcript.count) { _, _ in
                    withAnimation { proxy.scrollTo(transcript.last?.id ?? "streaming", anchor: .bottom) }
                }
                .onChange(of: streamingResponse) { _, _ in
                    proxy.scrollTo("streaming", anchor: .bottom)
                }
            }

            KairosDivider()

            // Input bar
            HStack(spacing: KairosTheme.Spacing.sm) {
                Button {
                    // TODO: Voice input
                } label: {
                    Image(systemName: "mic.circle")
                        .font(.title3)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                }
                .buttonStyle(.plain)

                TextField("Respond…", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(KairosTheme.Typography.body)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                    .lineLimit(5)
                    .onSubmit { sendResponse() }

                Button {
                    sendResponse()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title3)
                        .foregroundStyle(inputText.isEmpty ? KairosTheme.Colors.textMuted : KairosTheme.Colors.accent)
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty || isThinking)

                Button("End Review") {
                    endInterview()
                }
                .buttonStyle(.plain)
                .font(KairosTheme.Typography.caption)
                .foregroundStyle(KairosTheme.Colors.textMuted)
            }
            .padding(KairosTheme.Spacing.md)
            .background(KairosTheme.Colors.surface)
        }
    }

    // MARK: - Past Reviews Sidebar

    private var pastReviewsSidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
                KairosLabel(text: "Past Reviews")
                    .padding(.horizontal, KairosTheme.Spacing.md)
                    .padding(.top, KairosTheme.Spacing.xl)

                ForEach(reviews) { review in
                    PastReviewRow(review: review)
                }
            }
        }
        .background(KairosTheme.Colors.surface)
    }

    // MARK: - Logic

    private func startInterview() {
        transcript = []
        isInInterview = true

        let opening = ChatMessage(
            role: .ai,
            persona: .witness,
            content: openingMessage()
        )
        transcript.append(opening)
    }

    private func openingMessage() -> String {
        let cal = Calendar.current
        let month = cal.component(.month, from: Date())
        let year = cal.component(.year, from: Date())
        let monthName = DateFormatter().monthSymbols[month - 1]

        var context = "It's \(monthName) \(year)."
        if let y = currentYear {
            let lowDomains = y.sortedDomains.filter { $0.progress < 0.2 }.map { $0.name }
            if !lowDomains.isEmpty {
                context += " Before we begin — I notice \(lowDomains.joined(separator: ", ")) hasn't moved much."
            }
        }
        if !pulses.isEmpty {
            let recentPulses = pulses.prefix(4)
            let avgE = recentPulses.map { Double($0.energyLevel) }.reduce(0, +) / Double(recentPulses.count)
            context += " Your average energy this period was \(String(format: "%.1f", avgE))/10."
        }

        return "\(context)\n\nIs there something pressing you want to start with — or should I begin with what the data is showing?"
    }

    private func sendResponse() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let userMsg = ChatMessage(role: .user, content: inputText)
        transcript.append(userMsg)
        let sent = inputText
        inputText = ""
        isThinking = true
        streamingResponse = ""

        Task {
            guard let year = currentYear else {
                await MainActor.run { isThinking = false }
                return
            }
            let ctx = intelligence.buildContext(from: year, month: Calendar.current.component(.month, from: Date()), pulses: Array(pulses.prefix(4)))
            let prompt = buildPrompt(userMessage: sent)

            do {
                for try await chunk in intelligence.engine.stream(prompt: prompt, context: ctx) {
                    await MainActor.run { streamingResponse += chunk }
                }
                await MainActor.run {
                    let response = ChatMessage(role: .ai, persona: nextPersona(), content: streamingResponse)
                    transcript.append(response)
                    streamingResponse = ""
                    isThinking = false
                }
            } catch {
                await MainActor.run {
                    transcript.append(ChatMessage(role: .ai, persona: .witness, content: "Something went wrong: \(error.localizedDescription)"))
                    isThinking = false
                    streamingResponse = ""
                }
            }
        }
    }

    private func buildPrompt(userMessage: String) -> String {
        let history = transcript.suffix(6).map { "\($0.role == .user ? "User" : "Council"): \($0.content)" }.joined(separator: "\n")
        return "\(history)\nUser: \(userMessage)\nCouncil:"
    }

    private func nextPersona() -> AIPersona {
        let personas: [AIPersona] = [.witness, .auditor, .scientist, .philosopher]
        let aiCount = transcript.filter { $0.role == .ai }.count
        return personas[aiCount % personas.count]
    }

    private func endInterview() {
        let review = KairosMonthlyReview(
            year: Calendar.current.component(.year, from: Date()),
            month: Calendar.current.component(.month, from: Date())
        )
        review.transcript = transcript.map { "\($0.role == .user ? "You" : $0.persona?.rawValue ?? "Council"): \($0.content)" }.joined(separator: "\n\n")
        context.insert(review)
        try? context.save()
        withAnimation { isInInterview = false }
    }
}

// MARK: - Chat Models

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    var persona: AIPersona?
    let content: String

    init(role: ChatRole, persona: AIPersona? = nil, content: String) {
        self.role = role
        self.persona = persona
        self.content = content
    }
}

enum ChatRole { case user, ai }

// MARK: - ChatBubble

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: KairosTheme.Spacing.sm) {
            if message.role == .ai {
                VStack(alignment: .leading, spacing: 2) {
                    if let persona = message.persona {
                        Text(persona.rawValue.uppercased())
                            .font(KairosTheme.Typography.label)
                            .foregroundStyle(KairosTheme.Colors.accent)
                            .tracking(1)
                    }
                    Text(message.content)
                        .font(KairosTheme.Typography.body)
                        .foregroundStyle(KairosTheme.Colors.textPrimary)
                        .textSelection(.enabled)
                }
                .padding(KairosTheme.Spacing.md)
                .background(KairosTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
                .frame(maxWidth: 580, alignment: .leading)
                Spacer()
            } else {
                Spacer()
                Text(message.content)
                    .font(KairosTheme.Typography.body)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                    .textSelection(.enabled)
                    .padding(KairosTheme.Spacing.md)
                    .background(KairosTheme.Colors.accentSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
                    .frame(maxWidth: 480, alignment: .trailing)
            }
        }
    }
}

// MARK: - PastReviewRow

struct PastReviewRow: View {
    let review: KairosMonthlyReview
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f
    }()
    private var monthString: String {
        let c = DateComponents(year: review.year, month: review.month, day: 1)
        guard let date = Calendar.current.date(from: c) else { return "\(review.month)/\(review.year)" }
        return Self.formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
            Text(monthString)
                .font(KairosTheme.Typography.mono)
                .foregroundStyle(KairosTheme.Colors.textSecondary)
            if let point = review.summaryPoints.first {
                Text(point)
                    .font(KairosTheme.Typography.caption)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
                    .lineLimit(2)
            }
        }
        .padding(KairosTheme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
