import SwiftUI
import SwiftData

// MARK: - OnboardingView

struct OnboardingView: View {
    @AppStorage("ouraEnabled") private var ouraEnabled = true
    @AppStorage("healthKitEnabled") private var healthKitEnabled = true
    var onComplete: () -> Void

    @State private var step = 0
    @State private var showYearWizard = false
    @State private var yearSetupDone = false

    var body: some View {
        ZStack {
            KairosTheme.Colors.background.ignoresSafeArea()

            Group {
                switch step {
                case 0: welcomeStep
                case 1: yearStep
                case 2: integrationsStep
                default: EmptyView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: step)
        .sheet(isPresented: $showYearWizard) {
            YearWizardView()
                .onDisappear { yearSetupDone = true }
        }
    }

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        centeredContent {
            VStack(spacing: KairosTheme.Spacing.xs) {
                Text("FOURONEIGHT")
                    .font(KairosTheme.Typography.monoLarge)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                    .tracking(6)
                Text("Your annual operating system")
                    .font(KairosTheme.Typography.body)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
            }
            .padding(.bottom, KairosTheme.Spacing.xxl)

            primaryButton("Get Started →") { step = 1 }
        }
    }

    // MARK: - Step 1: Year Setup

    private var yearStep: some View {
        centeredContent {
            stepHeader(
                title: "Set up your year",
                subtitle: "Define what you want to achieve in \(currentYear)"
            )

            OnboardingCard(
                icon: yearSetupDone ? "checkmark.circle.fill" : "sparkles",
                title: yearSetupDone ? "\(currentYear) is set up" : "Set up \(currentYear)",
                subtitle: yearSetupDone
                    ? "Domains, objectives, and key results created"
                    : "Create your domains, objectives, and key results",
                accent: yearSetupDone ? KairosTheme.Colors.status(.done) : KairosTheme.Colors.accent
            ) {
                showYearWizard = true
            }
            .frame(maxWidth: 460)

            VStack(spacing: KairosTheme.Spacing.sm) {
                primaryButton("Continue →") { step = 2 }
                if !yearSetupDone {
                    skipButton("Skip for now") { step = 2 }
                }
            }
            .padding(.top, KairosTheme.Spacing.xl)
        }
    }

    // MARK: - Step 2: Integrations

    private var integrationsStep: some View {
        centeredContent {
            stepHeader(
                title: "Health integrations",
                subtitle: "Connect physiological data to your reviews.\nYou can change this any time in Settings."
            )

            VStack(spacing: KairosTheme.Spacing.md) {
                #if os(macOS)
                integrationToggle(
                    icon: "circle.hexagonpath",
                    title: "Oura Ring",
                    subtitle: "Sleep, HRV, recovery score via OAuth",
                    isOn: $ouraEnabled
                )
                #else
                integrationToggle(
                    icon: "heart.fill",
                    title: "Apple Health",
                    subtitle: "Sleep, HRV, and activity rings from HealthKit",
                    isOn: $healthKitEnabled
                )
                #endif
            }
            .frame(maxWidth: 460)

            primaryButton("Start using FourOneEight") { onComplete() }
                .padding(.top, KairosTheme.Spacing.xl)
        }
    }

    // MARK: - Shared components

    private func centeredContent<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 0) { content() }
            Spacer()
        }
        .padding(KairosTheme.Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(spacing: KairosTheme.Spacing.xs) {
            Text(title)
                .font(KairosTheme.Typography.displayMedium)
                .foregroundStyle(KairosTheme.Colors.textPrimary)
            Text(subtitle)
                .font(KairosTheme.Typography.body)
                .foregroundStyle(KairosTheme.Colors.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, KairosTheme.Spacing.xl)
    }

    private func integrationToggle(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: KairosTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isOn.wrappedValue ? KairosTheme.Colors.accent : KairosTheme.Colors.textMuted)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(KairosTheme.Typography.headline)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                Text(subtitle)
                    .font(KairosTheme.Typography.caption)
                    .foregroundStyle(KairosTheme.Colors.textSecondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(KairosTheme.Spacing.md)
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
                .stroke(
                    isOn.wrappedValue ? KairosTheme.Colors.accent.opacity(0.4) : KairosTheme.Colors.border,
                    lineWidth: 1
                )
        )
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(KairosTheme.Typography.headline)
                .foregroundStyle(KairosTheme.Colors.background)
                .padding(.horizontal, KairosTheme.Spacing.xl)
                .padding(.vertical, KairosTheme.Spacing.sm)
                .background(KairosTheme.Colors.accent)
                .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
        }
        .buttonStyle(.plain)
    }

    private func skipButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(KairosTheme.Typography.caption)
                .foregroundStyle(KairosTheme.Colors.textMuted)
        }
        .buttonStyle(.plain)
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
}

// MARK: - OnboardingCard

struct OnboardingCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: KairosTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(accent)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(KairosTheme.Typography.headline)
                        .foregroundStyle(KairosTheme.Colors.textPrimary)
                    Text(subtitle)
                        .font(KairosTheme.Typography.caption)
                        .foregroundStyle(KairosTheme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
            }
            .padding(KairosTheme.Spacing.md)
            .background(isHovered ? KairosTheme.Colors.surface.opacity(0.8) : KairosTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
                    .stroke(isHovered ? accent.opacity(0.4) : KairosTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
