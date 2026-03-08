import SwiftUI
import SwiftData

// MARK: - ReviewPhase

private enum ReviewPhase {
    case overview
    case wizard
    case interview
}

// MARK: - ReviewView

struct ReviewView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \KairosMonthlyReview.createdAt, order: .reverse) private var reviews: [KairosMonthlyReview]
    @Query(sort: \KairosYear.year, order: .reverse) private var years: [KairosYear]
    @Query(sort: \KairosWeeklyPulse.date, order: .reverse) private var pulses: [KairosWeeklyPulse]

    @StateObject private var intelligence = IntelligenceManager.shared

    // Phase
    @State private var phase: ReviewPhase = .overview

    // Wizard state
    @State private var wizardIndex: Int = 0
    @State private var pendingStatuses:     [PersistentIdentifier: KRStatus] = [:]
    @State private var pendingRatings:      [PersistentIdentifier: Int]      = [:]
    @State private var pendingCommentaries: [PersistentIdentifier: String]   = [:]

    // Interview state
    @State private var transcript: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isThinking = false
    @State private var streamingResponse = ""
    @State private var selectedReview: KairosMonthlyReview?

    private var currentMonthReview: KairosMonthlyReview? {
        let cal = Calendar.current
        let now = Date()
        return reviews.first {
            $0.year == cal.component(.year, from: now) &&
            $0.month == cal.component(.month, from: now)
        }
    }

    private var currentYear: KairosYear? { years.first { $0.year == 2026 } }

    /// All KRs across all domains, flattened, sorted domain → objective → KR
    private var allKRs: [(domain: KairosDomain, kr: KairosKeyResult)] {
        guard let year = currentYear else { return [] }
        return year.sortedDomains.flatMap { domain in
            domain.sortedObjectives.flatMap { obj in
                obj.sortedKeyResults.map { kr in (domain: domain, kr: kr) }
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                switch phase {
                case .overview:  overviewView
                case .wizard:    wizardView
                case .interview: interviewView
                }
            }
            .frame(maxWidth: .infinity)

            if !reviews.isEmpty && phase == .overview {
                KairosDivider().frame(width: 1).frame(maxHeight: .infinity)
                pastReviewsSidebar.frame(width: 260)
            }
        }
        .background(KairosTheme.Colors.background)
        .sheet(item: $selectedReview) { review in
            ReviewTranscriptSheet(review: review)
        }
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

                if let year = currentYear {
                    reviewDataPreview(year)
                }

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
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return f.string(from: Date())
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
            let recentPulses = pulses.prefix(4)
            if !recentPulses.isEmpty {
                HStack(spacing: KairosTheme.Spacing.md) {
                    Image(systemName: "waveform").foregroundStyle(KairosTheme.Colors.textMuted)
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
            Text("Ready for your monthly review?")
                .font(KairosTheme.Typography.headline)
                .foregroundStyle(KairosTheme.Colors.textPrimary)
            Text("First: rate each key result from last month. Then the council takes over.")
                .font(KairosTheme.Typography.body)
                .foregroundStyle(KairosTheme.Colors.textSecondary)

            HStack(spacing: KairosTheme.Spacing.sm) {
                // KR count badge
                if !allKRs.isEmpty {
                    Text("\(allKRs.count) key results to review")
                        .font(KairosTheme.Typography.monoSmall)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(KairosTheme.Colors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
                }
                Spacer()
            }

            Button { startWizard() } label: {
                HStack {
                    Image(systemName: "list.bullet.clipboard")
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
        .overlay(RoundedRectangle(cornerRadius: KairosTheme.Radius.md).stroke(KairosTheme.Colors.border, lineWidth: 1))
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
            // Re-enter council
            Button { startWizard() } label: {
                Text("New Review with the Council")
                    .font(KairosTheme.Typography.caption)
                    .foregroundStyle(KairosTheme.Colors.accent)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(KairosTheme.Spacing.lg)
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
    }

    // MARK: - KR Wizard

    private var wizardView: some View {
        let krs = allKRs
        guard !krs.isEmpty, wizardIndex < krs.count else {
            return AnyView(Color.clear.onAppear { commitWizardAndStartInterview() })
        }

        let item = krs[wizardIndex]
        let kr   = item.kr
        let dom  = item.domain
        let isLast = wizardIndex == krs.count - 1

        let currentStatus   = pendingStatuses[kr.id]     ?? kr.currentStatus
        let currentRating   = pendingRatings[kr.id]      ?? kr.latestRating
        let currentComment  = pendingCommentaries[kr.id] ?? kr.latestCommentary

        return AnyView(
            VStack(spacing: 0) {
                // Progress bar + header
                wizardHeader(total: krs.count, index: wizardIndex, domainName: dom.name, domainColor: KairosTheme.Colors.domain(dom.name))

                KairosDivider()

                ScrollView {
                    VStack(alignment: .leading, spacing: KairosTheme.Spacing.xl) {

                        // Domain tag
                        HStack(spacing: KairosTheme.Spacing.sm) {
                            Text(dom.emoji).font(.title3)
                            Text(dom.name.uppercased())
                                .font(KairosTheme.Typography.monoSmall)
                                .foregroundStyle(KairosTheme.Colors.domain(dom.name))
                                .tracking(1.5)
                        }

                        // KR title
                        Text(kr.title)
                            .font(KairosTheme.Typography.displayMedium)
                            .foregroundStyle(KairosTheme.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        // Status picker
                        VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
                            KairosLabel(text: "How did this land?")
                            WizardStatusPicker(selected: currentStatus) { newStatus in
                                pendingStatuses[kr.id] = newStatus
                            }
                        }

                        // Star rating
                        VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
                            KairosLabel(text: "Effort / satisfaction (1–5)")
                            WizardStarRating(rating: currentRating) { newRating in
                                pendingRatings[kr.id] = newRating
                            }
                        }

                        // Commentary
                        VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
                            KairosLabel(text: "Commentary")
                            TextField("What happened? What blocked you? Any wins?", text: Binding(
                                get: { pendingCommentaries[kr.id] ?? kr.latestCommentary },
                                set: { pendingCommentaries[kr.id] = $0 }
                            ), axis: .vertical)
                            .font(KairosTheme.Typography.body)
                            .foregroundStyle(KairosTheme.Colors.textPrimary)
                            .textFieldStyle(.plain)
                            .lineLimit(4...)
                            .padding(KairosTheme.Spacing.sm)
                            .background(KairosTheme.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
                            .overlay(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm).stroke(KairosTheme.Colors.border, lineWidth: 1))
                        }
                    }
                    .padding(KairosTheme.Spacing.xl)
                }

                KairosDivider()

                // Navigation buttons
                HStack(spacing: KairosTheme.Spacing.md) {
                    if wizardIndex > 0 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { wizardIndex -= 1 }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(KairosTheme.Typography.body)
                            .foregroundStyle(KairosTheme.Colors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if isLast {
                                commitWizardAndStartInterview()
                            } else {
                                wizardIndex += 1
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(isLast ? "Start Interview" : "Next")
                                .font(KairosTheme.Typography.headline)
                            Image(systemName: isLast ? "bubble.left.and.bubble.right.fill" : "chevron.right")
                        }
                        .foregroundStyle(KairosTheme.Colors.background)
                        .padding(.horizontal, KairosTheme.Spacing.lg)
                        .padding(.vertical, KairosTheme.Spacing.sm)
                        .background(isLast ? KairosTheme.Colors.accent : KairosTheme.Colors.accent.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
                    }
                    .buttonStyle(.plain)
                }
                .padding(KairosTheme.Spacing.md)
                .background(KairosTheme.Colors.surface)
            }
        )
    }

    private func wizardHeader(total: Int, index: Int, domainName: String, domainColor: Color) -> some View {
        VStack(spacing: KairosTheme.Spacing.xs) {
            HStack {
                Text(monthTitle.uppercased())
                    .font(KairosTheme.Typography.monoSmall)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
                    .tracking(1)
                Spacer()
                Text("KR \(index + 1) of \(total)")
                    .font(KairosTheme.Typography.monoSmall)
                    .foregroundStyle(KairosTheme.Colors.textMuted)

                Button("Cancel") {
                    withAnimation { phase = .overview }
                }
                .buttonStyle(.plain)
                .font(KairosTheme.Typography.caption)
                .foregroundStyle(KairosTheme.Colors.textMuted)
                .padding(.leading, KairosTheme.Spacing.sm)
            }
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1).fill(KairosTheme.Colors.border).frame(height: 2)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(domainColor)
                        .frame(width: geo.size.width * Double(index + 1) / Double(total), height: 2)
                }
            }
            .frame(height: 2)
        }
        .padding(.horizontal, KairosTheme.Spacing.xl)
        .padding(.top, KairosTheme.Spacing.md)
        .padding(.bottom, KairosTheme.Spacing.sm)
        .background(KairosTheme.Colors.surface)
    }

    // MARK: - Interview View

    private var interviewView: some View {
        VStack(spacing: 0) {
            // Engine status bar
            HStack {
                Image(systemName: intelligence.isUsingAI ? "cpu.fill" : "exclamationmark.triangle")
                    .font(.caption2)
                    .foregroundStyle(intelligence.isUsingAI ? KairosTheme.Colors.accent : KairosTheme.Colors.textMuted)
                Text(intelligence.engine.displayName)
                    .font(KairosTheme.Typography.monoSmall)
                    .foregroundStyle(intelligence.isUsingAI ? KairosTheme.Colors.textSecondary : KairosTheme.Colors.textMuted)
                Spacer()
                Button("End Review") { endInterview() }
                    .buttonStyle(.plain)
                    .font(KairosTheme.Typography.caption)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
            }
            .padding(.horizontal, KairosTheme.Spacing.xl)
            .padding(.vertical, KairosTheme.Spacing.sm)
            .background(KairosTheme.Colors.surface)

            KairosDivider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: KairosTheme.Spacing.md) {
                        ForEach(transcript) { message in
                            ChatBubble(message: message).id(message.id)
                        }
                        if isThinking || !streamingResponse.isEmpty {
                            ChatBubble(message: ChatMessage(
                                role: .ai, persona: .witness,
                                content: streamingResponse.isEmpty ? "…" : streamingResponse
                            ))
                            .id("streaming")
                        }
                    }
                    .padding(KairosTheme.Spacing.xl)
                }
                .onChange(of: transcript.count) { _, _ in
                    withAnimation { if let id = transcript.last?.id { proxy.scrollTo(id, anchor: .bottom) } }
                }
                .onChange(of: streamingResponse) { _, _ in proxy.scrollTo("streaming", anchor: .bottom) }
            }

            KairosDivider()

            HStack(spacing: KairosTheme.Spacing.sm) {
                Button { } label: {
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

                Button { sendResponse() } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title3)
                        .foregroundStyle(inputText.isEmpty ? KairosTheme.Colors.textMuted : KairosTheme.Colors.accent)
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty || isThinking)
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
                    Button { selectedReview = review } label: {
                        PastReviewRow(review: review) {
                            context.delete(review)
                            try? context.save()
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            context.delete(review)
                            try? context.save()
                        } label: {
                            Label("Delete Review", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .background(KairosTheme.Colors.surface)
    }

    // MARK: - Wizard Logic

    private func startWizard() {
        wizardIndex = 0
        pendingStatuses = [:]
        pendingRatings = [:]
        pendingCommentaries = [:]

        // Pre-populate from existing current-month entries
        let cal = Calendar.current
        let now = Date()
        let thisYear = cal.component(.year, from: now)
        let thisMonth = cal.component(.month, from: now)
        for item in allKRs {
            if let entry = item.kr.entries.first(where: { $0.year == thisYear && $0.month == thisMonth }) {
                pendingStatuses[item.kr.id]     = entry.statusEnum
                pendingRatings[item.kr.id]      = entry.rating
                pendingCommentaries[item.kr.id] = entry.commentary
            }
        }
        withAnimation { phase = .wizard }
    }

    private func commitWizardAndStartInterview() {
        let cal = Calendar.current
        let now = Date()
        let thisYear  = cal.component(.year,  from: now)
        let thisMonth = cal.component(.month, from: now)

        for item in allKRs {
            let kr     = item.kr
            let status = pendingStatuses[kr.id]     ?? kr.currentStatus
            let rating = pendingRatings[kr.id]      ?? 0
            let note   = pendingCommentaries[kr.id] ?? ""

            // Find or create entry for this month
            if let existing = kr.entries.first(where: { $0.year == thisYear && $0.month == thisMonth }) {
                existing.statusEnum  = status
                existing.rating      = rating
                existing.commentary  = note
            } else {
                let entry = KairosMonthlyEntry(year: thisYear, month: thisMonth, status: status, rating: rating, commentary: note)
                context.insert(entry)
                kr.entries.append(entry)
            }
        }
        try? context.save()
        startInterview()
    }

    // MARK: - Interview Logic

    private func startInterview() {
        transcript = []
        phase = .interview
        transcript.append(ChatMessage(role: .ai, persona: .witness, content: openingMessage()))
    }

    private func openingMessage() -> String {
        let cal   = Calendar.current
        let month = cal.component(.month, from: Date())
        let year  = cal.component(.year,  from: Date())
        let name  = DateFormatter().monthSymbols[month - 1]

        var parts = ["It's \(name) \(year)."]
        if let y = currentYear {
            let lowDomains = y.sortedDomains.filter { $0.progress < 0.2 }.map { $0.name }
            if !lowDomains.isEmpty { parts.append("I notice \(lowDomains.joined(separator: ", ")) hasn't moved much.") }
        }
        if !pulses.isEmpty {
            let avg = pulses.prefix(4).map { Double($0.energyLevel) }.reduce(0, +) / min(4.0, Double(pulses.count))
            parts.append("Your average energy this period was \(String(format: "%.1f", avg))/10.")
        }
        // Reference wizard data
        let doneCount = pendingStatuses.values.filter { $0 == .done }.count
        let blockedCount = pendingStatuses.values.filter { $0 == .blocked }.count
        if doneCount > 0 || blockedCount > 0 {
            parts.append("You just marked \(doneCount) done and \(blockedCount) blocked.")
        }
        parts.append("\nIs there something pressing you want to start with — or should I begin with what the data is showing?")
        return parts.joined(separator: " ")
    }

    private func sendResponse() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let userMsg = ChatMessage(role: .user, content: inputText)
        transcript.append(userMsg)
        let sent = inputText
        inputText = ""
        isThinking = true
        streamingResponse = ""
        let persona = nextPersona()

        Task {
            guard let year = currentYear else {
                await MainActor.run { isThinking = false }; return
            }
            let ctx = intelligence.buildContext(
                from: year,
                month: Calendar.current.component(.month, from: Date()),
                pulses: Array(pulses.prefix(4)),
                persona: persona
            )
            let prompt = buildPrompt(userMessage: sent)
            do {
                for try await chunk in intelligence.engine.stream(prompt: prompt, context: ctx) {
                    await MainActor.run { streamingResponse += chunk }
                }
                await MainActor.run {
                    transcript.append(ChatMessage(role: .ai, persona: persona, content: streamingResponse))
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
            year:  Calendar.current.component(.year,  from: Date()),
            month: Calendar.current.component(.month, from: Date())
        )
        review.transcript = transcript
            .map { "\($0.role == .user ? "You" : $0.persona?.rawValue ?? "Council"): \($0.content)" }
            .joined(separator: "\n\n")
        context.insert(review)
        try? context.save()
        withAnimation { phase = .overview }
    }
}

// MARK: - WizardStatusPicker

struct WizardStatusPicker: View {
    let selected: KRStatus
    let onSelect: (KRStatus) -> Void

    var body: some View {
        let statuses: [KRStatus] = [.notStarted, .inProgress, .done, .blocked, .paused]
        FlowLayout(spacing: KairosTheme.Spacing.sm) {
            ForEach(statuses, id: \.self) { status in
                Button {
                    onSelect(status)
                } label: {
                    Text(status.displayName)
                        .font(KairosTheme.Typography.monoSmall)
                        .foregroundStyle(selected == status ? KairosTheme.Colors.background : KairosTheme.Colors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(selected == status ? KairosTheme.Colors.status(status) : KairosTheme.Colors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
                        .overlay(
                            RoundedRectangle(cornerRadius: KairosTheme.Radius.sm)
                                .stroke(selected == status ? Color.clear : KairosTheme.Colors.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - WizardStarRating

struct WizardStarRating: View {
    let rating: Int
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { i in
                Button {
                    onSelect(rating == i ? 0 : i)  // tap same star to clear
                } label: {
                    Image(systemName: i <= rating ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundStyle(i <= rating ? Color(hex: "#DAB25A") : KairosTheme.Colors.textMuted)
                }
                .buttonStyle(.plain)
            }
            if rating > 0 {
                Text(ratingLabel)
                    .font(KairosTheme.Typography.monoSmall)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
                    .padding(.leading, 4)
            }
        }
    }

    private var ratingLabel: String {
        switch rating {
        case 1: return "Rough"
        case 2: return "Below expectations"
        case 3: return "Solid"
        case 4: return "Strong"
        case 5: return "Exceptional"
        default: return ""
        }
    }
}

// MARK: - FlowLayout (wrapping HStack for pills)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }
                        .reduce(0) { $0 + $1 + spacing } - spacing
        return CGSize(width: proposal.width ?? 0, height: max(height, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubview]] = [[]]
        var rowWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth && !rows[rows.endIndex - 1].isEmpty {
                rows.append([])
                rowWidth = 0
            }
            rows[rows.endIndex - 1].append(subview)
            rowWidth += size.width + spacing
        }
        return rows
    }
}

// MARK: - Chat Models

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    var persona: AIPersona?
    let content: String
    init(role: ChatRole, persona: AIPersona? = nil, content: String) {
        self.role = role; self.persona = persona; self.content = content
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

// MARK: - ReviewTranscriptSheet

struct ReviewTranscriptSheet: View {
    let review: KairosMonthlyReview
    @Environment(\.dismiss) private var dismiss

    private static let formatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f
    }()

    private var monthString: String {
        let c = DateComponents(year: review.year, month: review.month, day: 1)
        guard let date = Calendar.current.date(from: c) else { return "\(review.month)/\(review.year)" }
        return Self.formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    KairosLabel(text: "Monthly Review")
                    Text(monthString)
                        .font(KairosTheme.Typography.displayMedium)
                        .foregroundStyle(KairosTheme.Colors.textPrimary)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(KairosTheme.Spacing.xl)

            KairosDivider()

            ScrollView {
                Text(review.transcript.isEmpty ? "No transcript recorded." : review.transcript)
                    .font(KairosTheme.Typography.body)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(KairosTheme.Spacing.xl)
            }
        }
        .background(KairosTheme.Colors.background)
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 400)
        #else
        .frame(minWidth: 320, minHeight: 400)
        #endif
    }
}

// MARK: - PastReviewRow

struct PastReviewRow: View {
    let review: KairosMonthlyReview
    var onDelete: (() -> Void)? = nil

    private static let formatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM yyyy"; return f
    }()
    private var monthString: String {
        let c = DateComponents(year: review.year, month: review.month, day: 1)
        guard let date = Calendar.current.date(from: c) else { return "\(review.month)/\(review.year)" }
        return Self.formatter.string(from: date)
    }
    var body: some View {
        HStack(alignment: .top, spacing: KairosTheme.Spacing.xs) {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                Text(monthString)
                    .font(KairosTheme.Typography.mono)
                    .foregroundStyle(KairosTheme.Colors.textSecondary)
                if !review.transcript.isEmpty {
                    Text(review.transcript)
                        .font(KairosTheme.Typography.caption)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                        .lineLimit(2)
                }
            }
            Spacer()
            // Inline trash — always visible
            if let onDelete {
                Button { onDelete() } label: {
                    Image(systemName: "trash")
                        .font(.caption2)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                        .touchTarget()
                }
                .buttonStyle(.plain)
                .help("Delete review")
            }
        }
        .padding(KairosTheme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
