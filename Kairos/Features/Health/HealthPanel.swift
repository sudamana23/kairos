import SwiftUI
#if os(iOS)
import HealthKit
#endif

// MARK: - HealthPanel
// Shows physiological snapshot.
// iOS: reads live from HealthKit.
// macOS: displays snapshot synced from an iOS device via CloudKit.

struct HealthPanel: View {
    /// Snapshot stored on the current KairosYear and synced via CloudKit.
    /// Populated by an iOS device running HealthKit.
    var storedSnapshot: HealthSnapshot? = nil
    var storedSnapshotDate: Date = Date.distantPast

    @ObservedObject private var hk = HealthKitManager.shared

    private var activeSnapshot: HealthSnapshot? {
        #if os(macOS)
        return storedSnapshot
        #else
        return hk.snapshot
        #endif
    }

    private var panelTitle: String {
        #if os(macOS)
        return "Health · 30-Day Signal"
        #else
        return "Apple Health · 30-Day Signal"
        #endif
    }

    var body: some View {
        #if os(macOS)
        if activeSnapshot == nil {
            macPendingSyncStrip
        } else {
            fullPanel
        }
        #else
        fullPanel
        #endif
    }

    // Compact one-line strip shown on Mac when no snapshot has synced yet.
    #if os(macOS)
    private var macPendingSyncStrip: some View {
        HStack(spacing: KairosTheme.Spacing.sm) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.caption)
                .foregroundStyle(KairosTheme.Colors.textMuted)
            Text("Pending sync from an Apple Health enabled device.")
                .font(KairosTheme.Typography.caption)
                .foregroundStyle(KairosTheme.Colors.textMuted)
            Spacer()
        }
        .padding(.horizontal, KairosTheme.Spacing.md)
        .padding(.vertical, KairosTheme.Spacing.sm)
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
                .stroke(KairosTheme.Colors.border, lineWidth: 1)
        )
    }
    #endif

    private var fullPanel: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.md) {
            header

            if let snap = activeSnapshot {
                metricsGrid(snap)
            } else if hk.isAuthorized && hk.snapshot == nil {
                loadingView
            } else {
                connectionView
            }
        }
        .padding(KairosTheme.Spacing.md)
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
                .stroke(KairosTheme.Colors.border, lineWidth: 1)
        )
        .task {
            #if os(iOS)
            if hk.isAuthorized && hk.snapshot == nil {
                await hk.fetchCurrentSnapshot()
            }
            #endif
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                KairosLabel(text: panelTitle)
                #if os(macOS)
                if storedSnapshotDate > Date.distantPast {
                    Text("Synced \(relativeDate(storedSnapshotDate))")
                        .font(KairosTheme.Typography.monoSmall)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                }
                #endif
            }
            Spacer()
            if let snap = activeSnapshot {
                recoveryBadge(snap.recoverySignal)
            }
            #if os(iOS)
            if hk.isAuthorized {
                Button {
                    Task { await hk.fetchCurrentSnapshot() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                }
                .buttonStyle(.plain)
            }
            #endif
        }
    }

    private func recoveryBadge(_ signal: RecoverySignal) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(hex: signal.color))
                .frame(width: 6, height: 6)
            Text(signal.rawValue)
                .font(KairosTheme.Typography.monoSmall)
                .foregroundStyle(Color(hex: signal.color))
        }
        .padding(.horizontal, KairosTheme.Spacing.sm)
        .padding(.vertical, 3)
        .background(Color(hex: signal.color).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
    }

    // MARK: - Connection view

    private var connectionView: some View {
        #if os(macOS)
        Text("Health data syncs automatically from an iPhone or iPad running FourOneEight. Open the app on your iOS device and connect Apple Health.")
            .font(KairosTheme.Typography.caption)
            .foregroundStyle(KairosTheme.Colors.textMuted)
            .multilineTextAlignment(.leading)
        #else
        healthKitConnectRow
        #endif
    }

    // MARK: - HealthKit connect row (iOS only)

    #if os(iOS)
    private var healthKitConnectRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Connect Apple Health")
                    .font(KairosTheme.Typography.headline)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                Text("HRV, sleep, steps, and activity.")
                    .font(KairosTheme.Typography.caption)
                    .foregroundStyle(KairosTheme.Colors.textSecondary)
            }
            Spacer()
            Button {
                Task { await hk.requestAuthorization() }
            } label: {
                Text("Connect")
                    .font(KairosTheme.Typography.caption)
                    .foregroundStyle(KairosTheme.Colors.background)
                    .padding(.horizontal, KairosTheme.Spacing.md)
                    .padding(.vertical, KairosTheme.Spacing.xs)
                    .background(KairosTheme.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
            }
            .buttonStyle(.plain)
        }
    }
    #endif

    // MARK: - States

    private var loadingView: some View {
        HStack {
            ProgressView().scaleEffect(0.7)
            Text("Loading health data…")
                .font(KairosTheme.Typography.caption)
                .foregroundStyle(KairosTheme.Colors.textMuted)
        }
    }

    // MARK: - Metrics Grid

    private func metricsGrid(_ snap: HealthSnapshot) -> some View {
        VStack(spacing: KairosTheme.Spacing.sm) {
            // Row 1: Recovery
            HStack(spacing: KairosTheme.Spacing.sm) {
                MetricTile(
                    label: "HRV",
                    value: snap.avgHRV.map { "\(Int($0))" } ?? "—",
                    unit: "ms",
                    trend: nil,
                    highlight: hrvHighlight(snap.avgHRV)
                )
                MetricTile(
                    label: "Resting HR",
                    value: snap.avgRHR.map { "\(Int($0))" } ?? "—",
                    unit: "bpm",
                    trend: nil,
                    highlight: .neutral
                )
                MetricTile(
                    label: snap.readinessScore != nil ? "Readiness" : "Resp Rate",
                    value: snap.readinessScore.map { "\($0)" }
                        ?? snap.avgRespiratoryRate.map { String(format: "%.1f", $0) }
                        ?? "—",
                    unit: snap.readinessScore != nil ? "/100" : "br/min",
                    trend: nil,
                    highlight: readinessHighlight(snap.readinessScore)
                )
            }

            // Row 2: Sleep
            HStack(spacing: KairosTheme.Spacing.sm) {
                MetricTile(
                    label: "Sleep Avg",
                    value: snap.avgSleepHours.map { formatHours($0) } ?? "—",
                    unit: "30-day",
                    trend: nil,
                    highlight: sleepHighlight(snap.avgSleepHours)
                )
                MetricTile(
                    label: "Deep",
                    value: snap.lastSleepDeepHours.map { formatHours($0) } ?? "—",
                    unit: "last night",
                    trend: nil,
                    highlight: .neutral
                )
                MetricTile(
                    label: "REM",
                    value: snap.lastSleepREMHours.map { formatHours($0) } ?? "—",
                    unit: "last night",
                    trend: nil,
                    highlight: .neutral
                )
            }

            // Row 3: Activity + Fitness
            HStack(spacing: KairosTheme.Spacing.sm) {
                MetricTile(
                    label: "Steps",
                    value: snap.avgDailySteps.map { "\(Int($0 / 1000))k" } ?? "—",
                    unit: "avg/day",
                    trend: nil,
                    highlight: stepsHighlight(snap.avgDailySteps)
                )
                MetricTile(
                    label: "Active kcal",
                    value: snap.avgActiveEnergy.map { "\(Int($0))" } ?? "—",
                    unit: "avg/day",
                    trend: nil,
                    highlight: .neutral
                )
                MetricTile(
                    label: "VO₂ Max",
                    value: snap.vo2Max.map { String(format: "%.1f", $0) } ?? "—",
                    unit: "ml/kg/min",
                    trend: nil,
                    highlight: vo2Highlight(snap.vo2Max)
                )
            }

            // Sleep quality bar
            if let avg = snap.avgSleepHours {
                sleepBar(avg)
            }
        }
    }

    // MARK: - Sleep visual bar

    private func sleepBar(_ avgHours: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                KairosLabel(text: "Sleep Quality")
                Spacer()
                Text(snap7DaySleepLabel(avgHours))
                    .font(KairosTheme.Typography.monoSmall)
                    .foregroundStyle(Color(hex: sleepHighlight(avgHours) == .good ? "#4A9A6A" : avgHours >= 6.5 ? "#AA9A4A" : "#9A4A4A"))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(KairosTheme.Colors.border).frame(height: 4)
                    let targetStart = min(7.0 / 10.0, 1.0)
                    let targetEnd   = min(9.0 / 10.0, 1.0)
                    RoundedRectangle(cornerRadius: 0)
                        .fill(KairosTheme.Colors.status(.done).opacity(0.15))
                        .frame(width: (targetEnd - targetStart) * geo.size.width, height: 4)
                        .offset(x: targetStart * geo.size.width)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: sleepHighlight(avgHours) == .good ? "#4A9A6A" : avgHours >= 6.5 ? "#AA9A4A" : "#9A4A4A"))
                        .frame(width: min(avgHours / 10.0, 1.0) * geo.size.width, height: 4)
                }
            }
            .frame(height: 4)
            HStack {
                Text("0h")
                    .font(KairosTheme.Typography.monoSmall)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
                Spacer()
                Text("7h optimal")
                    .font(KairosTheme.Typography.monoSmall)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
                Spacer()
                Text("10h")
                    .font(KairosTheme.Typography.monoSmall)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
            }
        }
    }

    // MARK: - Highlight logic

    enum Highlight { case good, warning, alert, neutral }

    private func readinessHighlight(_ score: Int?) -> Highlight {
        guard let v = score else { return .neutral }
        if v >= 70 { return .good }
        if v >= 50 { return .warning }
        return .alert
    }

    private func hrvHighlight(_ hrv: Double?) -> Highlight {
        guard let v = hrv else { return .neutral }
        if v >= 50 { return .good }
        if v >= 30 { return .warning }
        return .alert
    }

    private func sleepHighlight(_ hours: Double?) -> Highlight {
        guard let v = hours else { return .neutral }
        if v >= 7.5 { return .good }
        if v >= 6.5 { return .warning }
        return .alert
    }

    private func stepsHighlight(_ steps: Double?) -> Highlight {
        guard let v = steps else { return .neutral }
        if v >= 8000 { return .good }
        if v >= 5000 { return .warning }
        return .alert
    }

    private func vo2Highlight(_ vo2: Double?) -> Highlight {
        guard let v = vo2 else { return .neutral }
        if v >= 42 { return .good }
        if v >= 35 { return .warning }
        return .alert
    }

    private func formatHours(_ h: Double) -> String {
        let hrs  = Int(h)
        let mins = Int((h - Double(hrs)) * 60)
        return mins > 0 ? "\(hrs)h \(mins)m" : "\(hrs)h"
    }

    private func snap7DaySleepLabel(_ avg: Double) -> String {
        if avg >= 7.5 { return "Optimal" }
        if avg >= 6.5 { return "Adequate" }
        return "Insufficient"
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - MetricTile

struct MetricTile: View {
    let label:     String
    let value:     String
    let unit:      String
    let trend:     Double?
    let highlight: HealthPanel.Highlight

    private var valueColor: Color {
        switch highlight {
        case .good:    return KairosTheme.Colors.status(.done)
        case .warning: return KairosTheme.Colors.status(.paused)
        case .alert:   return KairosTheme.Colors.status(.blocked)
        case .neutral: return KairosTheme.Colors.textPrimary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            KairosLabel(text: label)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(KairosTheme.Typography.monoLarge)
                    .foregroundStyle(valueColor)
                Text(unit)
                    .font(KairosTheme.Typography.monoSmall)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
            }
            if let trend {
                HStack(spacing: 2) {
                    Image(systemName: trend >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 8))
                    Text(String(format: "%.0f%%", abs(trend)))
                        .font(KairosTheme.Typography.monoSmall)
                }
                .foregroundStyle(trend >= 0 ? KairosTheme.Colors.status(.done) : KairosTheme.Colors.status(.blocked))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(KairosTheme.Spacing.sm)
        .background(KairosTheme.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
    }
}
