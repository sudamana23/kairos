import SwiftUI
import SwiftData

// MARK: - Draft Types

struct WizardDomain: Identifiable {
    var id = UUID()
    var name: String
    var emoji: String
    var colorHex: String
    var sortOrder: Int
    var enabled = true
    var note = ""
    var objectives: [WizardObjective] = []
}

struct WizardObjective: Identifiable {
    var id = UUID()
    var title: String
    var enabled = true
    var keyResults: [WizardKR] = []
}

struct WizardKR: Identifiable {
    var id = UUID()
    var title: String
    var enabled = true
}

// MARK: - YearWizardView

struct YearWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \KairosYear.year, order: .reverse) private var years: [KairosYear]
    @Query(sort: \KairosWeeklyPulse.date, order: .reverse) private var pulses: [KairosWeeklyPulse]

    @State private var step = 0
    @State private var targetYear: Int
    @State private var yearIntention = ""
    @State private var domains: [WizardDomain] = []
    @State private var blindspot = ""
    @State private var reviewText = ""
    @State private var isLoading = false
    @State private var loadingMessage = ""

    private let stepLabels = ["Setup", "Domains", "Objectives", "Key Results", "Review"]

    init(defaultYear: Int? = nil) {
        let cal = Calendar.current
        let now = Date()
        let y = cal.component(.year, from: now)
        let m = cal.component(.month, from: now)
        _targetYear = State(initialValue: defaultYear ?? (m >= 10 ? y + 1 : y))
    }

    private var previousYear: KairosYear? {
        years.first { $0.year == targetYear - 1 }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            KairosDivider()

            if isLoading {
                loadingView
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: KairosTheme.Spacing.xl) {
                        stepContent
                    }
                    .padding(KairosTheme.Spacing.xl)
                    .frame(maxWidth: 660, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
            }

            KairosDivider()
            navBar
        }
        .background(KairosTheme.Colors.background)
        .frame(minWidth: 660, minHeight: 520)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            KairosLabel(text: stepLabels[step])
            Spacer()
            HStack(spacing: 5) {
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(i <= step ? KairosTheme.Colors.accent : KairosTheme.Colors.border)
                        .frame(width: i == step ? 20 : 8, height: 3)
                        .animation(.easeInOut(duration: 0.2), value: step)
                }
            }
        }
        .padding(.horizontal, KairosTheme.Spacing.xl)
        .padding(.vertical, KairosTheme.Spacing.md)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0: introStep
        case 1: domainsStep
        case 2: objectivesStep
        case 3: keyResultsStep
        case 4: reviewStep
        default: EmptyView()
        }
    }

    // MARK: - Step 0: Intro

    private var introStep: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                Text("Setting up a new year")
                    .font(KairosTheme.Typography.displayMedium)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                Text("AI will propose domains, objectives, and key results — you decide what stays.")
                    .font(KairosTheme.Typography.body)
                    .foregroundStyle(KairosTheme.Colors.textSecondary)
            }

            // Year picker
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                KairosLabel(text: "Which year?")
                HStack(spacing: KairosTheme.Spacing.sm) {
                    Button { if targetYear > 2020 { targetYear -= 1 } } label: {
                        Image(systemName: "minus.circle")
                            .font(.title3)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                    }
                    .buttonStyle(.plain)
                    Text(String(targetYear))
                        .font(KairosTheme.Typography.mono)
                        .foregroundStyle(KairosTheme.Colors.textPrimary)
                        .frame(width: 64, alignment: .center)
                    Button { targetYear += 1 } label: {
                        Image(systemName: "plus.circle")
                            .font(.title3)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                    }
                    .buttonStyle(.plain)
                }
                .padding(KairosTheme.Spacing.sm)
                .background(KairosTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
                .overlay(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm).stroke(KairosTheme.Colors.border, lineWidth: 1))
            }

            // Year intention
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                KairosLabel(text: "Year Intention (optional)")
                TextField("e.g. Build the foundations for the decade ahead", text: $yearIntention)
                    .textFieldStyle(.plain)
                    .font(KairosTheme.Typography.body)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                    .padding(KairosTheme.Spacing.sm)
                    .background(KairosTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: KairosTheme.Radius.sm)
                            .stroke(KairosTheme.Colors.border, lineWidth: 1)
                    )
            }

            // Previous year summary
            if let prev = previousYear {
                prevYearSnapshot(prev)
            }
        }
    }

    private func prevYearSnapshot(_ year: KairosYear) -> some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
            KairosLabel(text: "\(String(year.year)) at a glance")
            HStack(spacing: KairosTheme.Spacing.md) {
                ForEach(year.sortedDomains) { domain in
                    VStack(spacing: 3) {
                        Text(domain.emoji).font(.title3)
                        Text("\(Int(domain.progress * 100))%")
                            .font(KairosTheme.Typography.monoSmall)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                    }
                }
            }
            .padding(KairosTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(KairosTheme.Spacing.md)
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: KairosTheme.Radius.md).stroke(KairosTheme.Colors.border, lineWidth: 1))
    }

    // MARK: - Step 1: Domains

    private var domainsStep: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                Text("Life Domains")
                    .font(KairosTheme.Typography.displayMedium)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                Text("Toggle off domains you won't track. Edit names inline.")
                    .font(KairosTheme.Typography.body)
                    .foregroundStyle(KairosTheme.Colors.textSecondary)
            }

            if !blindspot.isEmpty {
                HStack(spacing: KairosTheme.Spacing.sm) {
                    Image(systemName: "lightbulb").foregroundStyle(KairosTheme.Colors.accent).font(.caption)
                    Text(blindspot)
                        .font(KairosTheme.Typography.caption)
                        .foregroundStyle(KairosTheme.Colors.textSecondary)
                }
                .padding(KairosTheme.Spacing.sm)
                .background(KairosTheme.Colors.accentSubtle)
                .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
            }

            VStack(spacing: KairosTheme.Spacing.xs) {
                ForEach($domains) { $domain in
                    HStack(spacing: KairosTheme.Spacing.md) {
                        Toggle("", isOn: $domain.enabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .scaleEffect(0.75)
                        Text(domain.emoji).font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(domain.name)
                                .font(KairosTheme.Typography.headline)
                                .foregroundStyle(domain.enabled ? KairosTheme.Colors.textPrimary : KairosTheme.Colors.textMuted)
                            if !domain.note.isEmpty {
                                Text(domain.note)
                                    .font(KairosTheme.Typography.caption)
                                    .foregroundStyle(KairosTheme.Colors.textSecondary)
                                    .italic()
                            }
                        }
                        Spacer()
                    }
                    .padding(KairosTheme.Spacing.md)
                    .background(KairosTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
                            .stroke(domain.enabled ? KairosTheme.Colors.border : KairosTheme.Colors.borderSubtle, lineWidth: 1)
                    )
                    .opacity(domain.enabled ? 1 : 0.5)
                    .animation(.easeInOut(duration: 0.15), value: domain.enabled)
                }
            }

            Button {
                domains.append(WizardDomain(name: "New Domain", emoji: "✦", colorHex: "#6A6A8A", sortOrder: domains.count))
            } label: {
                Label("Add domain", systemImage: "plus")
                    .font(KairosTheme.Typography.caption)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Step 2: Objectives

    private var objectivesStep: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                Text("Objectives")
                    .font(KairosTheme.Typography.displayMedium)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                Text("What you're aiming to achieve this year. Toggle, edit, or add.")
                    .font(KairosTheme.Typography.body)
                    .foregroundStyle(KairosTheme.Colors.textSecondary)
            }

            ForEach($domains) { $domain in
                if domain.enabled {
                    domainObjectivesCard(domain: $domain)
                }
            }
        }
    }

    private func domainObjectivesCard(domain: Binding<WizardDomain>) -> some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
            Text(domain.wrappedValue.name.uppercased())
                .font(KairosTheme.Typography.label)
                .foregroundStyle(KairosTheme.Colors.textMuted)
                .tracking(1.5)

            ForEach(domain.objectives) { $obj in
                HStack(spacing: KairosTheme.Spacing.sm) {
                    Toggle("", isOn: $obj.enabled)
                        #if os(macOS)
                        .toggleStyle(.checkbox)
                        #endif
                        .labelsHidden()
                    TextField("Objective", text: $obj.title)
                        .textFieldStyle(.plain)
                        .font(KairosTheme.Typography.body)
                        .foregroundStyle(obj.enabled ? KairosTheme.Colors.textPrimary : KairosTheme.Colors.textMuted)
                }
                .padding(.vertical, 2)
            }

            Button {
                domain.objectives.wrappedValue.append(WizardObjective(title: ""))
            } label: {
                Label("Add objective", systemImage: "plus")
                    .font(KairosTheme.Typography.caption)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(KairosTheme.Spacing.md)
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: KairosTheme.Radius.md).stroke(KairosTheme.Colors.border, lineWidth: 1))
    }

    // MARK: - Step 3: Key Results

    private var keyResultsStep: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                Text("Key Results")
                    .font(KairosTheme.Typography.displayMedium)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                Text("Measurable outcomes for each objective. Toggle, edit, or add.")
                    .font(KairosTheme.Typography.body)
                    .foregroundStyle(KairosTheme.Colors.textSecondary)
            }

            ForEach($domains) { $domain in
                if domain.enabled {
                    ForEach($domain.objectives) { $obj in
                        if obj.enabled && !obj.title.isEmpty {
                            objectiveKRCard(objective: $obj, domainEmoji: domain.emoji)
                        }
                    }
                }
            }
        }
    }

    private func objectiveKRCard(objective: Binding<WizardObjective>, domainEmoji: String) -> some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
            Text(objective.wrappedValue.title)
                .font(KairosTheme.Typography.caption)
                .foregroundStyle(KairosTheme.Colors.textSecondary)
                .lineLimit(1)

            ForEach(objective.keyResults) { $kr in
                HStack(spacing: KairosTheme.Spacing.sm) {
                    Toggle("", isOn: $kr.enabled)
                        #if os(macOS)
                        .toggleStyle(.checkbox)
                        #endif
                        .labelsHidden()
                    TextField("Key result", text: $kr.title)
                        .textFieldStyle(.plain)
                        .font(KairosTheme.Typography.body)
                        .foregroundStyle(kr.enabled ? KairosTheme.Colors.textPrimary : KairosTheme.Colors.textMuted)
                }
                .padding(.vertical, 2)
            }

            Button {
                objective.keyResults.wrappedValue.append(WizardKR(title: ""))
            } label: {
                Label("Add key result", systemImage: "plus")
                    .font(KairosTheme.Typography.caption)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(KairosTheme.Spacing.md)
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: KairosTheme.Radius.md).stroke(KairosTheme.Colors.border, lineWidth: 1))
    }

    // MARK: - Step 4: Review

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                Text("Looks good?")
                    .font(KairosTheme.Typography.displayMedium)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                Text("AI structural assessment. Go back to edit, or commit.")
                    .font(KairosTheme.Typography.body)
                    .foregroundStyle(KairosTheme.Colors.textSecondary)
            }

            if !reviewText.isEmpty {
                Text(reviewText)
                    .font(KairosTheme.Typography.body)
                    .foregroundStyle(KairosTheme.Colors.textSecondary)
                    .italic()
                    .padding(KairosTheme.Spacing.md)
                    .background(KairosTheme.Colors.accentSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
            }

            // Summary of what will be created
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                KairosLabel(text: "Will create for \(String(targetYear))")
                ForEach(domains.filter { $0.enabled }) { domain in
                    let objs = domain.objectives.filter { $0.enabled }
                    let krCount = objs.flatMap { $0.keyResults.filter { $0.enabled } }.count
                    HStack {
                        Text(domain.name)
                            .font(KairosTheme.Typography.caption)
                            .foregroundStyle(KairosTheme.Colors.textSecondary)
                        Spacer()
                        Text("\(objs.count) obj · \(krCount) KRs")
                            .font(KairosTheme.Typography.monoSmall)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                    }
                    .padding(.vertical, 3)
                    .padding(.horizontal, KairosTheme.Spacing.xs)
                }
            }
            .padding(KairosTheme.Spacing.md)
            .background(KairosTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
            .overlay(RoundedRectangle(cornerRadius: KairosTheme.Radius.md).stroke(KairosTheme.Colors.border, lineWidth: 1))
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: KairosTheme.Spacing.md) {
            ProgressView().scaleEffect(0.9)
            Text(loadingMessage)
                .font(KairosTheme.Typography.caption)
                .foregroundStyle(KairosTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(KairosTheme.Spacing.xxl)
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            if step > 0 {
                Button("← Back") { withAnimation { step -= 1 } }
                    .buttonStyle(.plain)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
                    .font(KairosTheme.Typography.body)
            }
            Spacer()
            Button("Cancel") { dismiss() }
                .buttonStyle(.plain)
                .foregroundStyle(KairosTheme.Colors.textMuted)
                .font(KairosTheme.Typography.body)

            let isLast = step == 4
            Button(isLast ? "Set Up \(String(targetYear))" : (step == 0 ? "Generate →" : "Next →")) {
                if isLast { commitAndDismiss() } else { Task { await advance() } }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, KairosTheme.Spacing.md)
            .padding(.vertical, KairosTheme.Spacing.sm)
            .background(isLoading ? KairosTheme.Colors.border : KairosTheme.Colors.accent)
            .foregroundStyle(KairosTheme.Colors.background)
            .font(KairosTheme.Typography.headline)
            .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
            .disabled(isLoading)
        }
        .padding(KairosTheme.Spacing.xl)
    }

    // MARK: - AI Generation

    private func advance() async {
        switch step {
        case 0: await generateDomains()
        case 1: await generateObjectives()
        case 2: await generateKRs()
        case 3: await generateReview()
        default: break
        }
    }

    private func generateDomains() async {
        isLoading = true; loadingMessage = "Proposing domains…"
        defer { isLoading = false }

        let prevSummary: String
        if let prev = previousYear {
            prevSummary = prev.sortedDomains
                .map { "\($0.name): \(Int($0.progress * 100))% (\($0.completedCount)/\($0.allKeyResults.count) KRs done)" }
                .joined(separator: ", ")
        } else {
            prevSummary = "no prior data"
        }

        let prompt = """
        Year plan setup for \(targetYear). Previous year: \(prevSummary).
        Propose 6-7 life domains using Wheel of Life / Maslow.
        For each, one line: [emoji] [Name] | [8-word max note on why this year]
        End with one line: BLINDSPOT: [gap in coverage, 10 words max]
        No other text. No numbering.
        """

        do {
            let text = try await IntelligenceManager.shared.engine.complete(prompt: prompt, context: buildContext())
            parseDomains(from: text)
        } catch {
            setDefaultDomains()
        }
        withAnimation { step = 1 }
    }

    private func generateObjectives() async {
        isLoading = true; loadingMessage = "Proposing objectives…"
        defer { isLoading = false }

        let domainList = domains.filter { $0.enabled }.map { $0.name }.joined(separator: ", ")
        var prevContext = ""
        if let prev = previousYear {
            prevContext = prev.sortedDomains.compactMap { d -> String? in
                let notes = d.allKeyResults
                    .filter { !$0.latestCommentary.isEmpty }
                    .prefix(2).map { $0.latestCommentary }
                guard !notes.isEmpty else { return nil }
                return "\(d.name): \(notes.joined(separator: "; "))"
            }.joined(separator: "\n")
        }

        let prompt = """
        Propose 2 clear objectives for each domain in \(targetYear).
        Domains: \(domainList)\(prevContext.isEmpty ? "" : "\nContext from last year:\n\(prevContext)")
        Output ONLY this exact format with no extra text:
        \(domains.filter { $0.enabled }.map { "\($0.name)\n- Objective one\n- Objective two" }.joined(separator: "\n"))
        Replace the placeholder objectives with real ones. Keep the domain names exactly as given.
        """

        if IntelligenceManager.shared.isUsingAI {
            do {
                let text = try await IntelligenceManager.shared.engine.complete(prompt: prompt, context: buildContext())
                mergeObjectives(from: text)
            } catch {}
        }
        // Fill in fallback for any domains still missing objectives
        for i in domains.indices where domains[i].enabled && domains[i].objectives.isEmpty {
            domains[i].objectives = defaultObjectives(for: domains[i].name)
        }
        withAnimation { step = 2 }
    }

    private func generateKRs() async {
        isLoading = true; loadingMessage = "Proposing key results…"
        defer { isLoading = false }

        let objectiveLines = domains.filter { $0.enabled }
            .flatMap { $0.objectives.filter { $0.enabled } }
            .filter { !$0.title.isEmpty }
            .map { "OBJECTIVE: \($0.title)" }
            .joined(separator: "\n")

        let prompt = """
        Propose 2-3 measurable key results per objective for \(targetYear).
        \(objectiveLines)
        Format exactly:
        OBJECTIVE: [exact title]
        - Specific measurable key result
        - Specific measurable key result
        No explanations. No other text.
        """

        if IntelligenceManager.shared.isUsingAI {
            do {
                let text = try await IntelligenceManager.shared.engine.complete(prompt: prompt, context: buildContext())
                mergeKRs(from: text)
            } catch {}
        }
        // Fill in fallback for any objectives still missing KRs
        for di in domains.indices where domains[di].enabled {
            for oi in domains[di].objectives.indices where domains[di].objectives[oi].enabled {
                if domains[di].objectives[oi].keyResults.isEmpty {
                    domains[di].objectives[oi].keyResults = defaultKRs(for: domains[di].objectives[oi].title)
                }
            }
        }
        withAnimation { step = 3 }
    }

    private func generateReview() async {
        isLoading = true; loadingMessage = "Reviewing your plan…"
        defer { isLoading = false }

        let planText = domains.filter { $0.enabled }.map { d in
            let objs = d.objectives.filter { $0.enabled }.map { obj in
                let krs = obj.keyResults.filter { $0.enabled }.map { "    · \($0.title)" }.joined(separator: "\n")
                return "  — \(obj.title)\n\(krs)"
            }.joined(separator: "\n")
            return "\(d.name):\n\(objs)"
        }.joined(separator: "\n\n")

        let prompt = """
        Review this \(targetYear) life plan:
        \(planText)
        In max 3 sentences: (1) balance vs Maslow/Wheel of Life, (2) one thing to cut or consolidate, (3) one blindspot. Direct. No preamble.
        """

        do {
            let text = try await IntelligenceManager.shared.engine.complete(prompt: prompt, context: buildContext())
            reviewText = text.count < 700 ? text : String(text.prefix(600)) + "…"
        } catch {
            reviewText = "Apple Intelligence isn't active — but your plan looks solid. Review it manually before committing."
        }
        withAnimation { step = 4 }
    }

    // MARK: - Parsing

    private func parseDomains(from text: String) {
        var result: [WizardDomain] = []
        var bs = ""
        var order = 0
        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.lowercased().hasPrefix("blindspot:") {
                bs = String(line.dropFirst("blindspot:".count)).trimmingCharacters(in: .whitespaces)
                continue
            }
            let parts = line.components(separatedBy: " | ")
            let head = parts[0].trimmingCharacters(in: .whitespaces)
            let note = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : ""
            let tokens = head.split(separator: " ", maxSplits: 1)
            guard tokens.count == 2 else { continue }
            let emoji = String(tokens[0])
            let name = String(tokens[1]).trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }
            result.append(WizardDomain(name: name, emoji: emoji, colorHex: defaultHex(name), sortOrder: order, note: note))
            order += 1
        }
        if !result.isEmpty { domains = result } else { setDefaultDomains() }
        blindspot = bs
    }

    private func mergeObjectives(from text: String) {
        var currentDomain = ""
        var map: [String: [String]] = [:]
        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("- ") || line.hasPrefix("• ") {
                guard !currentDomain.isEmpty else { continue }
                let item = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                if !item.isEmpty { map[currentDomain, default: []].append(item) }
            } else {
                // Strip markdown bold/italic/heading characters, colons, numbering
                let cleaned = line
                    .replacingOccurrences(of: "**", with: "")
                    .replacingOccurrences(of: "*", with: "")
                    .replacingOccurrences(of: "##", with: "")
                    .replacingOccurrences(of: "#", with: "")
                    .replacingOccurrences(of: ":", with: "")
                    .replacingOccurrences(of: "__", with: "")
                    .trimmingCharacters(in: .whitespaces)
                    // Strip leading digits like "1." or "1)"
                    .replacingOccurrences(of: "^\\d+[.)\\s]+", with: "", options: .regularExpression)
                if !cleaned.isEmpty { currentDomain = cleaned }
            }
        }
        let domainNames = domains.filter { $0.enabled }.map { $0.name }
        for i in domains.indices where domains[i].enabled {
            let name = domains[i].name
            let nameLower = name.lowercased()
            let key = map.keys.first { $0.caseInsensitiveCompare(name) == .orderedSame }
                ?? map.keys.first { $0.lowercased().contains(nameLower) || nameLower.contains($0.lowercased()) }
            if let k = key, let titles = map[k], !titles.isEmpty {
                domains[i].objectives = titles.map { WizardObjective(title: $0) }
            }
        }
        _ = domainNames // suppress warning
    }

    private func mergeKRs(from text: String) {
        var currentObj = ""
        var map: [String: [String]] = [:]
        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.lowercased().hasPrefix("objective:") {
                currentObj = String(line.dropFirst("objective:".count)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("- ") && !currentObj.isEmpty {
                map[currentObj, default: []].append(String(line.dropFirst(2)))
            }
        }
        for di in domains.indices where domains[di].enabled {
            for oi in domains[di].objectives.indices where domains[di].objectives[oi].enabled {
                let title = domains[di].objectives[oi].title
                let titleLower = title.lowercased()
                // Try exact match first, then fuzzy contains
                let key = map.keys.first { $0.caseInsensitiveCompare(title) == .orderedSame }
                    ?? map.keys.first { $0.lowercased().contains(titleLower) || titleLower.contains($0.lowercased()) }
                if let k = key, let krs = map[k], !krs.isEmpty {
                    domains[di].objectives[oi].keyResults = krs.map { WizardKR(title: $0) }
                }
            }
        }
    }

    // MARK: - Helpers

    private func buildContext() -> IntelligenceContext {
        if let prev = previousYear {
            return IntelligenceManager.shared.buildContext(from: prev, pulses: Array(pulses.prefix(8)))
        }
        return IntelligenceContext(year: targetYear, month: nil, domainSummaries: [], recentPulseNotes: [], healthSnapshot: nil, persona: nil)
    }

    private func setDefaultDomains() {
        let defaults: [(String, String, String)] = [
            ("💚", "Health",        "#4A9A6A"),
            ("💼", "Work",          "#4A7AA8"),
            ("🧘", "Spirit",        "#9A6AAA"),
            ("🏃", "Sport",         "#AA7A4A"),
            ("👶", "Kids",          "#AA9A4A"),
            ("❤️", "Love",          "#AA4A6A"),
            ("🌍", "Externalities", "#6A8AAA"),
        ]
        domains = defaults.enumerated().map { i, d in
            WizardDomain(name: d.1, emoji: d.0, colorHex: d.2, sortOrder: i)
        }
    }

    private func defaultHex(_ name: String) -> String {
        switch name.lowercased() {
        case "health":        return "#4A9A6A"
        case "work":          return "#4A7AA8"
        case "spirit":        return "#9A6AAA"
        case "sport":         return "#AA7A4A"
        case "kids":          return "#AA9A4A"
        case "love":          return "#AA4A6A"
        case "externalities": return "#6A8AAA"
        default:              return "#6A6A8A"
        }
    }

    // MARK: - Fallback defaults

    private func defaultObjectives(for name: String) -> [WizardObjective] {
        switch name.lowercased() {
        case "health":
            return [WizardObjective(title: "Improve fitness and endurance"),
                    WizardObjective(title: "Optimize sleep and recovery")]
        case "work", "career":
            return [WizardObjective(title: "Advance core skills and expertise"),
                    WizardObjective(title: "Deliver key projects with impact")]
        case "spirit", "mindfulness", "mind":
            return [WizardObjective(title: "Deepen a consistent inner practice"),
                    WizardObjective(title: "Create regular space for reflection")]
        case "sport", "fitness", "training":
            return [WizardObjective(title: "Hit a meaningful performance milestone"),
                    WizardObjective(title: "Build consistency in training")]
        case "relationships", "family", "social":
            return [WizardObjective(title: "Strengthen the most important relationships"),
                    WizardObjective(title: "Create shared experiences and memories")]
        case "love", "partnership", "romance":
            return [WizardObjective(title: "Deepen connection and partnership"),
                    WizardObjective(title: "Invest in quality time together")]
        case "finance", "money", "wealth":
            return [WizardObjective(title: "Build financial resilience and buffer"),
                    WizardObjective(title: "Grow income or reduce unnecessary spending")]
        case "learning", "growth", "education":
            return [WizardObjective(title: "Master one high-leverage new skill"),
                    WizardObjective(title: "Build a consistent learning habit")]
        case "kids", "children":
            return [WizardObjective(title: "Be fully present and engaged"),
                    WizardObjective(title: "Create meaningful experiences together")]
        default:
            return [WizardObjective(title: "Define clear goals for \(name)"),
                    WizardObjective(title: "Build habits that move \(name) forward")]
        }
    }

    private func defaultKRs(for objectiveTitle: String) -> [WizardKR] {
        [WizardKR(title: "Edit this key result for: \(objectiveTitle)"),
         WizardKR(title: "Add a second measurable outcome")]
    }

    // MARK: - Commit

    private func commitAndDismiss() {
        let year = KairosYear(year: targetYear, intention: yearIntention)
        modelContext.insert(year)

        for (di, wd) in domains.filter({ $0.enabled }).enumerated() {
            let domain = KairosDomain(name: wd.name, emoji: wd.emoji, identityStatement: "", sortOrder: di, colorHex: wd.colorHex)
            modelContext.insert(domain)
            year.domains.append(domain)

            for (oi, wo) in wd.objectives.filter({ $0.enabled && !$0.title.isEmpty }).enumerated() {
                let obj = KairosObjective(title: wo.title, sortOrder: oi)
                modelContext.insert(obj)
                domain.objectives.append(obj)

                for (ki, wk) in wo.keyResults.filter({ $0.enabled && !$0.title.isEmpty }).enumerated() {
                    let kr = KairosKeyResult(title: wk.title, sortOrder: ki)
                    modelContext.insert(kr)
                    obj.keyResults.append(kr)
                }
            }
        }

        try? modelContext.save()
        dismiss()
    }
}
