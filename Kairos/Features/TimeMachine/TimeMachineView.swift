import SwiftUI
import SwiftData

struct TimeMachineView: View {
    @Query(sort: \KairosYear.year, order: .forward) private var years: [KairosYear]
    @State private var selectedYear = 2026
    @State private var selectedDomain = ""
    @State private var yearInsights: [Int: String] = [:]
    @State private var isLoadingInsight = false

    private let monthAbbrs = ["J","F","M","A","M","J","J","A","S","O","N","D"]

    private var currentYear: KairosYear? {
        years.first { $0.year == selectedYear }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xl) {
                header
                if let year = currentYear {
                    if years.count > 1 { yearPicker }
                    yearProgressSection(year)
                    if !selectedDomain.isEmpty {
                        domainPicker(year)
                        monthlyHeatmap(year)
                        krStatusTable(year)
                    }
                    if years.count >= 2 { crossYearSection }
                } else {
                    emptyState
                }
            }
            .padding(KairosTheme.Spacing.xl)
        }
        .background(KairosTheme.Colors.background)
        .onAppear { initSelection() }
        .onChange(of: selectedYear) { _, _ in initSelection() }
        .task(id: selectedYear) { await loadInsight() }
    }

    private func initSelection() {
        if let first = currentYear?.sortedDomains.first {
            if selectedDomain.isEmpty || currentYear?.domains.first(where: { $0.name == selectedDomain }) == nil {
                selectedDomain = first.name
            }
        }
    }

    // MARK: - Insight

    private func loadInsight() async {
        guard let year = currentYear else { return }
        if yearInsights[year.year] != nil { return }
        isLoadingInsight = true
        defer { isLoadingInsight = false }
        let ctx = IntelligenceManager.shared.buildContext(from: year)
        let prompt = "One punchy sentence, max 18 words: summarize this year. Name the strongest domain and the biggest struggle. No filler."
        do {
            let result = try await IntelligenceManager.shared.engine.complete(prompt: prompt, context: ctx)
            yearInsights[year.year] = result.count < 200 ? result : staticInsight(year)
        } catch {
            yearInsights[year.year] = staticInsight(year)
        }
    }

    private func staticInsight(_ year: KairosYear) -> String {
        let domains = year.sortedDomains
        guard !domains.isEmpty else { return "\(year.year) — No data recorded." }
        let sorted = domains.sorted { $0.progress > $1.progress }
        let best = sorted.first!
        let worst = sorted.last!
        let pct = Int(year.overallProgress * 100)
        guard best.name != worst.name else {
            return "\(year.year) — \(pct)% overall across all domains."
        }
        return "\(year.year) — \(pct)% overall · strong in \(best.name), needs work in \(worst.name)."
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
            KairosLabel(text: "Time Machine")
            Group {
                if let insight = yearInsights[selectedYear] {
                    Text(insight)
                } else if let year = currentYear {
                    Text(staticInsight(year))
                        .opacity(isLoadingInsight ? 0.4 : 1)
                } else {
                    Text("Progress History")
                }
            }
            .font(KairosTheme.Typography.displayMedium)
            .foregroundStyle(KairosTheme.Colors.textPrimary)
            .animation(.easeIn(duration: 0.3), value: yearInsights[selectedYear])

            Text("Monthly patterns, KR history, and year-over-year trends.")
                .font(KairosTheme.Typography.body)
                .foregroundStyle(KairosTheme.Colors.textSecondary)
        }
    }

    // MARK: - Year Picker

    private var yearPicker: some View {
        HStack(spacing: KairosTheme.Spacing.sm) {
            ForEach(years) { y in
                Button { selectedYear = y.year } label: {
                    Text(String(y.year))
                        .font(KairosTheme.Typography.mono)
                        .foregroundStyle(
                            y.year == selectedYear
                            ? KairosTheme.Colors.background
                            : KairosTheme.Colors.textSecondary
                        )
                        .padding(.horizontal, KairosTheme.Spacing.sm)
                        .padding(.vertical, KairosTheme.Spacing.xs)
                        .background(
                            y.year == selectedYear
                            ? KairosTheme.Colors.accent
                            : KairosTheme.Colors.surface
                        )
                        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Year Progress Overview

    private func yearProgressSection(_ year: KairosYear) -> some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
            KairosLabel(text: "\(year.year) — Domain Progress")
            VStack(spacing: KairosTheme.Spacing.sm) {
                ForEach(year.sortedDomains) { domain in
                    HStack(spacing: KairosTheme.Spacing.md) {
                        HStack(spacing: KairosTheme.Spacing.xs) {
                            Text(domain.emoji).font(.system(size: 13))
                            Text(domain.name)
                                .font(KairosTheme.Typography.caption)
                                .foregroundStyle(KairosTheme.Colors.textSecondary)
                        }
                        .frame(width: 120, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(KairosTheme.Colors.border)
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(KairosTheme.Colors.domain(domain.name))
                                    .frame(width: max(4, geo.size.width * CGFloat(domain.progress)), height: 6)
                            }
                        }
                        .frame(height: 6)

                        Text("\(Int(domain.progress * 100))%")
                            .font(KairosTheme.Typography.monoSmall)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                            .frame(width: 32, alignment: .trailing)
                    }
                }
            }
        }
        .padding(KairosTheme.Spacing.md)
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
                .stroke(KairosTheme.Colors.border, lineWidth: 1)
        )
    }

    // MARK: - Domain Picker

    private func domainPicker(_ year: KairosYear) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: KairosTheme.Spacing.sm) {
                ForEach(year.sortedDomains) { domain in
                    Button { selectedDomain = domain.name } label: {
                        HStack(spacing: 4) {
                            Text(domain.emoji).font(.system(size: 11))
                            Text(domain.name).font(KairosTheme.Typography.caption)
                        }
                        .foregroundStyle(
                            domain.name == selectedDomain
                            ? KairosTheme.Colors.background
                            : KairosTheme.Colors.textSecondary
                        )
                        .padding(.horizontal, KairosTheme.Spacing.sm)
                        .padding(.vertical, KairosTheme.Spacing.xs)
                        .background(
                            domain.name == selectedDomain
                            ? KairosTheme.Colors.domain(domain.name)
                            : KairosTheme.Colors.surface
                        )
                        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Monthly Heatmap

    @ViewBuilder
    private func monthlyHeatmap(_ year: KairosYear) -> some View {
        if let domain = year.domains.first(where: { $0.name == selectedDomain }) {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.md) {
                KairosLabel(text: "\(selectedDomain) — \(year.year) Activity")

                HStack(spacing: 3) {
                    Text("").frame(width: 40)
                    ForEach(0..<12, id: \.self) { i in
                        Text(monthAbbrs[i])
                            .font(KairosTheme.Typography.monoSmall)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                            .frame(maxWidth: .infinity)
                    }
                }

                HStack(spacing: 3) {
                    Text(String(year.year))
                        .font(KairosTheme.Typography.monoSmall)
                        .foregroundStyle(KairosTheme.Colors.textSecondary)
                        .frame(width: 40, alignment: .leading)

                    ForEach(1...12, id: \.self) { month in
                        let cell = cellData(domain: domain, month: month, year: year.year)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(cell.color)
                            .frame(maxWidth: .infinity)
                            .frame(height: 28)
                            .overlay(
                                Text(cell.label)
                                    .font(KairosTheme.Typography.monoSmall)
                                    .foregroundStyle(KairosTheme.Colors.textPrimary.opacity(0.7))
                            )
                            .help(cell.tooltip)
                    }
                }

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
    }

    // MARK: - KR Status Table

    @ViewBuilder
    private func krStatusTable(_ year: KairosYear) -> some View {
        if let domain = year.domains.first(where: { $0.name == selectedDomain }),
           !domain.sortedObjectives.isEmpty {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.md) {
                KairosLabel(text: "\(selectedDomain) — Key Result History")

                // Column header
                HStack(spacing: 3) {
                    Text("Key Result")
                        .font(KairosTheme.Typography.monoSmall)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                        .frame(minWidth: 140, maxWidth: .infinity, alignment: .leading)
                    ForEach(0..<12, id: \.self) { i in
                        Text(monthAbbrs[i])
                            .font(KairosTheme.Typography.monoSmall)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                            .frame(width: 22, alignment: .center)
                    }
                }

                KairosDivider()

                // Grouped by objective
                ForEach(domain.sortedObjectives) { objective in
                    if !objective.sortedKeyResults.isEmpty {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(objective.title)
                                .font(KairosTheme.Typography.caption)
                                .foregroundStyle(KairosTheme.Colors.textSecondary)
                                .padding(.top, KairosTheme.Spacing.xs)

                            ForEach(objective.sortedKeyResults) { kr in
                                krHistoryRow(kr: kr, year: year.year)
                            }
                        }
                    }
                }
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

    private func krHistoryRow(kr: KairosKeyResult, year: Int) -> some View {
        HStack(spacing: 3) {
            Text(kr.title)
                .font(KairosTheme.Typography.monoSmall)
                .foregroundStyle(KairosTheme.Colors.textMuted)
                .lineLimit(1)
                .frame(minWidth: 140, maxWidth: .infinity, alignment: .leading)

            ForEach(1...12, id: \.self) { month in
                let entry = kr.entries.first { $0.year == year && $0.month == month }
                Group {
                    if let e = entry {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(KairosTheme.Colors.status(e.statusEnum))
                            .help("\(kr.title) · \(monthAbbrs[month - 1]) · \(e.statusEnum.displayName)\(e.rating > 0 ? " · \(e.rating)★" : "")")
                    } else {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(KairosTheme.Colors.borderSubtle)
                            .help("\(kr.title) · \(monthAbbrs[month - 1]) · No entry")
                    }
                }
                .frame(width: 22, height: 14)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Cross-Year Grid

    private var crossYearSection: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.md) {
            KairosLabel(text: "Year over Year — \(selectedDomain)")

            // Month headers
            HStack(spacing: 2) {
                Text("Year")
                    .font(KairosTheme.Typography.monoSmall)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
                    .frame(width: 40, alignment: .leading)
                ForEach(0..<12, id: \.self) { i in
                    Text(monthAbbrs[i])
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
                            .foregroundStyle(
                                year.year == selectedYear
                                ? KairosTheme.Colors.textPrimary
                                : KairosTheme.Colors.textSecondary
                            )
                            .frame(width: 40, alignment: .leading)

                        ForEach(1...12, id: \.self) { month in
                            let cell = cellData(domain: domain, month: month, year: year.year)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(cell.color)
                                .frame(maxWidth: .infinity)
                                .frame(height: 24)
                                .overlay(
                                    Text(cell.label)
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundStyle(KairosTheme.Colors.textPrimary.opacity(0.6))
                                )
                                .help(cell.tooltip)
                        }
                    }
                }
            }

            legendView

            HStack(spacing: KairosTheme.Spacing.sm) {
                Image(systemName: "lightbulb")
                    .foregroundStyle(KairosTheme.Colors.accent)
                    .font(.caption)
                Text("Seasonal patterns become clearer with each additional year of data.")
                    .font(KairosTheme.Typography.caption)
                    .foregroundStyle(KairosTheme.Colors.textSecondary)
            }
            .padding(KairosTheme.Spacing.sm)
            .background(KairosTheme.Colors.accentSubtle)
            .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
        }
        .padding(KairosTheme.Spacing.md)
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
                .stroke(KairosTheme.Colors.border, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private struct CellData {
        let color: Color
        let label: String
        let tooltip: String
    }

    private func cellData(domain: KairosDomain, month: Int, year: Int) -> CellData {
        let entries = domain.allKeyResults
            .flatMap { $0.entries }
            .filter { $0.month == month && $0.year == year }

        if entries.isEmpty {
            return CellData(color: KairosTheme.Colors.borderSubtle, label: "", tooltip: "No data")
        }

        let avg = entries.reduce(0.0) { $0 + $1.statusEnum.weight } / Double(entries.count)
        let label = avg > 0.05 ? "\(Int(avg * 100))%" : ""
        let tooltip = "\(domain.name) · \(monthAbbrs[month - 1]) \(year) · \(entries.count) KR\(entries.count == 1 ? "" : "s") · \(Int(avg * 100))% avg"

        return CellData(color: progressColor(avg), label: label, tooltip: tooltip)
    }

    private func progressColor(_ p: Double) -> Color {
        if p == 0    { return KairosTheme.Colors.borderSubtle }
        if p < 0.2   { return KairosTheme.Colors.status(.initialized).opacity(0.4) }
        if p < 0.5   { return KairosTheme.Colors.status(.inProgress).opacity(0.5) }
        if p < 0.8   { return KairosTheme.Colors.status(.inProgress).opacity(0.8) }
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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: KairosTheme.Spacing.lg) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(KairosTheme.Colors.textMuted)
            Text("No data yet")
                .font(KairosTheme.Typography.headline)
                .foregroundStyle(KairosTheme.Colors.textMuted)
            Text("Start tracking key results and they'll appear here.")
                .font(KairosTheme.Typography.body)
                .foregroundStyle(KairosTheme.Colors.textMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}
