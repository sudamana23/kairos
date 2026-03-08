import SwiftUI
import HealthKit

// MARK: - HealthPanel
// Shows 7-day physiological snapshot.
// Data priority: Oura API → Apple Health (HealthKit).

struct HealthPanel: View {
    @ObservedObject private var oura = OuraManager.shared
    @ObservedObject private var hk   = HealthKitManager.shared

    // Setup form state
    @State private var clientIdDraft     = ""
    @State private var clientSecretDraft = ""
    enum CredentialField { case clientId, clientSecret }
    @FocusState private var setupFocus: CredentialField?

    // macOS: prefer Oura, fall back to HealthKit
    // iOS/iPadOS: HealthKit only
    private var activeSnapshot: HealthSnapshot? {
        #if os(macOS)
        return oura.snapshot ?? hk.snapshot
        #else
        return hk.snapshot
        #endif
    }
    private var panelTitle: String {
        #if os(macOS)
        return oura.snapshot != nil ? "Oura · 30-Day Signal" : "Body · 30-Day Signal"
        #else
        return "Apple Health · 30-Day Signal"
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.md) {
            header

            if let snap = activeSnapshot {
                metricsGrid(snap)
            } else if oura.isAuthorized && oura.isFetching {
                loadingView
            } else if oura.isAuthorized, let err = oura.fetchError {
                errorView(err)
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
            #if os(macOS)
            if oura.isAuthorized && oura.snapshot == nil {
                await oura.fetchCurrentSnapshot()
            } else if hk.isAuthorized && hk.snapshot == nil {
                await hk.fetchCurrentSnapshot()
            }
            #else
            if hk.isAuthorized && hk.snapshot == nil {
                await hk.fetchCurrentSnapshot()
            }
            #endif
        }
        .onAppear {
            // Pre-fill if credentials already saved (in case of re-auth after token expiry)
            clientIdDraft = ""
            clientSecretDraft = ""
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            KairosLabel(text: panelTitle)
            Spacer()
            if let snap = activeSnapshot {
                recoveryBadge(snap.recoverySignal)
            }
            if oura.isAuthorized || hk.isAuthorized {
                Button {
                    Task {
                        if oura.isAuthorized { await oura.fetchCurrentSnapshot() }
                        else { await hk.fetchCurrentSnapshot() }
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                }
                .buttonStyle(.plain)
            }
            #if os(macOS)
            if oura.isAuthorized {
                Button { oura.disconnectTokens() } label: {
                    Image(systemName: "xmark.circle")
                        .font(.caption)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                }
                .buttonStyle(.plain)
                .help("Disconnect — keeps credentials, just re-authorize")
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
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
            #if os(macOS)
            // macOS: Oura first, HealthKit as secondary fallback
            if !oura.isConfigured {
                credentialSetupView
            } else {
                authorizeView
            }
            if hk.isAvailable && !hk.isAuthorized {
                KairosDivider()
                healthKitConnectRow
            }
            #else
            // iPad: HealthKit is the primary (and only) source
            healthKitConnectRow
            #endif
        }
    }

    // MARK: - Oura setup views (macOS only)

    #if os(macOS)

    private var credentialSetupView: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Connect Oura Ring")
                        .font(KairosTheme.Typography.headline)
                        .foregroundStyle(KairosTheme.Colors.textPrimary)
                    Text("OAuth via your registered app — sleep, HRV, steps, recovery.")
                        .font(KairosTheme.Typography.caption)
                        .foregroundStyle(KairosTheme.Colors.textSecondary)
                }
            }

