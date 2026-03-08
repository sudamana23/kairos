import SwiftUI
import SwiftData

struct DomainDetailView: View {
    let domainName: String

    @Environment(\.modelContext) private var modelContext
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
                    isExpanded: expandedObjective == objective.id,
                    moveDomainTargets: otherDomains,
                    allDomains: allDomains,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedObjective = expandedObjective == objective.id ? nil : objective.id
                        }
                    },
                    onMoveObjectiveTo: { target in
                        moveObjective(objective: objective, toDomain: target)
                    },
                    onMoveKRToObjective: { kr, obj in kr.objective = obj },
                    onDelete: {
                        modelContext.delete(objective)
                        try? modelContext.save()
                    },
                    onAddKR: {
                        let newKR = KairosKeyResult(
                            title: "New key result",
                            sortOrder: objective.keyResults.count
                        )
                        modelContext.insert(newKR)
                        objective.keyResults.append(newKR)
                        try? modelContext.save()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedObjective = objective.id
                        }
                    }
                )
            }

            // Add Objective button
            Button {
                let newObj = KairosObjective(
                    title: "New Objective",
                    sortOrder: domain.objectives.count
                )
                modelContext.insert(newObj)
                domain.objectives.append(newObj)
                try? modelContext.save()
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedObjective = newObj.id
                }
            } label: {
                HStack(spacing: KairosTheme.Spacing.xs) {
                    Image(systemName: "plus.circle")
                    Text("Add objective")
                }
                .font(KairosTheme.Typography.caption)
                .foregroundStyle(KairosTheme.Colors.textMuted)
            }
            .buttonStyle(.plain)
            .padding(.top, KairosTheme.Spacing.xs)
        }
    }

    private var otherDomains: [KairosDomain] {
        guard let year = years.first(where: { $0.year == selectedYear }) else { return [] }
        return year.sortedDomains.filter { $0.name != domainName }
    }

    private var allDomains: [KairosDomain] {
        years.first(where: { $0.year == selectedYear })?.sortedDomains ?? []
    }

    private func moveObjective(objective: KairosObjective, toDomain target: KairosDomain) {
        objective.domain = target
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
    let isExpanded: Bool
    let moveDomainTargets: [KairosDomain]
    let allDomains: [KairosDomain]
    let onTap: () -> Void
    let onMoveObjectiveTo: (KairosDomain) -> Void
    let onMoveKRToObjective: (KairosKeyResult, KairosObjective) -> Void
    var onDelete: (() -> Void)? = nil
    var onAddKR: (() -> Void)? = nil

    @State private var confirmDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            objectiveHeader
            if isExpanded {
                KairosDivider()
                krList
            }
        }
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
                .stroke(KairosTheme.Colors.border, lineWidth: 1)
        )
        // Right-click context menu — all actions in one place
        .contextMenu {
            if !moveDomainTargets.isEmpty {
                Menu("Move objective to…") {
                    ForEach(moveDomainTargets) { domain in
                        Button {
                            onMoveObjectiveTo(domain)
                        } label: {
                            Label("\(domain.emoji) \(domain.name)", systemImage: "arrow.right")
                        }
                    }
                }
                Divider()
            }
            if onDelete != nil {
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label("Delete Objective", systemImage: "trash")
                }
            }
        }
        .confirmationDialog(
            "Delete \"\(objective.title)\"?",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Objective & KRs", role: .destructive) { onDelete?() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Permanently deletes \(objective.keyResults.count) key result(s).")
        }
    }

    // MARK: Header
    //
    // KEY FIX: the header is NOT wrapped in a Button. Instead, only the left
    // portion (title + subtitle) carries the tap-to-expand gesture. This lets
    // the right-side action buttons and menus receive their own clicks cleanly.

    private var objectiveHeader: some View {
        HStack(spacing: KairosTheme.Spacing.sm) {

            // Left tap area → expand / collapse
            VStack(alignment: .leading, spacing: 2) {
                TextField("Objective", text: Binding(
                    get: { objective.title },
                    set: { objective.title = $0; try? objective.modelContext?.save() }
                ))
                .textFieldStyle(.plain)
                .font(KairosTheme.Typography.headline)
                .foregroundStyle(KairosTheme.Colors.textPrimary)

                Text(objective.keyResults.count == 1
                     ? "1 key result"
                     : "\(objective.keyResults.count) key results")
                    .font(KairosTheme.Typography.caption)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
            }
            .contentShape(Rectangle())
            .onTapGesture { onTap() }

            Spacer()

            // KR status mini-strip
            HStack(spacing: 2) {
                ForEach(objective.sortedKeyResults) { kr in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(KairosTheme.Colors.status(kr.currentStatus))
                        .frame(width: 12, height: 6)
                }
            }

            // Move button — clear label so it's discoverable
            if !moveDomainTargets.isEmpty {
                Menu {
                    ForEach(moveDomainTargets) { domain in
                        Button {
                            onMoveObjectiveTo(domain)
                        } label: {
                            Label("\(domain.emoji) \(domain.name)", systemImage: "arrow.right")
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.right.circle")
                        Text("Move")
                    }
                    .font(KairosTheme.Typography.caption)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            // Delete button — always visible
            if onDelete != nil {
                Button {
                    confirmDelete = true
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                }
                .buttonStyle(.plain)
                .help("Delete objective")
            }

            // Chevron
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption)
                .foregroundStyle(KairosTheme.Colors.textMuted)
                .onTapGesture { onTap() }
        }
        .padding(KairosTheme.Spacing.md)
    }

    // MARK: KR List

    private var krList: some View {
        VStack(spacing: 0) {
            ForEach(objective.sortedKeyResults) { kr in
                KeyResultRow(
                    kr: kr,
                    allDomains: allDomains,
                    onMoveKRToObjective: onMoveKRToObjective
                )
                if kr.id != objective.sortedKeyResults.last?.id {
                    KairosDivider().padding(.leading, KairosTheme.Spacing.md)
                }
            }
            // Add KR row
            if let onAddKR {
                KairosDivider()
                Button(action: onAddKR) {
                    HStack(spacing: KairosTheme.Spacing.xs) {
                        Image(systemName: "plus")
                            .font(.caption2)
                        Text("Add key result")
                            .font(KairosTheme.Typography.caption)
                    }
                    .foregroundStyle(KairosTheme.Colors.textMuted)
                    .padding(.horizontal, KairosTheme.Spacing.md)
                    .padding(.vertical, KairosTheme.Spacing.sm)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - KeyResultRow

struct KeyResultRow: View {
    let kr: KairosKeyResult
    let allDomains: [KairosDomain]
    let onMoveKRToObjective: (KairosKeyResult, KairosObjective) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var confirmDelete = false

    // MARK: - Entry helpers

    private var currentEntry: KairosMonthlyEntry? {
        let cal = Calendar.current
        let now = Date()
        return kr.entries.first {
            $0.year == cal.component(.year, from: now) &&
            $0.month == cal.component(.month, from: now)
        }
    }

    @discardableResult
    private func getOrCreateEntry() -> KairosMonthlyEntry {
        if let e = currentEntry { return e }
        let cal = Calendar.current
        let now = Date()
        let e = KairosMonthlyEntry(
            year: cal.component(.year, from: now),
            month: cal.component(.month, from: now),
            status: kr.currentStatus,
            rating: kr.latestRating,
            commentary: kr.latestCommentary
        )
        modelContext.insert(e)
        kr.entries.append(e)
        return e
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: KairosTheme.Spacing.md) {
            // Status colour bar
            RoundedRectangle(cornerRadius: 1)
                .fill(KairosTheme.Colors.status(kr.currentStatus))
                .frame(width: 3)
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                // Title + action row
                HStack {
                    // Editable title
                    TextField("Key result", text: Binding(
                        get: { kr.title },
                        set: { kr.title = $0; try? kr.modelContext?.save() }
                    ))
                    .textFieldStyle(.plain)
                    .font(KairosTheme.Typography.body)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)

                    Spacer()

                    // Status pill (menu)
                    Menu {
                        ForEach(KRStatus.allCases, id: \.self) { status in
                            Button {
                                getOrCreateEntry().statusEnum = status
                            } label: {
                                HStack {
                                    if status == kr.currentStatus {
                                        Image(systemName: "checkmark")
                                    }
                                    Text(status.displayName)
                                }
                            }
                        }
                    } label: {
                        StatusPill(status: kr.currentStatus)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()

                    // Rating stars
                    ratingStars

                    // Move KR menu — labelled for discoverability
                    if !krMoveGroups.isEmpty {
                        Menu {
                            ForEach(krMoveGroups, id: \.domain.id) { group in
                                Section("\(group.domain.emoji) \(group.domain.name)") {
                                    ForEach(group.objectives) { obj in
                                        Button(obj.title) { onMoveKRToObjective(kr, obj) }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.right.circle")
                                Text("Move")
                            }
                            .font(KairosTheme.Typography.caption)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                    }

                    // Delete button — always visible
                    Button {
                        confirmDelete = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                    }
                    .buttonStyle(.plain)
                    .help("Delete key result")
                }

                // Commentary
                TextField("Add notes…", text: Binding(
                    get: { kr.latestCommentary },
                    set: { getOrCreateEntry().commentary = $0 }
                ), axis: .vertical)
                .font(KairosTheme.Typography.caption)
                .foregroundStyle(KairosTheme.Colors.textSecondary)
                .italic()
                .lineLimit(1...)
                .textFieldStyle(.plain)

                monthlyHistory
            }
        }
        .padding(.horizontal, KairosTheme.Spacing.md)
        .padding(.vertical, KairosTheme.Spacing.sm)
        // Right-click context menu — all actions in one place
        .contextMenu {
            if !krMoveGroups.isEmpty {
                Menu("Move to…") {
                    ForEach(krMoveGroups, id: \.domain.id) { group in
                        Section("\(group.domain.emoji) \(group.domain.name)") {
                            ForEach(group.objectives) { obj in
                                Button(obj.title) { onMoveKRToObjective(kr, obj) }
                            }
                        }
                    }
                }
                Divider()
            }
            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                Label("Delete Key Result", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "Delete this key result?",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                modelContext.delete(kr)
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\"\(kr.title)\" and all its monthly entries will be removed.")
        }
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

    // MARK: - Move groups helper

    private var krMoveGroups: [(domain: KairosDomain, objectives: [KairosObjective])] {
        allDomains.compactMap { domain in
            let objs = domain.sortedObjectives.filter { $0.id != kr.objective?.id }
            return objs.isEmpty ? nil : (domain: domain, objectives: objs)
        }
    }

    // MARK: - Rating stars

    private var ratingStars: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= kr.latestRating ? "star.fill" : "star")
                    .font(.system(size: 8))
                    .foregroundStyle(i <= kr.latestRating ? Color(hex: "#DAB25A") : KairosTheme.Colors.border)
                    .onTapGesture {
                        getOrCreateEntry().rating = (kr.latestRating == i ? 0 : i)
                    }
            }
        }
    }

    // MARK: - Monthly history

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
        ["J","F","M","A","M","J","J","A","S","O","N","D"][safe: month - 1] ?? "?"
    }
}

// MARK: - Safe array subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
