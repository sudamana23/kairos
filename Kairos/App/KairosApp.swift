import SwiftUI
import SwiftData

@main
struct KairosApp: App {
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            KairosYear.self,
            KairosDomain.self,
            KairosObjective.self,
            KairosKeyResult.self,
            KairosMonthlyEntry.self,
            KairosWeeklyPulse.self,
            KairosMonthlyReview.self,
            KairosValue.self
        ])
        modelContainer = Self.makeContainer(schema: schema)
    }

    // MARK: - Local store (no CloudKit — import/export via iCloud Drive is the backup mechanism)

    private static var storeURL: URL = {
        let fm = FileManager.default
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appending(path: "com.damianspendel.kairos", directoryHint: .isDirectory)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appending(path: "kairos.store", directoryHint: .notDirectory)
    }()

    private static func makeContainer(schema: Schema) -> ModelContainer {
        let config = ModelConfiguration(url: storeURL, cloudKitDatabase: .none)
        if let c = try? ModelContainer(for: schema, configurations: config) {
            return c
        }
        // Store unreadable — reset and try again
        let fm = FileManager.default
        for ext in ["", "-wal", "-shm"] {
            try? fm.removeItem(at: URL(fileURLWithPath: storeURL.path + ext))
        }
        return try! ModelContainer(for: schema, configurations: config)
    }

    var body: some Scene {
        WindowGroup {
            RootContainerView()
                .modelContainer(modelContainer)
                .task {
                    let granted = await NotificationManager.shared.requestPermission()
                    if granted { await NotificationManager.shared.scheduleAll() }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1280, height: 820)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .undoRedo) {}
        }
    }
}

// MARK: - RootContainerView

struct RootContainerView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isDarkMode") private var isDarkMode = true
    @Query private var years: [KairosYear]
    // Session-only flag: set to true the moment the user taps "Continue to the app"
    // so that years.isEmpty can't loop the onboarding back within the same launch.
    @State private var forceShowApp = false

    private var shouldOnboard: Bool {
        !forceShowApp && (!hasCompletedOnboarding || years.isEmpty)
    }

    var body: some View {
        Group {
            if shouldOnboard {
                OnboardingView {
                    hasCompletedOnboarding = true
                    forceShowApp = true
                }
                .frame(minWidth: 600, minHeight: 500)
            } else {
                AppRootView()
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear { KairosTheme.Colors.isDark = isDarkMode }
        .onChange(of: isDarkMode) { _, v in KairosTheme.Colors.isDark = v }
    }
}

// MARK: - AppRootView

struct AppRootView: View {
    @State private var selection: KairosRoute? = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @AppStorage("isDarkMode") private var isDarkMode = true

    var body: some View {
        splitView
    }

    // MARK: Sidebar split (iPad / Mac)
    private var splitView: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            KairosSidebar(selection: $selection)
                .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 250)
        } detail: {
            ZStack {
                KairosTheme.Colors.background.ignoresSafeArea()
                routeView(for: selection ?? .dashboard)
            }
        }
        .background(KairosTheme.Colors.background)
    }

    @ViewBuilder
    private func routeView(for route: KairosRoute) -> some View {
        switch route {
        case .dashboard:        DashboardView(navigate: { selection = $0 })
        case .values:           ValuesView()
        case .pulse:            PulseView()
        case .review:           ReviewView()
        case .timeMachine:      TimeMachineView()
        case .domain(let name): DomainDetailView(domainName: name)
        case .settings:         SettingsView()
        }
    }

}

// MARK: - KairosRoute

enum KairosRoute: Hashable {
    case dashboard
    case values
    case pulse
    case review
    case timeMachine
    case domain(String)
    case settings
}

// MARK: - DomainValueDrop

struct DomainValueDrop: Transferable, Codable {
    let domainID: String
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .kairosDomainDrop)
    }
}

// MARK: - KairosSidebar

