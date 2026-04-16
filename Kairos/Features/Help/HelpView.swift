import SwiftUI

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                    Text("How Tenets Works")
                        .font(KairosTheme.Typography.displayMedium)
                        .foregroundStyle(KairosTheme.Colors.textPrimary)
                    Text("Life-first annual planning")
                        .font(KairosTheme.Typography.body)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                        .italic()
                }
                .padding(.bottom, KairosTheme.Spacing.md)

                // Values
                helpSection(
                    title: "Values",
                    icon: "sparkles",
                    content: "Start with 3–5 timeless principles your life is built around. These guide everything else."
                )

                // Domains
                helpSection(
                    title: "Domains",
                    icon: "square.grid.2x2",
                    content: "The areas of life you're investing in this year: Health, Work, Relationships, Growth, etc. Each domain tracks progress across multiple objectives."
                )

                // Objectives & Key Results
                helpSection(
                    title: "Objectives & Key Results",
                    icon: "target",
                    content: "Objectives are ambitious aims within each domain. Key Results measure progress (0–100%). Keep them honest: if you hit 100%, you sandbagged. Aim for 70–80%."
                )

                // Weekly Pulse
                helpSection(
                    title: "Weekly Pulse",
                    icon: "waveform",
                    content: "Every week, spend 2 minutes on this: What's your energy level? What's the theme this week? Add a short note. The compound effect of staying honest, week by week."
                )

                // Monthly Review
                helpSection(
                    title: "Monthly Review",
                    icon: "bubble.left.and.bubble.right",
                    content: "Rate your key results. Have a short structured conversation about what moved and what didn't. Tenets summarizes your reflection into a clear written record."
                )

                // Time Machine
                helpSection(
                    title: "Time Machine",
                    icon: "clock.arrow.circlepath",
                    content: "See year-over-year trends, monthly activity, and key result history. Understand the shape of your year, not just the last 30 days."
                )

                Spacer(minLength: 20)
            }
            .padding(KairosTheme.Spacing.xl)
        }
        .background(KairosTheme.Colors.background)
    }

    @ViewBuilder
    private func helpSection(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
            HStack(spacing: KairosTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(KairosTheme.Colors.accent)
                Text(title.uppercased())
                    .font(KairosTheme.Typography.headline)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                    .tracking(1)
            }
            Text(content)
                .font(KairosTheme.Typography.body)
                .foregroundStyle(KairosTheme.Colors.textSecondary)
                .lineSpacing(2)
        }
        .padding(KairosTheme.Spacing.md)
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
                .stroke(KairosTheme.Colors.border, lineWidth: 1)
        )
    }
}

#Preview {
    HelpView()
        .preferredColorScheme(.dark)
}
