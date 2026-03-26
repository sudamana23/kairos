import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \KairosYear.year, order: .reverse) private var years: [KairosYear]

    @AppStorage("ouraEnabled") private var ouraEnabled = true
    @AppStorage("healthKitEnabled") private var healthKitEnabled = true

    @State private var showYearWizard = false
    @State private var expandedYears: Set<Int> = []
    @State private var yearToDelete: KairosYear?
    @State private var domainToDelete: KairosDomain?
    @State private var showResetConfirmation = false
    @State private var notificationsAuthorized = false
    @State private var pulseNotifEnabled = true
    @State private var reviewNotifEnabled = true

    // Export / Import
    @State private var exportDocument  = KairosBackupDocument()
    @State private var showExporter    = false
    @State private var showImporter    = false
    @State private var importAlertMsg: String?
    @State private var showImportAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xl) {
                header
                yearSetupSection
                integrationsSection
                yearsSection
                notificationsSection
                dataSection
            }
            .padding(KairosTheme.Spacing.xl)
        }
        .background(KairosTheme.Colors.background)
        .confirmationDialog(
            "Delete \(yearToDelete.map { String($0.year) } ?? "Year")?",
            isPresented: Binding(get: { yearToDelete != nil }, set: { if !$0 { yearToDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete Year & All Data", role: .destructive) {
                if let y = yearToDelete { y.deleteWithChildren(in: modelContext); try? modelContext.save() }
                yearToDelete = nil
            }
            Button("Cancel", role: .cancel) { yearToDelete = nil }
        } message: {
            Text("This permanently deletes all domains, objectives, and key results for this year.")
        }
        .confirmationDialog(
            "Delete \"\(domainToDelete?.name ?? "Domain")\"?",
            isPresented: Binding(get: { domainToDelete != nil }, set: { if !$0 { domainToDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete Domain & All KRs", role: .destructive) {
                if let d = domainToDelete { d.deleteWithChildren(in: modelContext); try? modelContext.save() }
                domainToDelete = nil
            }
            Button("Cancel", role: .cancel) { domainToDelete = nil }
        } message: {
            Text("This permanently deletes all objectives and key results in this domain.")
        }
        .confirmationDialog(
            "Reset All Data?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive) {
                for year in years { year.deleteWithChildren(in: modelContext) }
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes all years, domains, objectives, key results, pulses, and reviews.")
        }
        // MARK: File Exporter
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: exportFilename
        ) { result in
            if case .failure(let error) = result {
                importAlertMsg = "Export failed: \(error.localizedDescription)"
                showImportAlert = true
            }
        }
        // MARK: File Importer
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .failure(let error):
                importAlertMsg = "Could not open file: \(error.localizedDescription)"
                showImportAlert = true
            case .success(let urls):
                guard let url = urls.first else { return }
                performImport(from: url)
            }
        }
        // MARK: Import result / error alert
        .alert("Import", isPresented: $showImportAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importAlertMsg ?? "")
        }
        // MARK: Year Wizard
        .sheet(isPresented: $showYearWizard) {
            YearWizardView()
        }
    }

    // MARK: - Export helpers

    private var exportFilename: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return "kairos-backup-\(f.string(from: Date()))"
    }

    private func triggerExport() {
        do {
            let data = try KairosExportManager.makeBackupData(years: years, context: modelContext)
            exportDocument = KairosBackupDocument(data: data)
            showExporter   = true
        } catch {
            importAlertMsg  = error.localizedDescription
            showImportAlert = true
        }
    }

    private func performImport(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            importAlertMsg  = "Permission denied for this file."
            showImportAlert = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data   = try Data(contentsOf: url)
            let result = try KairosExportManager.importBackup(from: data, into: modelContext)
            importAlertMsg  = result.summary
            showImportAlert = true
        } catch {
            importAlertMsg  = error.localizedDescription
            showImportAlert = true
        }
    }

    // MARK: - Year Setup Section

    private var yearSetupSection: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
            KairosLabel(text: "Year Setup")

            Button {
                showYearWizard = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(KairosTheme.Colors.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Set up a new year")
                            .font(KairosTheme.Typography.body)
                            .foregroundStyle(KairosTheme.Colors.textPrimary)
                        Text("Define domains, objectives, and key results")
                            .font(KairosTheme.Typography.caption)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                }
            }
            .buttonStyle(.plain)
            .padding(KairosTheme.Spacing.md)
            .background(KairosTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
                    .stroke(KairosTheme.Colors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Integrations Section

    private var integrationsSection: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
            KairosLabel(text: "Health Integrations")

            VStack(alignment: .leading, spacing: KairosTheme.Spacing.md) {
                #if os(macOS)
                Toggle(isOn: $ouraEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Oura Ring")
                            .font(KairosTheme.Typography.body)
                            .foregroundStyle(KairosTheme.Colors.textPrimary)
                        Text("Show health panel on dashboard")
                            .font(KairosTheme.Typography.caption)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                    }
                }
                .toggleStyle(.switch)
                #else
                Toggle(isOn: $healthKitEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Health")
                            .font(KairosTheme.Typography.body)
                            .foregroundStyle(KairosTheme.Colors.textPrimary)
                        Text("Show health panel on dashboard")
                            .font(KairosTheme.Typography.caption)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                    }
                }
                .toggleStyle(.switch)
                #endif
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

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
            KairosLabel(text: "Settings")
            Text("Data & Structure")
                .font(KairosTheme.Typography.displayMedium)
                .foregroundStyle(KairosTheme.Colors.textPrimary)
        }
    }

    // MARK: - Years Section

    private var yearsSection: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
            KairosLabel(text: "Years")

            if years.isEmpty {
                Text("No years set up yet.")
                    .font(KairosTheme.Typography.body)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
                    .padding(KairosTheme.Spacing.md)
            } else {
                ForEach(years) { year in
                    YearCard(
                        year: year,
                        isExpanded: expandedYears.contains(year.year),
                        onToggle: {
                            if expandedYears.contains(year.year) {
                                expandedYears.remove(year.year)
                            } else {
                                expandedYears.insert(year.year)
                            }
                        },
                        onDeleteYear: { yearToDelete = year },
                        onDeleteDomain: { domainToDelete = $0 }
                    )
                }
            }
        }
    }

    // MARK: - Data Section

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
            KairosLabel(text: "Notifications")

            VStack(alignment: .leading, spacing: KairosTheme.Spacing.md) {
                if !notificationsAuthorized {
                    HStack(spacing: KairosTheme.Spacing.sm) {
                        Image(systemName: "bell.slash")
                            .font(.caption)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                        Text("Notifications are disabled. Enable them in System Settings → Notifications → Kairos.")
                            .font(KairosTheme.Typography.caption)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                    }
                    Button("Request Permission") {
                        Task {
                            let granted = await NotificationManager.shared.requestPermission()
                            notificationsAuthorized = granted
                            if granted { await NotificationManager.shared.scheduleAll() }
                        }
                    }
                    .buttonStyle(.plain)
                    .font(KairosTheme.Typography.caption)
                    .foregroundStyle(KairosTheme.Colors.accent)
                } else {
                    Toggle(isOn: $pulseNotifEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Weekly Pulse reminder")
                                .font(KairosTheme.Typography.body)
                                .foregroundStyle(KairosTheme.Colors.textPrimary)
                            Text("Every Monday at 9:00 AM")
                                .font(KairosTheme.Typography.caption)
                                .foregroundStyle(KairosTheme.Colors.textMuted)
                        }
                    }
                    .toggleStyle(.switch)
                    .onChange(of: pulseNotifEnabled) { _, on in
                        if on { NotificationManager.shared.scheduleWeeklyPulse() }
                        else  { NotificationManager.shared.cancelWeeklyPulse() }
                    }

                    KairosDivider()

                    Toggle(isOn: $reviewNotifEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Monthly Review reminder")
                                .font(KairosTheme.Typography.body)
                                .foregroundStyle(KairosTheme.Colors.textPrimary)
                            Text("1st of every month at 10:00 AM")
                                .font(KairosTheme.Typography.caption)
                                .foregroundStyle(KairosTheme.Colors.textMuted)
                        }
                    }
                    .toggleStyle(.switch)
                    .onChange(of: reviewNotifEnabled) { _, on in
                        if on { NotificationManager.shared.scheduleMonthlyReview() }
                        else  { NotificationManager.shared.cancelMonthlyReview() }
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
        .task {
            notificationsAuthorized = await NotificationManager.shared.isAuthorized
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: KairosTheme.Spacing.sm) {
            KairosLabel(text: "Data Management")

            VStack(alignment: .leading, spacing: KairosTheme.Spacing.md) {
                dataStatsRow

                KairosDivider()

                // Export
                Button { triggerExport() } label: {
                    HStack {
                        Image(systemName: "arrow.up.doc")
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export Backup")
                                .font(KairosTheme.Typography.body)
                                .foregroundStyle(KairosTheme.Colors.textPrimary)
                            Text("Saves a JSON file with all years, pulses, and reviews")
                                .font(KairosTheme.Typography.caption)
                                .foregroundStyle(KairosTheme.Colors.textMuted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                    }
                }
                .buttonStyle(.plain)

                KairosDivider()

                // Import
                Button { showImporter = true } label: {
                    HStack {
                        Image(systemName: "arrow.down.doc")
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Import Backup")
                                .font(KairosTheme.Typography.body)
                                .foregroundStyle(KairosTheme.Colors.textPrimary)
                            Text("Merges a .json backup — existing items are skipped")
                                .font(KairosTheme.Typography.caption)
                                .foregroundStyle(KairosTheme.Colors.textMuted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                    }
                }
                .buttonStyle(.plain)

                KairosDivider()

                // Reset
                Button { showResetConfirmation = true } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Reset All Data")
                    }
                    .font(KairosTheme.Typography.body)
                    .foregroundStyle(KairosTheme.Colors.status(.blocked))
                }
                .buttonStyle(.plain)
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

    private var dataStatsRow: some View {
        let allKRs = years.flatMap { $0.allKeyResults }
        let allDomains = years.flatMap { $0.domains }
        return HStack(spacing: KairosTheme.Spacing.lg) {
            statPill(value: years.count, label: "Years")
            statPill(value: allDomains.count, label: "Domains")
            statPill(value: allKRs.count, label: "Key Results")
        }
    }

    private func statPill(value: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(KairosTheme.Typography.monoLarge)
                .foregroundStyle(KairosTheme.Colors.textPrimary)
            Text(label)
                .font(KairosTheme.Typography.monoSmall)
                .foregroundStyle(KairosTheme.Colors.textMuted)
        }
    }
}

// MARK: - YearCard

private struct YearCard: View {
    let year: KairosYear
    let isExpanded: Bool
    let onToggle: () -> Void
    let onDeleteYear: () -> Void
    let onDeleteDomain: (KairosDomain) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var editingIntention = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Year header row
            HStack {
                Button(action: onToggle) {
                    HStack(spacing: KairosTheme.Spacing.sm) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                            .frame(width: 14)
                        Text(String(year.year))
                            .font(KairosTheme.Typography.monoLarge)
                            .foregroundStyle(KairosTheme.Colors.textPrimary)
                        Text("·")
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                        Text("\(year.domains.count) domains · \(year.allKeyResults.count) KRs")
                            .font(KairosTheme.Typography.monoSmall)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    onDeleteYear()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                }
                .buttonStyle(.plain)
                .help("Delete \(String(year.year))")
            }
            .padding(KairosTheme.Spacing.md)

            if isExpanded {
                KairosDivider()
                    .padding(.horizontal, KairosTheme.Spacing.md)

                VStack(alignment: .leading, spacing: KairosTheme.Spacing.md) {
                    // Intention field
                    VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                        KairosLabel(text: "Year Intention")
                        TextField("Optional theme or word of the year", text: Binding(
                            get: { year.intention },
                            set: { year.intention = $0; try? year.modelContext?.save() }
                        ))
                        .textFieldStyle(.plain)
                        .font(KairosTheme.Typography.body)
                        .foregroundStyle(KairosTheme.Colors.textPrimary)
                        .padding(KairosTheme.Spacing.sm)
                        .background(KairosTheme.Colors.background)
                        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
                    }

                    // Domains list
                    VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                        KairosLabel(text: "Domains")
                        ForEach(Array(year.sortedDomains.enumerated()), id: \.element.id) { index, domain in
                            DomainEditRow(
                                domain: domain,
                                canMoveUp: index > 0,
                                canMoveDown: index < year.sortedDomains.count - 1,
                                onMoveUp: {
                                    let domains = year.sortedDomains
                                    let prev = domains[index - 1]
                                    let tmp = domain.sortOrder
                                    domain.sortOrder = prev.sortOrder
                                    prev.sortOrder = tmp
                                    try? domain.modelContext?.save()
                                },
                                onMoveDown: {
                                    let domains = year.sortedDomains
                                    let next = domains[index + 1]
                                    let tmp = domain.sortOrder
                                    domain.sortOrder = next.sortOrder
                                    next.sortOrder = tmp
                                    try? domain.modelContext?.save()
                                },
                                onDelete: { onDeleteDomain(domain) }
                            )
                        }
                        Button {
                            let newDomain = KairosDomain(
                                name: "New Domain",
                                emoji: "◆",
                                identityStatement: "",
                                sortOrder: year.domains.count,
                                colorHex: "#6A6A8A"
                            )
                            modelContext.insert(newDomain)
                            year.domains.append(newDomain)
                            try? modelContext.save()
                        } label: {
                            Label("Add domain", systemImage: "plus")
                                .font(KairosTheme.Typography.caption)
                                .foregroundStyle(KairosTheme.Colors.textMuted)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, KairosTheme.Spacing.xs)
                    }
                }
                .padding(KairosTheme.Spacing.md)
            }
        }
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
                .stroke(KairosTheme.Colors.border, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isExpanded)
    }
}

