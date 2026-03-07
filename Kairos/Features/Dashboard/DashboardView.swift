import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \KairosYear.year, order: .reverse) private var years: [KairosYear]
    @State private var selectedYear = 2026

    private var currentYear: KairosYear? { years.first { $0.year == selectedYear } }

    private let columns = [
        GridItem(.flexible(), spacing: KairosTheme.Spacing.md),
        GridItem(.flexible(), spacing: KairosTheme.Spacing.md),
        GridItem(.flexible(), spacing: KairosTheme.Spacing.md)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xl) {
                header
                if let year = currentYear {
                    overallProgress(for: year)
                    domainGrid(for: year)
                } else {
                    emptyState
                }
            }
            .padding(KairosTheme.Spacing.xl)
        }
        .background(KairosTheme.Colors.background)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                HStack(spacing: KairosTheme.Spacing.sm) {
                    ForEach(years.prefix(3), id: \.id) { y in
                        Button {
                            selectedYear = y.year
                        } label: {
                            Text(String(y.year))
                                .font(KairosTheme.Typography.mono)
                                .foregroundStyle(
                                    y.year == selectedYear
                                    ? KairosTheme.Colors.textPrimary
                                    : KairosTheme.Colors.textMuted
                                )
                                .padding(.horizontal, KairosTheme.Spacing.sm)
                                .padding(.vertical, KairosTheme.Spacing.xs)
                                .background(
                                    y.year == selectedYear
                                    ? KairosTheme.Colors.surfaceElevated
                                    : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
                        }
                        .buttonStyle(.plain)
                    }
                }
                if let intention = currentYear?.intention, !intention.isEmpty {
                    Text(intention)
                        .font(KairosTheme.Typography.displayMedium)
                        .foregroundStyle(KairosTheme.Colors.textPrimary)
                        .italic()
                }
            }
            Spacer()
            // Month indicator
            Text(monthLabel)
                .font(KairosTheme.Typography.mono)
                .foregroundStyle(KairosTheme.Colors.textMuted)
        }
    }

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: Date()).uppercased()
    }

    // MARK: - Overall Progress

    private func overallProgress(for year: KairosYear) -> some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
            HStack {
                KairosLabel(text: "Overall Progress")
                Spacer()
                Text("\(Int(year.overallProgress * 100))%")
                    .font(KairosTheme.Typography.mono)
                    .foregroundStyle(KairosTheme.Colors.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(KairosTheme.Colors.border)
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(KairosTheme.Colors.accent)
                        .frame(width: geo.size.width * year.overallProgress, height: 3)
                }
            }
            .frame(height: 3)

            // KR status summary strip
            HStack(spacing: 2) {
                let krs = year.allKeyResults
                ForEach(KRStatus.allCases, id: \.self) { status in
                    let count = krs.filter { $0.currentStatus == status }.count
                    if count > 0 {
                        let fraction = Double(count) / Double(max(krs.count, 1))
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(KairosTheme.Colors.status(status))
                                .frame(width: max(geo.size.width * fraction, 2))
                        }
                    }
                }
            }
            .frame(height: 6)

            HStack {
                ForEach(KRStatus.allCases, id: \.self) { status in
                    let count = year.allKeyResults.filter { $0.currentStatus == status }.count
                    if count > 0 {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(KairosTheme.Colors.status(status))
                                .frame(width: 5, height: 5)
                            Text("\(count) \(status.displayName)")
                                .font(KairosTheme.Typography.monoSmall)
                                .foregroundStyle(KairosTheme.Colors.textMuted)
                        }
                    }
                }
                Spacer()
                Text("\(year.allKeyResults.count) KRs total")
                    .font(KairosTheme.Typography.monoSmall)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
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

    // MARK: - Domain Grid

    private func domainGrid(for year: KairosYear) -> some View {
        LazyVGrid(columns: columns, spacing: KairosTheme.Spacing.md) {
            ForEach(year.sortedDomains) { domain in
                DomainCard(domain: domain)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: KairosTheme.Spacing.md) {
            Text("No data for \(selectedYear)")
                .font(KairosTheme.Typography.headline)
                .foregroundStyle(KairosTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

// MARK: - DomainCard

struct DomainCard: View {
    let domain: KairosDomain
    @State private var isHovered = false

    private var domainColor: Color { KairosTheme.Colors.domain(domain.name) }
    private var allKRs: [KairosKeyResult] { domain.allKeyResults }

    var body: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.md) {

            // Title row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(domain.emoji)
                        .font(.title2)
                    Text(domain.name.uppercased())
                        .font(KairosTheme.Typography.monoSmall)
                        .foregroundStyle(KairosTheme.Colors.textSecondary)
                        .tracking(1.5)
                }
                Spacer()
                Text("\(Int(domain.progress * 100))%")
                    .font(KairosTheme.Typography.monoLarge)
                    .foregroundStyle(domainColor)
            }

            // KR status dots
            krDots

            Spacer(minLength: 0)

            // Progress bar + count
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(KairosTheme.Colors.border)
                            .frame(height: 2)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(domainColor)
                            .frame(width: geo.size.width * domain.progress, height: 2)
                    }
                }
                .frame(height: 2)

                HStack {
                    Text("\(domain.completedCount)/\(allKRs.count) KRs")
                        .font(KairosTheme.Typography.monoSmall)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                    Spacer()
                    // Latest notable commentary snippet
                    if let note = latestNote {
                        Text(note)
                            .font(KairosTheme.Typography.monoSmall)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                            .lineLimit(1)
                            .frame(maxWidth: 120, alignment: .trailing)
                    }
                }
            }
        }
        .padding(KairosTheme.Spacing.md)
        .frame(minHeight: 150)
        .background(isHovered ? KairosTheme.Colors.surfaceElevated : KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
                .stroke(isHovered ? domainColor.opacity(0.4) : KairosTheme.Colors.border, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
    }

    // KR dots arranged in rows of 6
    private var krDots: some View {
        let chunked = allKRs.chunked(into: 7)
        return VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(chunked.enumerated()), id: \.offset) { _, chunk in
                HStack(spacing: 3) {
                    ForEach(chunk) { kr in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(KairosTheme.Colors.status(kr.currentStatus))
                            .frame(width: 14, height: 7)
                    }
                }
            }
        }
    }

    private var latestNote: String? {
        allKRs
            .compactMap { $0.latestCommentary.isEmpty ? nil : $0.latestCommentary }
            .first
            .map { String($0.prefix(40)) + ($0.count > 40 ? "…" : "") }
    }
}

// MARK: - Array Chunking

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
