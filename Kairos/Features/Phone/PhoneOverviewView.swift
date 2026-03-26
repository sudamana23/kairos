import SwiftUI
import SwiftData

// MARK: - PhoneOverviewView
// iPhone overview tab: year intention, domain progress, KR list.

struct PhoneOverviewView: View {
    @Query(sort: \KairosYear.year, order: .reverse) private var allYears: [KairosYear]
    private var years: [KairosYear] { allYears.filter { !$0.isArchived } }
    // Ensures live re-render when CloudKit delivers remote deletions.
    private var _sync: Int { CloudKitSyncMonitor.shared.remoteChangeToken }

    private var currentYear: KairosYear? { years.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.lg) {
                if let year = currentYear {
                    yearHeader(year)
                    ForEach(year.sortedDomains) { domain in
                        PhoneDomainCard(domain: domain)
                    }
                } else {
                    emptyState
                }
            }
            .padding(KairosTheme.Spacing.md)
        }
        .background(KairosTheme.Colors.background.ignoresSafeArea())
        .navigationTitle("Overview")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }

    private func yearHeader(_ year: KairosYear) -> some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
            Text(String(year.year))
                .font(KairosTheme.Typography.monoLarge)
                .foregroundStyle(KairosTheme.Colors.textPrimary)
            if !year.intention.isEmpty {
                Text(year.intention)
                    .font(KairosTheme.Typography.body)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
                    .italic()
            }
            // Overall progress bar
            let progress = year.sortedDomains.isEmpty ? 0.0 :
                year.sortedDomains.map(\.progress).reduce(0, +) / Double(year.sortedDomains.count)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(KairosTheme.Colors.border)
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(KairosTheme.Colors.accent)
                        .frame(width: geo.size.width * progress, height: 3)
                }
            }
            .frame(height: 3)
            .padding(.top, KairosTheme.Spacing.xs)
            Text("\(Int(progress * 100))% complete across \(year.sortedDomains.count) domains")
                .font(KairosTheme.Typography.monoSmall)
                .foregroundStyle(KairosTheme.Colors.textMuted)
        }
        .padding(KairosTheme.Spacing.md)
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
            .stroke(KairosTheme.Colors.border, lineWidth: 1))
    }

    private var emptyState: some View {
        VStack(spacing: KairosTheme.Spacing.md) {
            Text("No year set up yet.")
                .font(KairosTheme.Typography.body)
                .foregroundStyle(KairosTheme.Colors.textMuted)
            Text("Go to Settings to set up your year.")
                .font(KairosTheme.Typography.caption)
                .foregroundStyle(KairosTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(KairosTheme.Spacing.xxl)
    }
}

// MARK: - PhoneDomainCard

private struct PhoneDomainCard: View {
    let domain: KairosDomain
    @State private var isExpanded = true

    private var domainColor: Color { KairosTheme.Colors.domain(domain.name) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Domain header
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: KairosTheme.Spacing.sm) {
                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(KairosTheme.Colors.border, lineWidth: 2.5)
                        Circle()
                            .trim(from: 0, to: domain.progress)
                            .stroke(domainColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(domain.name)
                            .font(KairosTheme.Typography.headline)
                            .foregroundStyle(KairosTheme.Colors.textPrimary)
                        Text("\(domain.allKeyResults.count) key results · \(Int(domain.progress * 100))%")
                            .font(KairosTheme.Typography.monoSmall)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                }
                .padding(KairosTheme.Spacing.md)
            }
            .buttonStyle(.plain)

            // Objectives + KRs
            if isExpanded {
                KairosDivider().padding(.horizontal, KairosTheme.Spacing.md)
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(domain.sortedObjectives.filter { !$0.isArchived }) { obj in
                        PhoneObjectiveRow(objective: obj, domainColor: domainColor)
                    }
                }
                .padding(.bottom, KairosTheme.Spacing.xs)
            }
        }
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
            .stroke(domainColor.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - PhoneObjectiveRow

private struct PhoneObjectiveRow: View {
    let objective: KairosObjective
    let domainColor: Color
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.12)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: KairosTheme.Spacing.sm) {
                    Circle()
                        .fill(domainColor.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .padding(.leading, KairosTheme.Spacing.md)

                    Text(objective.title)
                        .font(KairosTheme.Typography.body)
                        .foregroundStyle(KairosTheme.Colors.textSecondary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    let activeKRs = objective.keyResults.filter { !$0.isArchived }
                    let doneKRs   = activeKRs.filter { $0.currentStatus == .done }
                    Text("\(doneKRs.count)/\(activeKRs.count)")
                        .font(KairosTheme.Typography.monoSmall)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                        .padding(.trailing, KairosTheme.Spacing.sm)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9))
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                        .padding(.trailing, KairosTheme.Spacing.md)
                }
                .padding(.vertical, KairosTheme.Spacing.sm)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(objective.keyResults.filter { !$0.isArchived }) { kr in
                        PhoneKRRow(kr: kr, domainColor: domainColor)
                    }
                }
            }
        }
    }
}

// MARK: - PhoneKRRow

private struct PhoneKRRow: View {
    let kr: KairosKeyResult
    let domainColor: Color

    var body: some View {
        HStack(spacing: KairosTheme.Spacing.sm) {
            Image(systemName: kr.currentStatus == .done ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundStyle(kr.currentStatus == .done ? domainColor : KairosTheme.Colors.border)
                .padding(.leading, KairosTheme.Spacing.xl)

            Text(kr.title)
                .font(KairosTheme.Typography.caption)
                .foregroundStyle(kr.currentStatus == .done
                    ? KairosTheme.Colors.textMuted
                    : KairosTheme.Colors.textSecondary)
                .strikethrough(kr.currentStatus == .done, color: KairosTheme.Colors.textMuted)
                .multilineTextAlignment(.leading)

            Spacer()

            StatusPill(status: kr.currentStatus)
                .padding(.trailing, KairosTheme.Spacing.md)
        }
        .padding(.vertical, 6)
    }
}