// MARK: - DomainEditRow

private struct DomainEditRow: View {
    let domain: KairosDomain
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    @State private var isExpanded = false

    private var domainColor: Color { KairosTheme.Colors.domain(domain.name) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Compact row
            HStack(spacing: KairosTheme.Spacing.sm) {
                // Emoji edit
                TextField("", text: Binding(
                    get: { domain.emoji },
                    set: { domain.emoji = $0; try? domain.modelContext?.save() }
                ))
                .textFieldStyle(.plain)
                .font(.title3)
                .frame(width: 32)
                .multilineTextAlignment(.center)

                // Name edit
                TextField("Domain name", text: Binding(
                    get: { domain.name },
                    set: { domain.name = $0; try? domain.modelContext?.save() }
                ))
                .textFieldStyle(.plain)
                .font(KairosTheme.Typography.body)
                .foregroundStyle(KairosTheme.Colors.textPrimary)

                Spacer()

                // KR count
                Text("\(domain.allKeyResults.count) KRs")
                    .font(KairosTheme.Typography.monoSmall)
                    .foregroundStyle(KairosTheme.Colors.textMuted)

                // Expand toggle (for identity statement)
                Button {
                    withAnimation(.easeInOut(duration: 0.12)) { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                }
                .buttonStyle(.plain)

                // Reorder
                HStack(spacing: 2) {
                    Button(action: onMoveUp) {
                        Image(systemName: "arrow.up")
                            .font(.caption2)
                            .foregroundStyle(canMoveUp ? KairosTheme.Colors.textMuted : KairosTheme.Colors.border)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canMoveUp)

                    Button(action: onMoveDown) {
                        Image(systemName: "arrow.down")
                            .font(.caption2)
                            .foregroundStyle(canMoveDown ? KairosTheme.Colors.textMuted : KairosTheme.Colors.border)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canMoveDown)
                }

                // Delete
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption2)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                }
                .buttonStyle(.plain)
                .help("Delete \(domain.name)")
            }
            .padding(.horizontal, KairosTheme.Spacing.sm)
            .padding(.vertical, KairosTheme.Spacing.xs)

