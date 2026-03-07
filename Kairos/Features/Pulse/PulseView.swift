import SwiftUI
import SwiftData

struct PulseView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \KairosWeeklyPulse.date, order: .reverse) private var pulses: [KairosWeeklyPulse]

    @State private var isCapturing = false
    @State private var energyLevel: Double = 5
    @State private var selectedTags: Set<PulseTag> = []
    @State private var note = ""

    private var thisWeekPulse: KairosWeeklyPulse? {
        let cal = Calendar.current
        return pulses.first { cal.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xl) {
                headerSection
                if isCapturing {
                    captureCard
                } else {
                    capturePrompt
                }
                if !pulses.isEmpty {
                    historySection
                }
            }
            .padding(KairosTheme.Spacing.xl)
        }
        .background(KairosTheme.Colors.background)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
            KairosLabel(text: "Weekly Pulse")
            Text("90 seconds.\nHow are you, honestly?")
                .font(KairosTheme.Typography.displayMedium)
                .foregroundStyle(KairosTheme.Colors.textPrimary)
        }
    }

    // MARK: - Capture Prompt

    private var capturePrompt: some View {
        VStack(spacing: KairosTheme.Spacing.md) {
            if thisWeekPulse != nil {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(KairosTheme.Colors.status(.done))
                    Text("This week's pulse is in.")
                        .font(KairosTheme.Typography.body)
                        .foregroundStyle(KairosTheme.Colors.textSecondary)
                }
                .padding(KairosTheme.Spacing.md)
                .background(KairosTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
            } else {
                Button {
                    withAnimation { isCapturing = true }
                } label: {
                    HStack {
                        Image(systemName: "waveform.circle.fill")
                            .font(.title2)
                        Text("Capture this week's pulse")
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
        }
    }

    // MARK: - Capture Card

    private var captureCard: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.lg) {
            // Energy slider
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
                HStack {
                    KairosLabel(text: "Energy Level")
                    Spacer()
                    Text(String(Int(energyLevel)))
                        .font(KairosTheme.Typography.monoLarge)
                        .foregroundStyle(energyColor)
                }
                Slider(value: $energyLevel, in: 1...10, step: 1)
                    .tint(energyColor)
            }

            KairosDivider()

            // Tag selection
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
                KairosLabel(text: "What's driving it?")
                HStack(spacing: KairosTheme.Spacing.sm) {
                    ForEach(PulseTag.allCases, id: \.self) { tag in
                        TagToggle(tag: tag, isSelected: selectedTags.contains(tag)) {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        }
                    }
                }
            }

            KairosDivider()

            // Voice placeholder + text note
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
                HStack {
                    KairosLabel(text: "One sentence (optional)")
                    Spacer()
                    // Voice record button (placeholder — AVAudioRecorder integration in next iteration)
                    Button {
                        // TODO: AVAudioRecorder
                    } label: {
                        Label("Voice", systemImage: "mic.circle")
                            .font(KairosTheme.Typography.caption)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                    }
                    .buttonStyle(.plain)
                }
                TextField("What's on your mind?", text: $note, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(KairosTheme.Typography.body)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                    .lineLimit(3)
                    .padding(KairosTheme.Spacing.sm)
                    .background(KairosTheme.Colors.background)
                    .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
            }

            KairosDivider()

            // Actions
            HStack {
                Button("Cancel") {
                    withAnimation { isCapturing = false; reset() }
                }
                .buttonStyle(.plain)
                .foregroundStyle(KairosTheme.Colors.textMuted)

                Spacer()

                Button("Save Pulse") {
                    savePulse()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, KairosTheme.Spacing.md)
                .padding(.vertical, KairosTheme.Spacing.sm)
                .background(KairosTheme.Colors.accent)
                .foregroundStyle(KairosTheme.Colors.background)
                .font(KairosTheme.Typography.headline)
                .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
            }
        }
        .padding(KairosTheme.Spacing.lg)
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
                .stroke(KairosTheme.Colors.accent.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.md) {
            KairosLabel(text: "Recent Pulses")

            // Energy sparkline
            energySparkline

            // List
            VStack(spacing: KairosTheme.Spacing.sm) {
                ForEach(pulses.prefix(8)) { pulse in
                    PulseHistoryRow(pulse: pulse)
                }
            }
        }
    }

    private var energySparkline: some View {
        let recent = pulses.prefix(12).reversed().map { $0.energyLevel }
        return HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(recent.enumerated()), id: \.offset) { _, level in
                let h = CGFloat(max(level, 1)) / 10.0 * 40
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 2)
                        .fill(energyBarColor(level))
                        .frame(width: 16, height: h)
                }
                .frame(height: 40)
            }
        }
        .padding(KairosTheme.Spacing.md)
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
    }

    // MARK: - Helpers

    private var energyColor: Color {
        let level = Int(energyLevel)
        if level <= 3 { return KairosTheme.Colors.status(.blocked) }
        if level <= 6 { return KairosTheme.Colors.status(.inProgress) }
        return KairosTheme.Colors.status(.done)
    }

    private func energyBarColor(_ level: Int) -> Color {
        if level <= 3 { return KairosTheme.Colors.status(.blocked) }
        if level <= 6 { return KairosTheme.Colors.status(.inProgress) }
        return KairosTheme.Colors.status(.done)
    }

    private func savePulse() {
        let pulse = KairosWeeklyPulse(date: Date())
        pulse.energyLevel = Int(energyLevel)
        pulse.tags = Array(selectedTags)
        pulse.note = note
        context.insert(pulse)
        try? context.save()
        withAnimation { isCapturing = false; reset() }
    }

    private func reset() {
        energyLevel = 5
        selectedTags = []
        note = ""
    }
}

// MARK: - TagToggle

struct TagToggle: View {
    let tag: PulseTag
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(tag.rawValue)
                .font(KairosTheme.Typography.caption)
                .foregroundStyle(isSelected ? KairosTheme.Colors.background : KairosTheme.Colors.textSecondary)
                .padding(.horizontal, KairosTheme.Spacing.sm)
                .padding(.vertical, KairosTheme.Spacing.xs)
                .background(isSelected ? KairosTheme.Colors.accent : KairosTheme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PulseHistoryRow

struct PulseHistoryRow: View {
    let pulse: KairosWeeklyPulse

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        HStack(spacing: KairosTheme.Spacing.md) {
            Text(String(pulse.energyLevel > 0 ? pulse.energyLevel : 0))
                .font(KairosTheme.Typography.monoLarge)
                .foregroundStyle(energyColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(Self.formatter.string(from: pulse.date))
                    .font(KairosTheme.Typography.caption)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
                if !pulse.note.isEmpty {
                    Text(pulse.note)
                        .font(KairosTheme.Typography.body)
                        .foregroundStyle(KairosTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                if !pulse.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(pulse.tags, id: \.self) { tag in
                            Text(tag.rawValue)
                                .font(KairosTheme.Typography.monoSmall)
                                .foregroundStyle(KairosTheme.Colors.textMuted)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(KairosTheme.Colors.surfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(KairosTheme.Spacing.sm)
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
    }

    private var energyColor: Color {
        let l = pulse.energyLevel
        if l <= 3 { return KairosTheme.Colors.status(.blocked) }
        if l <= 6 { return KairosTheme.Colors.status(.inProgress) }
        return KairosTheme.Colors.status(.done)
    }
}
