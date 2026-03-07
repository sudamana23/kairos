import SwiftUI
import SwiftData

struct TimeMachineView: View {
    @Query(sort: \KairosYear.year, order: .forward) private var years: [KairosYear]
    @State private var selectedDomain = "Health"

    private let domains = ["Health", "Work", "Spirit", "Sport", "Kids", "Love", "Externalities"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xl) {
                header
                if years.count >= 2 {
                    domainPicker
                    crossYearGrid
                    seasonalNote
                } else {
                    insufficientDataView
                }
            }
            .padding(KairosTheme.Spacing.xl)
        }
        .background(KairosTheme.Colors.background)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
            KairosLabel(text: "Time Machine")
            Text("Patterns across years")
                .font(KairosTheme.Typography.displayMedium)
                .foregroundStyle(KairosTheme.Colors.textPrimary)
            Text("Seasonal slumps and peaks become visible over time.")
                .font(KairosTheme.Typography.body)
                .foregroundStyle(KairosTheme.Colors.textSecondary)
        }
    }

    // MARK: - Domain Picker

    private var domainPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: KairosTheme.Spacing.sm) {
                ForEach(domains, id: \.self) { domain in
                    Button {
                        selectedDomain = domain
                    } label: {
                        Text(domain)
                            .font(KairosTheme.Typography.caption)
                            .foregroundStyle(
                                domain == selectedDomain
                                ? KairosTheme.Colors.background
                                : KairosTheme.Colors.textSecondary
                            )
                            .padding(.horizontal, KairosTheme.Spacing.sm)
                            .padding(.vertical, KairosTheme.Spacing.xs)
                            .background(
                                domain == selectedDomain
                                ? KairosTheme.Colors.domain(domain)
                                : KairosTheme.Colors.surface
                            )
                            .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Cross-Year Heatmap Grid

    private var crossYearGrid: some View {
        let monthAbbrs = ["J","F","M","A","M","J","J","A","S","O","N","D"]

        return VStack(alignment: .leading, spacing: KairosTheme.Spacing.md) {
            KairosLabel(text: "\(selectedDomain) — Month by Month")

            // Month headers
            HStack(spacing: 2) {
                Text("Year")
                    .font(KairosTheme.Typography.monoSmall)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
                    .frame(width: 40, alignment: .leading)
                ForEach(monthAbbrs, id: \.self) { m in
                    Text(m)
                        .font(KairosTheme.Typography.monoSmall)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }

            // Year rows
            ForEach(years) { year in
                if let domain = year.domains.first(where: { $0.name == selectedDomain }) {
                    HStack(spacing: 2) {
                        Text(String(year.year))
                            .font(KairosTheme.Typography.monoSmall)
                            .foregroundStyle(KairosTheme.Colors.textSecondary)
                            .frame(width: 40, alignment: .leading)

                        ForEach(1...12, id: \.self) { month in
                            let cell = cellData(domain: domain, month: month)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(cell.color)
                                .frame(maxWidth: .infinity)
                                .frame(height: 28)
                                .overlay(
                                    Text(cell.label)
                                        .font(KairosTheme.Typography.monoSmall)
                                        .foregroundStyle(KairosTheme.Colors.textPrimary.opacity(0.6))
                                )
                                .help(cell.tooltip)
                        }
                    }
                }
            }

            // Legend
            legendView
        }
        .padding(KairosTheme.Spacing.md)
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
                .stroke(KairosTheme.Colors.border, lineWidth: 1)
        )
    }

    private struct CellData {
        let color: Color
        let label: String
        let tooltip: String
    }

    private func cellData(domain: KairosDomain, month: Int) -> CellData {
        // Gather all entries for this domain in this month
        let allEntries = domain.allKeyResults
            .flatMap { $0.entries }
            .filter { $0.month == month }

        if allEntries.isEmpty {
            return CellData(color: KairosTheme.Colors.borderSubtle, label: "", tooltip: "No data")
        }

        let avgProgress = allEntries.reduce(0.0) { $0 + $1.statusEnum.weight } / Double(allEntries.count)
        let color = progressColor(avgProgress)
        let label = avgProgress > 0.05 ? "\(Int(avgProgress * 100))%" : ""
        let tooltip = "\(domain.name) · Month \(month) · \(allEntries.count) KRs tracked"

        return CellData(color: color, label: label, tooltip: tooltip)
    }

    private func progressColor(_ progress: Double) -> Color {
        if progress == 0 { return KairosTheme.Colors.borderSubtle }
        if progress < 0.2 { return KairosTheme.Colors.status(.initialized).opacity(0.4) }
        if progress < 0.5 { return KairosTheme.Colors.status(.inProgress).opacity(0.5) }
        if progress < 0.8 { return KairosTheme.Colors.status(.inProgress).opacity(0.8) }
        return KairosTheme.Colors.status(.done).opacity(0.8)
    }

    private var legendView: some View {
        HStack(spacing: KairosTheme.Spacing.md) {
            KairosLabel(text: "Progress →")
            HStack(spacing: 3) {
                ForEach([0.0, 0.2, 0.4, 0.6, 0.8, 1.0], id: \.self) { p in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(progressColor(p))
                        .frame(width: 20, height: 10)
                }
            }
        }
    }

    // MARK: - Seasonal Note

    private var seasonalNote: some View {
        HStack(spacing: KairosTheme.Spacing.md) {
            Image(systemName: "lightbulb")
                .foregroundStyle(KairosTheme.Colors.accent)
            Text("Seasonal patterns become visible after 2–3 years of data. Check back here each year.")
                .font(KairosTheme.Typography.body)
                .foregroundStyle(KairosTheme.Colors.textSecondary)
        }
        .padding(KairosTheme.Spacing.md)
        .background(KairosTheme.Colors.accentSubtle)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
    }

    // MARK: - Insufficient Data

    private var insufficientDataView: some View {
        VStack(spacing: KairosTheme.Spacing.lg) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(KairosTheme.Colors.textMuted)
            Text("Time Machine activates with 2+ years of data")
                .font(KairosTheme.Typography.headline)
                .foregroundStyle(KairosTheme.Colors.textMuted)
            Text("Your 2025 and 2026 data is loaded. Patterns will emerge here as you continue tracking.")
                .font(KairosTheme.Typography.body)
                .foregroundStyle(KairosTheme.Colors.textMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}