struct KairosSidebar: View {
    @Binding var selection: KairosRoute?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \KairosYear.year, order: .reverse) private var years: [KairosYear]
    @Query private var allKeyResults: [KairosKeyResult]
    @Query(sort: \KairosValue.sortOrder) private var values: [KairosValue]
    @AppStorage("isDarkMode") private var isDarkMode = true

    private var current2026: KairosYear? { years.first { $0.year == 2026 } }

    var body: some View {
        List(selection: $selection) {

            // MARK: Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TENETS")
                        .font(KairosTheme.Typography.monoLarge)
                        .foregroundStyle(KairosTheme.Colors.textPrimary)
                        .tracking(3)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    if let intention = current2026?.intention, !intention.isEmpty {
                        Text(intention)
                            .font(KairosTheme.Typography.monoSmall)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                            .italic()
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Button {
                    isDarkMode.toggle()
                    KairosTheme.Colors.isDark = isDarkMode
                } label: {
                    Image(systemName: isDarkMode ? "sun.max" : "moon")
                        .font(.caption)
                        .foregroundStyle(isDarkMode ? Color(hex: "#FFD60A") : Color(hex: "#4A4A7A"))
                }
                .buttonStyle(.plain)
                .help(isDarkMode ? "Switch to light mode" : "Switch to dark mode")
            }
            .padding(.vertical, KairosTheme.Spacing.sm)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            // MARK: Core
            Section {
                Label("Dashboard", systemImage: "square.grid.2x2")
                    .tag(KairosRoute.dashboard)
                Label("Values", systemImage: "sparkles")
                    .tag(KairosRoute.values)
                Label("Weekly Pulse", systemImage: "waveform")
                    .tag(KairosRoute.pulse)
                Label("Monthly Review", systemImage: "bubble.left.and.bubble.right")
                    .tag(KairosRoute.review)
            }
            .listRowBackground(Color.clear)

            // MARK: Domains — grouped by value
            // Each value is a full-width list row (drop target for domain reassignment).
            // Domains appear as indented rows beneath their value.
            if let year = current2026 {
                if !values.isEmpty {
                    Section {
                        ForEach(values) { value in
                            // Value row — full-width drop target
                            HStack(spacing: KairosTheme.Spacing.sm) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: value.colorHex).opacity(0.8))
                                    .frame(width: 3, height: 14)
                                Text(value.name.uppercased())
                                    .font(KairosTheme.Typography.monoSmall)
                                    .foregroundStyle(KairosTheme.Colors.textMuted)
                                    .tracking(1)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .dropDestination(for: DomainValueDrop.self) { items, _ in
                                guard let item = items.first else { return false }
                                assignDomain(id: item.domainID, toValue: value)
                                return true
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)

                            // Domain children under this value
                            ForEach(year.sortedDomains.filter { $0.value?.id == value.id }) { domain in
                                domainRow(domain).padding(.leading, KairosTheme.Spacing.sm)
                            }
                        }

                        // Unassigned domains
                        let unassigned = year.sortedDomains.filter { $0.value == nil }
                        if !unassigned.isEmpty {
                            HStack(spacing: KairosTheme.Spacing.sm) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(KairosTheme.Colors.border)
                                    .frame(width: 3, height: 14)
                                Text("UNASSIGNED")
                                    .font(KairosTheme.Typography.monoSmall)
                                    .foregroundStyle(KairosTheme.Colors.textMuted)
                                    .tracking(1)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .dropDestination(for: DomainValueDrop.self) { items, _ in
                                guard let item = items.first else { return false }
                                assignDomain(id: item.domainID, toValue: nil)
                                return true
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)

                            ForEach(unassigned) { domain in
                                domainRow(domain).padding(.leading, KairosTheme.Spacing.sm)
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                } else {
                    // No values defined yet — flat domain list under year header
                    Section(String(year.year)) {
                        ForEach(year.sortedDomains) { domain in domainRow(domain) }
                    }
                    .listRowBackground(Color.clear)
                }
            }

            // MARK: Analysis
            Section("Analysis") {
                Label("Time Machine", systemImage: "clock.arrow.circlepath")
                    .tag(KairosRoute.timeMachine)
            }
            .listRowBackground(Color.clear)

            // MARK: Settings
            Section {
                Label("Settings", systemImage: "slider.horizontal.3")
                    .tag(KairosRoute.settings)
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(KairosTheme.Colors.surface)
        .foregroundStyle(KairosTheme.Colors.textPrimary)
    }

    // MARK: - Domain row helper

    @ViewBuilder
    private func domainRow(_ domain: KairosDomain) -> some View {
        HStack(spacing: KairosTheme.Spacing.sm) {
            Text(domain.name)
                .foregroundStyle(KairosTheme.Colors.textPrimary)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
            Spacer()
            ZStack {
                Circle()
                    .stroke(KairosTheme.Colors.border, lineWidth: 2)
                Circle()
                    .trim(from: 0, to: domain.progress)
                    .stroke(KairosTheme.Colors.domain(domain.name), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 16, height: 16)
        }
        .tag(KairosRoute.domain(domain.name))
        .draggable(DomainValueDrop(domainID: domain.id.uuidString))
        .dropDestination(for: KRDrop.self) { items, _ in
            guard let krID = items.first?.krID else { return false }
            moveKR(id: krID, toDomain: domain)
            return true
        }
    }

    // MARK: - Assign domain to value

    private func assignDomain(id: String, toValue value: KairosValue?) {
        guard let uuid = UUID(uuidString: id),
              let domain = current2026?.domains.first(where: { $0.id == uuid }) else { return }
        domain.value = value
        try? modelContext.save()
    }

    // MARK: - Move a KR into another domain's first objective

    private func moveKR(id krID: String, toDomain target: KairosDomain) {
        guard
            let uuid = UUID(uuidString: krID),
            let kr = allKeyResults.first(where: { $0.id == uuid }),
            kr.objective?.domain?.id != target.id
        else { return }

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
}
