import SwiftUI
import SwiftData
#if canImport(FoundationModels)
import FoundationModels
#endif

struct ValuesDiscoveryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \KairosValue.sortOrder) private var existingValues: [KairosValue]

    // Discovery state machine
    enum Step { case q1, q2, q3, thinking, review, done }
    @State private var step: Step = .q1
    @State private var answer1 = ""
    @State private var answer2 = ""
    @State private var answer3 = ""
    @State private var suggestions: [ValueSuggestion] = []
    @State private var errorMessage: String?

    struct ValueSuggestion: Identifiable {
        let id = UUID()
        var name: String
        var reflection: String
        var emoji: String
        var colorHex: String
        var include: Bool = true
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Discover Your Values")
                    .font(KairosTheme.Typography.monoLarge)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
            }
            .padding(KairosTheme.Spacing.xl)

            KairosDivider()

            switch step {
            case .q1: questionView(number: 1, total: 3,
                question: "What do you want your life to stand for?",
                hint: "Think about what you'd want said at your eulogy, or what you'd regret not having prioritised.",
                binding: $answer1,
                onNext: { step = .q2 })
            case .q2: questionView(number: 2, total: 3,
                question: "What would you regret not having made time for?",
                hint: "Think about relationships, experiences, work, or ways of being.",
                binding: $answer2,
                onNext: { step = .q3 })
            case .q3: questionView(number: 3, total: 3,
                question: "Name someone you deeply admire. What quality of theirs do you most want to embody?",
                hint: "This can be someone you know personally, historically, or from fiction.",
                binding: $answer3,
                onNext: { Task { await generateSuggestions() } })
            case .thinking: thinkingView
            case .review: reviewView
            case .done: doneView
            }
        }
        .background(KairosTheme.Colors.background)
        .frame(minWidth: 540, minHeight: 460)
    }

    // MARK: - Question view

    private func questionView(number: Int, total: Int, question: String, hint: String, binding: Binding<String>, onNext: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.lg) {
            // Progress
            HStack(spacing: 6) {
                ForEach(1...total, id: \.self) { i in
                    Capsule()
                        .fill(i <= number ? KairosTheme.Colors.accent : KairosTheme.Colors.border)
                        .frame(width: 24, height: 3)
                }
            }

            Text(question)
                .font(KairosTheme.Typography.monoLarge)
                .foregroundStyle(KairosTheme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(hint)
                .font(KairosTheme.Typography.body)
                .foregroundStyle(KairosTheme.Colors.textMuted)

            TextEditor(text: binding)
                .font(KairosTheme.Typography.body)
                .foregroundStyle(KairosTheme.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .background(KairosTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
                .frame(minHeight: 120, maxHeight: 200)

            HStack {
                // Allow skipping to manual entry at any point
                Button("Enter manually") {
                    suggestions = [
                        ValueSuggestion(name: "", reflection: "", emoji: "", colorHex: "#4A9A6A"),
                        ValueSuggestion(name: "", reflection: "", emoji: "", colorHex: "#5A7AB5"),
                        ValueSuggestion(name: "", reflection: "", emoji: "", colorHex: "#A0522D"),
                    ]
                    step = .review
                }
                .buttonStyle(.plain)
                .foregroundStyle(KairosTheme.Colors.textMuted)
                .font(KairosTheme.Typography.caption)

                Spacer()
                Button(number == total ? "Find my values →" : "Next →") {
                    onNext()
                }
                .buttonStyle(.plain)
                .foregroundStyle(KairosTheme.Colors.accent)
            }
        }
        .padding(KairosTheme.Spacing.xl)
    }

    // MARK: - Thinking

    private var thinkingView: some View {
        VStack(spacing: KairosTheme.Spacing.lg) {
            Spacer()
            ProgressView()
                .controlSize(.large)
            Text("Reflecting on your answers…")
                .font(KairosTheme.Typography.body)
                .foregroundStyle(KairosTheme.Colors.textMuted)
            if let err = errorMessage {
                Text(err)
                    .font(KairosTheme.Typography.monoSmall)
                    .foregroundStyle(KairosTheme.Colors.status(.blocked))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button("Try again") { Task { await generateSuggestions() } }
                    .buttonStyle(.plain)
                    .foregroundStyle(KairosTheme.Colors.accent)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(KairosTheme.Spacing.xl)
    }

    // MARK: - Review suggested values

    private var reviewView: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Values")
                    .font(KairosTheme.Typography.monoLarge)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                Text("Edit, remove, or accept these. Aim for 3–5 that feel deeply true.")
                    .font(KairosTheme.Typography.body)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
            }
            .padding(.horizontal, KairosTheme.Spacing.xl)
            .padding(.top, KairosTheme.Spacing.lg)

            ScrollView {
                VStack(spacing: KairosTheme.Spacing.sm) {
                    ForEach($suggestions) { $s in
                        HStack(spacing: KairosTheme.Spacing.md) {
                            Toggle("", isOn: $s.include)
                                .labelsHidden()
                                .toggleStyle(.checkbox)

                            // Colour swatch (pick from fixed palette)
                            let swatchColors = ["#4A9A6A","#5A7AB5","#A0522D","#8B6B8B","#B8860B","#2E86AB","#C0392B","#7D3C98","#1A6B4A","#D4AC0D"]
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: s.colorHex.isEmpty ? "#4A9A6A" : s.colorHex))
                                .frame(width: 6)
                                .frame(minHeight: 44)

                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Value name", text: $s.name)
                                    .font(KairosTheme.Typography.monoLarge)
                                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                                TextField("Why this matters to you", text: $s.reflection)
                                    .font(KairosTheme.Typography.monoSmall)
                                    .foregroundStyle(KairosTheme.Colors.textMuted)
                            }
                            Spacer()
                        }
                        .padding(KairosTheme.Spacing.md)
                        .background(KairosTheme.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
                        .overlay(RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
                            .stroke(s.include ? KairosTheme.Colors.accent.opacity(0.4) : KairosTheme.Colors.border, lineWidth: 1))
                        .opacity(s.include ? 1 : 0.4)
                    }
                }
                .padding(.horizontal, KairosTheme.Spacing.xl)
            }

            HStack {
                Button("← Redo") { step = .q1; suggestions = []; errorMessage = nil }
                    .buttonStyle(.plain)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
                Spacer()
                let count = suggestions.filter(\.include).count
                Text("\(count) value\(count == 1 ? "" : "s") selected")
                    .font(KairosTheme.Typography.monoSmall)
                    .foregroundStyle(count >= 3 && count <= 5 ? KairosTheme.Colors.accent : KairosTheme.Colors.status(.blocked))
                Spacer()
                Button("Save Values") { saveValues() }
                    .buttonStyle(.plain)
                    .foregroundStyle(suggestions.filter(\.include).isEmpty ? KairosTheme.Colors.textMuted : KairosTheme.Colors.accent)
                    .disabled(suggestions.filter(\.include).isEmpty)
            }
            .padding(KairosTheme.Spacing.xl)
        }
    }

    private var doneView: some View {
        VStack(spacing: KairosTheme.Spacing.lg) {
            Spacer()
            Text("✦")
                .font(.system(size: 48))
            Text("Values saved.")
                .font(KairosTheme.Typography.monoLarge)
                .foregroundStyle(KairosTheme.Colors.textPrimary)
            Text("Now assign your domains to the values they serve.")
                .font(KairosTheme.Typography.body)
                .foregroundStyle(KairosTheme.Colors.textMuted)
            Button("Done") { dismiss() }
                .buttonStyle(.plain)
                .foregroundStyle(KairosTheme.Colors.accent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - AI generation

    private func generateSuggestions() async {
        step = .thinking
        errorMessage = nil

        let prompt = """
        Based on these three personal reflections, suggest exactly 3 to 5 core life values.

        Reflection 1 — What they want their life to stand for:
        \(answer1.isEmpty ? "(not answered)" : answer1)

        Reflection 2 — What they'd regret not making time for:
        \(answer2.isEmpty ? "(not answered)" : answer2)

        Reflection 3 — A person they admire and the quality they want to embody:
        \(answer3.isEmpty ? "(not answered)" : answer3)

        Rules:
        - Suggest 3–5 values only. Fewer is better than more.
        - Each value name: 1–2 words, evocative, not generic (avoid "Balance", "Success", "Health" as standalone names)
        - Each reflection: one honest sentence about why this value matters to THIS person based on their answers
        - Format each value on its own line as: Name | Reflection sentence
        - Output only the values list, nothing else, no numbering, no emoji
        """

        #if canImport(FoundationModels)
        if #available(macOS 26, *) {
            do {
                let session = LanguageModelSession()
                let response = try await session.respond(to: prompt)
                let parsed = parseValueLines(response.content)
                if parsed.isEmpty {
                    errorMessage = "Couldn't parse the response. Try again."
                } else {
                    suggestions = parsed
                    step = .review
                }
                return
            } catch {
                errorMessage = "Apple Intelligence error: \(error.localizedDescription)"
                // fall through to stub
            }
        }
        #endif

        // Stub fallback
        try? await Task.sleep(for: .seconds(1))
        suggestions = stubSuggestions()
        step = .review
    }

    private func parseValueLines(_ text: String) -> [ValueSuggestion] {
        let lines = text.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let colors = ["#4A9A6A", "#5A7AB5", "#A0522D", "#8B6B8B", "#B8860B"]
        return lines.enumerated().compactMap { (i, line) in
            let parts = line.components(separatedBy: " | ")
            guard parts.count >= 2 else { return nil }
            let name = parts[0].trimmingCharacters(in: .whitespaces)
            let reflection = parts[1].trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { return nil }
            return ValueSuggestion(name: name, reflection: reflection, emoji: "", colorHex: colors[i % colors.count])
        }
    }

    private func stubSuggestions() -> [ValueSuggestion] {
        [
            ValueSuggestion(name: "Presence", reflection: "Being fully here — with people, with work, with yourself.", emoji: "", colorHex: "#4A9A6A"),
            ValueSuggestion(name: "Growth", reflection: "Staying curious and becoming more capable over time.", emoji: "", colorHex: "#5A7AB5"),
            ValueSuggestion(name: "Integrity", reflection: "Acting in line with what you believe, even when no one is watching.", emoji: "", colorHex: "#8B6B8B")
        ]
    }

    private func saveValues() {
        let toSave = suggestions.filter(\.include)
        let startOrder = existingValues.count
        for (i, s) in toSave.enumerated() {
            let v = KairosValue(name: s.name, reflection: s.reflection, emoji: s.emoji, colorHex: s.colorHex, sortOrder: startOrder + i)
            modelContext.insert(v)
        }
        try? modelContext.save()
        step = .done
    }
}
