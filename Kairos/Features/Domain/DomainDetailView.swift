import SwiftUI
import SwiftData

struct DomainDetailView: View {
    let domainName: String

    @Query(sort: \KairosYear.year, order: .reverse) private var years: [KairosYear]
    @State private var selectedYear = 2026
    @State private var expandedObjective: PersistentIdentifier?

    private var domain: KairosDomain? {
        years.first { $0.year == selectedYear }?
            .domains.first { $0.name == domainName }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xl) {
                if let domain {
                    domainHeader(domain)
                    objectiveList(domain)
                } else {
                    emptyState
                }
            }
            .padding(KairosTheme.Spacing.xl)
        }
        .background(KairosTheme.Colors.background)
    }

    // MARK: - Header

    private func domainHeader(_ domain: KairosDomain) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                HStack {
                    Text(domain.emoji).font(.largeTitle)
                    Text(domain.name.uppercased())
                        .font(KairosTheme.Typography.displayMedium)
                        .foregroundStyle(KairosTheme.Colors.textPrimary)
                        .tracking(2)
                }
                if !domain.identityStatement.isEmpty {
                    Text(domain.identityStatement)
                        .font(KairosTheme.Typography.body)
                        .foregroundStyle(KairosTheme.Colors.textSecondary)
                        .italic()
                }
            }
            Spacer()
            // Circular progress
            ZStack {
                Circle()
                    .stroke(KairosTheme.Colors.border, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: domain.progress)
                    .stroke(
                        KairosTheme.Colors.domain(domain.name),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text("\(Int(domain.progress * 100))%")
                    .font(KairosTheme.Typography.mono)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
            }
            .frame(width: 64, height: 64)
        }
    }

    // MARK: - Objective List

    private func objectiveList(_ domain: KairosDomain) -> some View {
        VStack(spacing: KairosTheme.Spacing.sm) {
            ForEach(domain.sortedObjectives) { objective in
                ObjectiveRow(
                    objective: objective,
                    domainName: domainName,
                    isExpanded: expandedObjective == objective.id
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedObjective = expandedObjective == objective.id ? nil : objective.id
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        Text("No data for \(domainName) in \(selectedYear)")
            .font(KairosTheme.Typography.body)
            .foregroundStyle(KairosTheme.Colors.textMuted)
            .frame(maxWidth: .infinity, minHeight: 200)
    }
}

// MARK: - ObjectiveRow

struct ObjectiveRow: View {
    let objective: KairosObjective
    let domainName: String
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Objective header
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(objective.title)
                            .font(KairosTheme.Typography.headline)
                            .foregroundStyle(KairosTheme.Colors.textPrimary)
                        Text("\(objective.keyResults.count) key results")
                            .font(KairosTheme.Typography.caption)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                    }
                    Spacer()
                    // KR status mini-strip
                    HStack(spacing: 2) {
                        ForEach(objective.sortedKeyResults) { kr in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(KairosTheme.Colors.status(kr.currentStatus))
                                .frame(width: 12, height: 6)
                        }
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                        .padding(.leading, KairosTheme.Spacing.sm)
                }
                .padding(KairosTheme.Spacing.md)
            }
            .buttonStyle(.plain)

            // Expanded KR list
            if isExpanded {
                KairosDivider()
                VStack(spacing: 0) {
                    ForEach(objective.sortedKeyResults) { kr in
                        KeyResultRow(kr: kr, domainName: domainName)
                        if kr.id != objective.sortedKeyResults.last?.id {
                            KairosDivider().padding(.leading, KairosTheme.Spacing.md)
                        }
                    }
                }
            }
        }
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
                .stroke(KairosTheme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - KeyResultRow

struct KeyResultRow: View {
    let kr: KairosKeyResult
    let domainName: String

    var body: some View {
        HStack(alignment: .top, spacing: KairosTheme.Spacing.md) {
            // Drag handle / status bar — grab here to move to another domain
            VStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(KairosTheme.Colors.textMuted.opacity(0.4))
                        .frame(width: 3, height: 3)
                }
            }
            .padding(.top, 6)

            RoundedRectangle(cornerRadius: 1)
                .fill(KairosTheme.Colors.status(kr.currentStatus))
                .frame(width: 3)
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                HStack {
                    Text(kr.title)
                        .font(KairosTheme.Typography.body)
                        .foregroundStyle(KairosTheme.Colors.textPrimary)
                    Spacer()
                    StatusPill(status: kr.currentStatus)
                    if kr.latestRating > 0 {
                        ratingDots(kr.latestRating)
                    }
                }

                if !kr.latestCommentary.isEmpty {
                    Text(kr.latestCommentary)
                        .font(KairosTheme.Typography.caption)
                        .foregroundStyle(KairosTheme.Colors.textSecondary)
                        .italic()
                        .lineLimit(3)
                }

                monthlyHistory
            }
        }
        .padding(.horizontal, KairosTheme.Spacing.md)
        .padding(.vertical, KairosTheme.Spacing.sm)
        .draggable(KRDrop(krID: kr.id.uuidString)) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(KairosTheme.Colors.status(kr.currentStatus))
                    .frame(width: 3, height: 20)
                Text(kr.title)
                    .font(KairosTheme.Typography.caption)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(KairosTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
        }
    }

    private func ratingDots(_ rating: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= rating ? KairosTheme.Colors.textSecondary : KairosTheme.Colors.border)
                    .frame(width: 5, height: 5)
            }
        }
    }

    private var monthlyHistory: some View {
        let sorted = kr.entries.sorted { ($0.year, $0.month) < ($1.year, $1.month) }
        return HStack(spacing: 3) {
            ForEach(sorted) { entry in
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(KairosTheme.Colors.status(entry.statusEnum))
                        .frame(width: 10, height: 10)
                    Text(monthAbbr(entry.month))
                        .font(KairosTheme.Typography.monoSmall)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                }
            }
        }
    }

    private func monthAbbr(_ month: Int) -> String {
        let months = ["J","F","M","A","M","J","J","A","S","O","N","D"]
        guard month >= 1 && month <= 12 else { return "?" }
        return months[month - 1]
    }
}
