import SwiftUI
import SwiftData

// MARK: - OnboardingView

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var step = 0
    @State private var showYearWizard = false
    @State private var yearSetupDone = false

    private let totalSteps = 5

    var body: some View {
        ZStack {
            KairosTheme.Colors.background.ignoresSafeArea()
            Group {
                switch step {
                case 0: welcomeStep
                case 1: conceptStep
                case 2: exampleStep
                case 3: rhythmStep
                case 4: intelligenceStep
                case 5: yearStep
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
                Text("A framework for deliberate annual living.")
                    .font(KairosTheme.Typography.body)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, KairosTheme.Spacing.xxl)
            primaryButton("Get started") { step = 1 }
        }
    }

    // MARK: - Step 1: The concept

    private var conceptStep: some View {
        centeredContent {
            stepHeader(
                title: "Annual OKRs for your life",
                subtitle: "OKRs — Objectives and Key Results — are a goal-setting framework used by high-performing teams. Here, they are applied to the one project that actually matters: your life."
            )
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.md) {
                conceptRow(
                    label: "Domains",
                    description: "The areas of life you choose to invest in. Health. Relationships. Work. Learning. Finances. You define what matters."
                )
                KairosDivider()
                conceptRow(
                    label: "Objectives",
                    description: "What you want to achieve in each domain this year. Ambitious but honest. Not a task list — a direction."
                )
                KairosDivider()
                conceptRow(
                    label: "Key Results",
                    description: "Specific, measurable evidence that progress has been made. Not activities. Evidence."
                )
            }
            .padding(KairosTheme.Spacing.md)
            .background(KairosTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
            .overlay(RoundedRectangle(cornerRadius: KairosTheme.Radius.md).stroke(KairosTheme.Colors.border, lineWidth: 1))
            .frame(maxWidth: 500)
            .padding(.top, KairosTheme.Spacing.xl)
            primaryButton("See an example") { step = 2 }
                .padding(.top, KairosTheme.Spacing.xl)
        }
    }

    // MARK: - Step 2: Example

    private var exampleStep: some View {
        centeredContent {
            stepHeader(
                title: "An example",
                subtitle: "A single domain, broken down into one objective and three key results."
            )
            VStack(alignment: .leading, spacing: 0) {
                exampleRow(level: .domain,    label: "Domain",     value: "Health")
                exampleRow(level: .objective, label: "Objective",  value: "Build physical resilience")
                exampleRow(level: .kr,        label: "Key Result", value: "Average 7.5 hours of sleep per night")
                exampleRow(level: .kr,        label: "Key Result", value: "Complete 150 strength sessions by year end")
                exampleRow(level: .kr,        label: "Key Result", value: "VO2 max above 45 by December")
            }
            .background(KairosTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
            .overlay(RoundedRectangle(cornerRadius: KairosTheme.Radius.md).stroke(KairosTheme.Colors.border, lineWidth: 1))
            .frame(maxWidth: 500)
            .padding(.top, KairosTheme.Spacing.xl)
            primaryButton("Continue") { step = 3 }
                .padding(.top, KairosTheme.Spacing.xl)
        }
    }

    // MARK: - Step 3: The rhythm

    private var rhythmStep: some View {
        centeredContent {
            stepHeader(
                title: "How you will use it",
                subtitle: "Three cadences. Each serves a different purpose."
            )
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.md) {
                rhythmRow(cadence: "Each year",  description: "Define your domains, objectives, and key results. Set an intention — a word or phrase that anchors the year.")
                KairosDivider()
                rhythmRow(cadence: "Each month", description: "A structured review. What moved. What didn't. Why. Recorded as a voice note and summarised automatically.")
                KairosDivider()
                rhythmRow(cadence: "Each week",  description: "A brief pulse. Energy level, themes, a short note. Takes two minutes. Compounds over time.")
            }
            .padding(KairosTheme.Spacing.md)
            .background(KairosTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
            .overlay(RoundedRectangle(cornerRadius: KairosTheme.Radius.md).stroke(KairosTheme.Colors.border, lineWidth: 1))
            .frame(maxWidth: 500)
            .padding(.top, KairosTheme.Spacing.xl)
            primaryButton("Continue") { step = 4 }
                .padding(.top, KairosTheme.Spacing.xl)
        }
    }

    // MARK: - Step 4: Apple Intelligence

    private var intelligenceStep: some View {
        centeredContent {
            stepHeader(
                title: "On-device AI",
                subtitle: "FourOneEight uses Apple Intelligence to generate insights, challenge your thinking during reviews, and summarise your year."
            )
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.md) {
                infoRow(
                    title: "Private by design",
                    body: "All AI runs on-device using Apple Intelligence. Your data never leaves your device."
                )
                KairosDivider()
                infoRow(
                    title: "Synced across devices",
                    body: "Summaries generated on a device with Apple Intelligence are stored in iCloud and displayed on all your devices — including those without it."
                )
                KairosDivider()
                infoRow(
                    title: "Supported devices",
                    body: "iPhone 16 and later, iPad mini (A17 Pro), iPad with M1 or later, Mac with Apple Silicon. Requires Apple Intelligence to be enabled in Settings."
                )
            }
            .padding(KairosTheme.Spacing.md)
            .background(KairosTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
            .overlay(RoundedRectangle(cornerRadius: KairosTheme.Radius.md).stroke(KairosTheme.Colors.border, lineWidth: 1))
            .frame(maxWidth: 500)
            .padding(.top, KairosTheme.Spacing.xl)
            primaryButton("Continue") { step = 5 }
                .padding(.top, KairosTheme.Spacing.xl)
        }
    }

    // MARK: - Step 5: Year setup

    private var yearStep: some View {
        centeredContent {
            stepHeader(
                title: "Set up your year",
                subtitle: "Define your domains, objectives, and key results for \(currentYear)."
            )
            OnboardingCard(
                icon: yearSetupDone ? "checkmark.circle" : "calendar",
                title: yearSetupDone ? String("\(currentYear) is set up") : String("Set up \(currentYear)"),
                subtitle: yearSetupDone
                    ? "Domains, objectives, and key results created"
                    : "Create your structure for the year",
                accent: yearSetupDone ? KairosTheme.Colors.status(.done) : KairosTheme.Colors.accent
            ) {
                showYearWizard = true
            }
            .frame(maxWidth: 460)
            .padding(.top, KairosTheme.Spacing.xl)

            primaryButton("Continue to the app") { onComplete() }
                .padding(.top, KairosTheme.Spacing.xl)
        }
    }

    // MARK: - Step 6: Health (iOS only)

    // MARK: - Shared components

    private func centeredContent<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: KairosTheme.Spacing.xxl)
                VStack(spacing: 0) { content() }
                    .padding(KairosTheme.Spacing.xxl)
                Spacer(minLength: KairosTheme.Spacing.xxl)
            }
            .frame(maxWidth: .infinity, minHeight: 400)
        }
    }

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(spacing: KairosTheme.Spacing.sm) {
            Text(title)
                .font(KairosTheme.Typography.displayMedium)
                .foregroundStyle(KairosTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(KairosTheme.Typography.body)
                .foregroundStyle(KairosTheme.Colors.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, KairosTheme.Spacing.lg)
        .frame(maxWidth: 500)
    }

    private func conceptRow(label: String, description: String) -> some View {
        HStack(alignment: .top, spacing: KairosTheme.Spacing.md) {
            Text(label)
                .font(KairosTheme.Typography.mono)
                .foregroundStyle(KairosTheme.Colors.accent)
                .frame(width: 90, alignment: .leading)
            Text(description)
                .font(KairosTheme.Typography.caption)
                .foregroundStyle(KairosTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }

    private func rhythmRow(cadence: String, description: String) -> some View {
        HStack(alignment: .top, spacing: KairosTheme.Spacing.md) {
            Text(cadence)
                .font(KairosTheme.Typography.mono)
                .foregroundStyle(KairosTheme.Colors.accent)
                .frame(width: 90, alignment: .leading)
            Text(description)
                .font(KairosTheme.Typography.caption)
                .foregroundStyle(KairosTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }

    private func infoRow(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(KairosTheme.Typography.headline)
                .foregroundStyle(KairosTheme.Colors.textPrimary)
            Text(body)
                .font(KairosTheme.Typography.caption)
                .foregroundStyle(KairosTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
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

// MARK: - Example row levels

private enum ExampleLevel { case domain, objective, kr }

private func exampleRow(level: ExampleLevel, label: String, value: String) -> some View {
    HStack(alignment: .top, spacing: KairosTheme.Spacing.md) {
        Text(label)
            .font(KairosTheme.Typography.monoSmall)
            .foregroundStyle(KairosTheme.Colors.textMuted)
            .frame(width: 80, alignment: .leading)
            .padding(.leading, level == .kr ? 16 : level == .objective ? 8 : 0)
        Text(value)
            .font(level == .domain ? KairosTheme.Typography.headline : KairosTheme.Typography.body)
            .foregroundStyle(level == .domain ? KairosTheme.Colors.textPrimary : KairosTheme.Colors.textSecondary)
        Spacer()
    }
    .padding(.horizontal, KairosTheme.Spacing.md)
    .padding(.vertical, KairosTheme.Spacing.sm)
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