            // Expanded: identity statement
            if isExpanded {
                VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                    KairosLabel(text: "Identity Statement")
                    TextField("\"I am someone who…\"", text: Binding(
                        get: { domain.identityStatement },
                        set: { domain.identityStatement = $0; try? domain.modelContext?.save() }
                    ), axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(KairosTheme.Typography.body)
                    .foregroundStyle(KairosTheme.Colors.textSecondary)
                    .lineLimit(2...)
                    .padding(KairosTheme.Spacing.sm)
                    .background(KairosTheme.Colors.background)
                    .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))

                    KairosLabel(text: "Objectives (\(domain.objectives.count))")
                        .padding(.top, KairosTheme.Spacing.xs)

                    ForEach(domain.sortedObjectives) { obj in
                        ObjectiveEditRow(objective: obj)
                    }
                }
                .padding(.horizontal, KairosTheme.Spacing.sm)
                .padding(.bottom, KairosTheme.Spacing.sm)
            }
        }
        .background(KairosTheme.Colors.surfaceElevated.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: KairosTheme.Radius.sm)
                .stroke(domainColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - ObjectiveEditRow

private struct ObjectiveEditRow: View {
    @Environment(\.modelContext) private var modelContext
    let objective: KairosObjective

    @State private var confirmDelete = false

    var body: some View {
        HStack(spacing: KairosTheme.Spacing.sm) {
            Image(systemName: "circle")
                .font(.caption2)
                .foregroundStyle(KairosTheme.Colors.textMuted)

            TextField("Objective", text: Binding(
                get: { objective.title },
                set: { objective.title = $0; try? objective.modelContext?.save() }
            ))
            .textFieldStyle(.plain)
            .font(KairosTheme.Typography.caption)
            .foregroundStyle(KairosTheme.Colors.textSecondary)

            Spacer()

            Text("\(objective.keyResults.count) KRs")
                .font(KairosTheme.Typography.monoSmall)
                .foregroundStyle(KairosTheme.Colors.textMuted)

            Button {
                confirmDelete = true
            } label: {
                Image(systemName: "trash")
                    .font(.caption2)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
            }
            .buttonStyle(.plain)
            .confirmationDialog(
                "Delete \"\(objective.title)\"?",
                isPresented: $confirmDelete,
                titleVisibility: .visible
            ) {
                Button("Delete Objective & KRs", role: .destructive) {
                    objective.deleteWithChildren(in: modelContext)
                    try? modelContext.save()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes \(objective.keyResults.count) key result(s).")
            }
        }
        .padding(.horizontal, KairosTheme.Spacing.sm)
        .padding(.vertical, 3)
    }
}