            // Instructions
            VStack(alignment: .leading, spacing: 4) {
                instructionRow(n: "1", text: "Register at cloud.ouraring.com → OAuth Applications")
                HStack(spacing: 4) {
                    instructionRow(n: "2", text: "Set redirect URI:")
                    Text(OuraManager.redirectURI)
                        .font(KairosTheme.Typography.mono)
                        .foregroundStyle(KairosTheme.Colors.accent)
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(OuraManager.redirectURI, forType: .string)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10))
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                    }
                    .buttonStyle(.plain)
                    .help("Copy redirect URI")
                }
                instructionRow(n: "3", text: "Paste your Client ID and Secret below")
            }
            .padding(KairosTheme.Spacing.sm)
            .background(KairosTheme.Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))

            // Credential fields
            VStack(spacing: KairosTheme.Spacing.xs) {
                credentialField(label: "Client ID", text: $clientIdDraft, field: .clientId)
                credentialField(label: "Client Secret", text: $clientSecretDraft, field: .clientSecret)
            }

            HStack {
                Spacer()
                Button("Continue →") {
                    oura.saveCredentials(clientId: clientIdDraft, clientSecret: clientSecretDraft)
                    clientIdDraft = ""
                    clientSecretDraft = ""
                }
                .font(KairosTheme.Typography.caption)
                .foregroundStyle(KairosTheme.Colors.background)
                .padding(.horizontal, KairosTheme.Spacing.md)
                .padding(.vertical, KairosTheme.Spacing.xs)
                .background(credentialsValid ? KairosTheme.Colors.accent : KairosTheme.Colors.border)
                .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
                .buttonStyle(.plain)
                .disabled(!credentialsValid)
            }
        }
    }

    private var credentialsValid: Bool {
        !clientIdDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !clientSecretDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func instructionRow(n: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(n + ".")
                .font(KairosTheme.Typography.monoSmall)
                .foregroundStyle(KairosTheme.Colors.textMuted)
                .frame(width: 12, alignment: .trailing)
            Text(text)
                .font(KairosTheme.Typography.monoSmall)
                .foregroundStyle(KairosTheme.Colors.textSecondary)
        }
    }

    private func credentialField(label: String, text: Binding<String>, field: CredentialField) -> some View {
        HStack {
            Text(label + ":")
                .font(KairosTheme.Typography.monoSmall)
                .foregroundStyle(KairosTheme.Colors.textMuted)
                .frame(width: 90, alignment: .trailing)
            TextField("", text: text)
                .textFieldStyle(.plain)
                .font(KairosTheme.Typography.mono)
                .foregroundStyle(KairosTheme.Colors.textPrimary)
                .focused($setupFocus, equals: field)
        }
        .padding(KairosTheme.Spacing.xs)
        .background(KairosTheme.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
        .overlay(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm)
            .stroke(KairosTheme.Colors.border, lineWidth: 1))
    }

    // MARK: - Step 2: Authorize

    private var authorizeView: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Oura app registered")
                        .font(KairosTheme.Typography.headline)
                        .foregroundStyle(KairosTheme.Colors.textPrimary)
                    Text("Complete OAuth in your browser to start syncing.")
                        .font(KairosTheme.Typography.caption)
                        .foregroundStyle(KairosTheme.Colors.textSecondary)
                }
                Spacer()
                Button {
                    oura.startAuthorization()
                } label: {
                    HStack(spacing: 4) {
                        Text("Authorize with Oura")
                        Image(systemName: "arrow.up.right.square")
                    }
                    .font(KairosTheme.Typography.caption)
                    .foregroundStyle(KairosTheme.Colors.background)
                    .padding(.horizontal, KairosTheme.Spacing.md)
                    .padding(.vertical, KairosTheme.Spacing.xs)
                    .background(KairosTheme.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
                }
                .buttonStyle(.plain)
            }
            if let err = oura.fetchError {
                Text(err)
                    .font(KairosTheme.Typography.monoSmall)
                    .foregroundStyle(KairosTheme.Colors.status(.blocked))
            }
            Button("Reset credentials") { oura.resetAll() }
                .font(KairosTheme.Typography.monoSmall)
                .foregroundStyle(KairosTheme.Colors.textMuted)
                .buttonStyle(.plain)
        }
    }

    #endif // os(macOS)

    // MARK: - HealthKit connect row (all platforms)

    private var healthKitConnectRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Connect Apple Health")
                    .font(KairosTheme.Typography.headline)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                Text("Reads Oura data synced via iPhone Health app.")
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

    // MARK: - States

    private var loadingView: some View {
        HStack {
            ProgressView().scaleEffect(0.7)
            Text("Loading health data…")
                .font(KairosTheme.Typography.caption)
                .foregroundStyle(KairosTheme.Colors.textMuted)
        }
    }

    private func errorView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(KairosTheme.Colors.status(.blocked))
            Text(message)
                .font(KairosTheme.Typography.caption)
                .foregroundStyle(KairosTheme.Colors.textMuted)
                .lineLimit(2)
            Spacer()
            Button("Retry") {
                Task { await oura.fetchCurrentSnapshot() }
            }
            .font(KairosTheme.Typography.caption)
            .foregroundStyle(KairosTheme.Colors.accent)
            .buttonStyle(.plain)
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
