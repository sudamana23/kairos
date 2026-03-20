import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Custom drag types

extension UTType {
    /// In-app domain-card reorder
    static let kairosDomainDrop = UTType(exportedAs: "com.damianspendel.kairos.domain-drop")
    /// In-app KR move between domains
    static let kairosKRDrop = UTType(exportedAs: "com.damianspendel.kairos.kr-drop")
}

struct DomainDrop: Codable, Transferable {
    let domainName: String
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .kairosDomainDrop)
    }
}

struct KRDrop: Codable, Transferable {
    let krID: String  // UUID string of the KairosKeyResult
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .kairosKRDrop)
    }
}

// MARK: - DashboardView

struct DashboardView: View {
    /// Called when the user taps a domain tile — parent updates sidebar selection
    var navigate: (KairosRoute) -> Void = { _ in }

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \KairosYear.year, order: .reverse) private var years: [KairosYear]
    @Query private var allKeyResults: [KairosKeyResult]
    @Query(sort: \KairosWeeklyPulse.date, order: .reverse) private var pulses: [KairosWeeklyPulse]

    @State private var selectedYear = 2026
    @State private var showingWizard = false

    // AI year summary
    @ObservedObject private var intelligence = IntelligenceManager.shared
    @State private var yearSummary: String?
    @State private var isSummaryLoading = false

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
                    HealthPanel()
                    domainGrid(for: year)
                } else {
                    emptyState
                }
            }
            .padding(KairosTheme.Spacing.xl)
        }
        .background(KairosTheme.Colors.background)
        .sheet(isPresented: $showingWizard) { YearWizardView() }
        .task(id: selectedYear) {
            guard let year = currentYear else { return }
            await generateYearSummary(for: year)
        }
    }

    // MARK: - AI Summary

    private func generateYearSummary(for year: KairosYear) async {
        let fallback = computedSummary(for: year)

        // Show stored summary if it was generated this calendar month
        let now = Date()
        let currentMonthKey = Calendar.current.component(.year, from: now) * 100
                            + Calendar.current.component(.month, from: now)
        if !year.aiSummary.isEmpty && year.aiSummaryGeneratedMonth == currentMonthKey {
            yearSummary = year.aiSummary
            return
        }

        guard intelligence.isUsingAI else {
            yearSummary = fallback
            return
        }

        isSummaryLoading = true
        yearSummary = year.aiSummary.isEmpty ? nil : year.aiSummary   // show stale while loading
        let ctx = intelligence.buildContext(from: year, pulses: Array(pulses.prefix(4)))
        let prompt = """
        In exactly one sentence (max 18 words), what is the single sharpest insight about this \
        person's year so far? Be specific, not generic.
        """
        do {
            let result = try await intelligence.engine.complete(prompt: prompt, context: ctx)
            year.aiSummary = result
            year.aiSummaryGeneratedMonth = currentMonthKey
            yearSummary = result
        } catch {
            yearSummary = year.aiSummary.isEmpty ? fallback : year.aiSummary
        }
        isSummaryLoading = false
    }

    private func computedSummary(for year: KairosYear) -> String {
        let pct      = Int(year.overallProgress * 100)
        let onTrack  = year.sortedDomains.filter { $0.progress >= 0.5 }.count
        let total    = year.sortedDomains.count
        let blocked  = year.allKeyResults.filter { $0.currentStatus == .blocked }.count
        var parts: [String] = ["\(pct)% complete"]
        if total > 0 { parts.append("\(onTrack)/\(total) domains on track") }
        if blocked > 0 { parts.append("\(blocked) KRs blocked") }
        return parts.joined(separator: " · ")
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                HStack(spacing: KairosTheme.Spacing.sm) {
                    ForEach(years.prefix(3), id: \.id) { y in
                        Button {
                            selectedYear = y.year
                            yearSummary = nil
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
                // AI year summary
                if let summary = yearSummary {
                    Text(summary)
                        .font(KairosTheme.Typography.body)
                        .foregroundStyle(KairosTheme.Colors.accent.opacity(0.9))
                        .italic()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else if isSummaryLoading {
                    Text("Analyzing…")
                        .font(KairosTheme.Typography.caption)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                        .italic()
                }
            }
            Spacer()
            HStack(spacing: KairosTheme.Spacing.sm) {
                Text(monthLabel)
                    .font(KairosTheme.Typography.mono)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
                Button {
                    showingWizard = true
                } label: {
                    Image(systemName: "plus.circle")
                        .font(KairosTheme.Typography.body)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                }
                .buttonStyle(.plain)
                .help("Set up a new year")
            }
        }
        .animation(.easeInOut(duration: 0.3), value: yearSummary)
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
                DomainCard(
                    domain: domain,
                    onSwap: { sourceName, targetName in
                        guard
                            let src = year.sortedDomains.first(where: { $0.name == sourceName }),
                            let tgt = year.sortedDomains.first(where: { $0.name == targetName })
                        else { return }
                        let tmp = src.sortOrder
                        src.sortOrder = tgt.sortOrder
                        tgt.sortOrder = tmp
                    },
                    onReceiveKR: { krID in
                        moveKR(id: krID, toDomain: domain)
                    },
                    onTap: {
                        navigate(.domain(domain.name))
                    }
                )
            }
        }
    }

    // MARK: - Move KR between domains

    private func moveKR(id krID: String, toDomain target: KairosDomain) {
        guard
            let uuid = UUID(uuidString: krID),
            let kr = allKeyResults.first(where: { $0.id == uuid }),
            kr.objective?.domain?.id != target.id
        else { return }

        // Find or create an objective in the target domain
        let targetObj: KairosObjective
        if let existing = target.sortedObjectives.first {
            targetObj = existing
        } else {
            let newObj = KairosObjective(
                title: kr.objective?.title ?? "General",
                sortOrder: 0
            )
            modelContext.insert(newObj)
            target.objectives.append(newObj)
            targetObj = newObj
        }
        kr.objective = targetObj
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: KairosTheme.Spacing.lg) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 36))
                .foregroundStyle(KairosTheme.Colors.textMuted)
            Text(verbatim: "\(selectedYear) isn't set up yet")
                .font(KairosTheme.Typography.headline)
                .foregroundStyle(KairosTheme.Colors.textMuted)
            Button {
                showingWizard = true
            } label: {
                Label(String("Set up \(selectedYear)"), systemImage: "sparkles")
                    .font(KairosTheme.Typography.headline)
                    .foregroundStyle(KairosTheme.Colors.background)
                    .padding(.horizontal, KairosTheme.Spacing.lg)
                    .padding(.vertical, KairosTheme.Spacing.sm)
                    .background(KairosTheme.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
    }
}

