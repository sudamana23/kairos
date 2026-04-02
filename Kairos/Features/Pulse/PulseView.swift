import SwiftUI
import SwiftData

struct PulseView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \KairosWeeklyPulse.date, order: .reverse) private var pulses: [KairosWeeklyPulse]
    private var syncMonitor: CloudKitSyncMonitor = .shared

    @State private var isCapturing = false
    @State private var energyLevel: Double = 5
    @State private var selectedTags: Set<PulseTag> = []
    @State private var note = ""
    @State private var recorder = VoiceRecorder()

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
        // Re-render when CloudKit delivers remote changes (e.g. deletions from another device)
        .id(syncMonitor.remoteChangeToken)
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

            // Voice + text note
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
                HStack {
                    KairosLabel(text: recorder.state == .recording ? "Listening…" : "One sentence (optional)")
                    Spacer()
                    if recorder.state == .recording { waveform }
                    Button {
                        if recorder.state == .idle {
                            note = ""
                        }
                        recorder.toggle()
                    } label: {
                        Image(systemName: recorder.state == .recording ? "stop.circle.fill" : "mic.circle")
                            .font(.title3)
                            .foregroundStyle(recorder.state == .recording
                                ? KairosTheme.Colors.status(.blocked)
                                : KairosTheme.Colors.accent)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.plain)
                }
                if let err = recorder.permissionError {
                    Text(err)
                        .font(KairosTheme.Typography.caption)
                        .foregroundStyle(KairosTheme.Colors.status(.blocked))
                }
                TextField("What's on your mind?", text: noteBinding, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(KairosTheme.Typography.body)
                    .foregroundStyle(recorder.state == .recording
                        ? KairosTheme.Colors.textSecondary
                        : KairosTheme.Colors.textPrimary)
                    .lineLimit(3...)
                    .padding(KairosTheme.Spacing.sm)
                    .background(KairosTheme.Colors.background)
                    .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
                    .onChange(of: recorder.state) { _, newState in
                        if newState == .idle && !recorder.transcript.isEmpty {
                            note = recorder.transcript
                        }
                    }
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
                    PulseHistoryRow(pulse: pulse) {
                        context.delete(pulse)
                        try? context.save()
                    }
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

    // MARK: - Voice Helpers

    private var noteBinding: Binding<String> {
        Binding(
            get: { recorder.state == .recording ? recorder.transcript : note },
            set: { if recorder.state == .idle { note = $0 } }
        )
    }

    private var waveform: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { i in
                let offset = Float(i % 3) * 0.4
                let h = CGFloat(max(4, (recorder.audioLevel + offset * recorder.audioLevel) * 22))
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(KairosTheme.Colors.status(.blocked))
                    .frame(width: 3, height: h)
                    .animation(.easeInOut(duration: 0.12), value: recorder.audioLevel)
            }
        }
        .frame(height: 22)
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
        pulse.transcription = recorder.transcript
        context.insert(pulse)
        try? context.save()
        // Cancel Wednesday nudge — pulse logged for this week
        NotificationManager.shared.pulseLogged()
        withAnimation { isCapturing = false; reset() }
    }

    private func reset() {
        energyLevel = 5
        selectedTags = []
        note = ""
        recorder.reset()
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
    var onDelete: (() -> Void)? = nil
    @State private var isExpanded = false

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private var hasExpandableContent: Bool {
        !pulse.note.isEmpty || !pulse.transcription.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Collapsed row
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
                            .lineLimit(isExpanded ? nil : 1)
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
                // Inline trash — always visible
                if let onDelete {
                    Button { onDelete() } label: {
                        Image(systemName: "trash")
                            .font(.caption2)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                            .touchTarget()
                    }
                    .buttonStyle(.plain)
                    .help("Delete pulse")
                }
                if hasExpandableContent {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if hasExpandableContent {
                    withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() }
                }
            }

            // Expanded: full transcription if different from note
            if isExpanded && !pulse.transcription.isEmpty && pulse.transcription != pulse.note {
                KairosDivider()
                    .padding(.vertical, KairosTheme.Spacing.xs)
                VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                    KairosLabel(text: "Voice transcription")
                    Text(pulse.transcription)
                        .font(KairosTheme.Typography.body)
                        .foregroundStyle(KairosTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(KairosTheme.Spacing.sm)
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
        .animation(.easeInOut(duration: 0.15), value: isExpanded)
        .contextMenu {
            if let onDelete {
                Button(role: .destructive) { onDelete() } label: {
                    Label("Delete Pulse", systemImage: "trash")
                }
            }
        }
    }

    private var energyColor: Color {
        let l = pulse.energyLevel
        if l <= 3 { return KairosTheme.Colors.status(.blocked) }
        if l <= 6 { return KairosTheme.Colors.status(.inProgress) }
        return KairosTheme.Colors.status(.done)
    }
}