// MARK: - DomainCard

struct DomainCard: View {
    let domain: KairosDomain
    let onSwap: (String, String) -> Void
    let onReceiveKR: (String) -> Void
    var onTap: (() -> Void)? = nil

    @State private var isHovered = false
    @State private var isDropTarget = false

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

            krDots

            Spacer(minLength: 0)

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
                .stroke(
                    isDropTarget ? KairosTheme.Colors.accent :
                    (isHovered ? domainColor.opacity(0.5) : KairosTheme.Colors.border),
                    lineWidth: isDropTarget ? 2 : 1
                )
        )
        .scaleEffect(isDropTarget ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.12), value: isDropTarget)
        .onHover { isHovered = $0 }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        // Domain card reorder — drag this card
        .draggable(DomainDrop(domainName: domain.name)) {
            HStack(spacing: 6) {
                Text(domain.emoji)
                Text(domain.name.uppercased())
                    .font(KairosTheme.Typography.monoSmall)
                    .tracking(1.2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(KairosTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
        }
        // Accept domain card reorder drops
        .dropDestination(for: DomainDrop.self) { items, _ in
            guard let sourceName = items.first?.domainName,
                  sourceName != domain.name
            else { return false }
            onSwap(sourceName, domain.name)
            return true
        } isTargeted: { targeted in
            isDropTarget = targeted
        }
        // Accept KR drops from DomainDetailView
        .dropDestination(for: KRDrop.self) { items, _ in
            guard let krID = items.first?.krID else { return false }
            onReceiveKR(krID)
            return true
        } isTargeted: { targeted in
            if targeted { isDropTarget = true }
            else if !targeted { isDropTarget = false }
        }
    }

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
