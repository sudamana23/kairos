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
            KairosMonthlyReview.self
        ])
        modelContainer = Self.makeContainer(schema: schema)
    }

    // MARK: - Container bootstrap (CloudKit → local → reset+local)

    // Explicit store URL so the location is always predictable.
    private static var storeURL: URL = {
        let fm = FileManager.default
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appending(path: "com.damianspendel.kairos", directoryHint: .isDirectory)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appending(path: "kairos.store", directoryHint: .notDirectory)
    }()

    private static func makeContainer(schema: Schema) -> ModelContainer {
        let cloudConfig = ModelConfiguration(
            url: storeURL,
            cloudKitDatabase: .private("iCloud.com.damianspendel.kairos")
        )
        let localConfig = ModelConfiguration(url: storeURL, cloudKitDatabase: .none)

        // 1. Try CloudKit sync
        do {
            let c = try ModelContainer(for: schema, configurations: cloudConfig)
            print("[Kairos] ✓ ModelContainer with CloudKit sync — \(storeURL.path)")
            return c
        } catch {
            print("[Kairos] CloudKit init failed: \(error)")
        }

        // 2. Local fallback (iCloud signed out, network issue, etc.)
        if let c = try? ModelContainer(for: schema, configurations: localConfig) {
            print("[Kairos] ModelContainer local-only — \(storeURL.path)")
            return c
        }

        // 3. Store unreadable — wipe and start fresh (seed data will be recreated)
        print("[Kairos] Store unreadable — resetting")
        Self.deleteStore()
        if let c = try? ModelContainer(for: schema, configurations: localConfig) {
            print("[Kairos] ✓ Fresh ModelContainer after reset")
            return c
        }

        fatalError("[Kairos] Cannot create ModelContainer even after store reset")
    }

    private static func deleteStore() {
        let fm = FileManager.default
        for ext in ["", "-wal", "-shm"] {
            let url = URL(fileURLWithPath: storeURL.path + ext)
            try? fm.removeItem(at: url)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootContainerView()
                .modelContainer(modelContainer)
                .task {
                    let granted = await NotificationManager.shared.requestPermission()
                    if granted { await NotificationManager.shared.scheduleAll() }
                }
                .onOpenURL { url in
                    Task { await OuraManager.shared.handleCallback(url: url) }
                }
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1280, height: 820)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .undoRedo) {}
        }
        #endif
    }
}

// MARK: - RootContainerView

struct RootContainerView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            AppRootView()
        } else {
            OnboardingView {
                hasCompletedOnboarding = true
            }
            #if os(macOS)
            .frame(minWidth: 600, minHeight: 500)
            #endif
        }
    }
}

// MARK: - AppRootView

struct AppRootView: View {
    // Optional so List(selection:) works on both macOS and iOS
    @State private var selection: KairosRoute? = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
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
    case pulse
    case review
    case timeMachine
    case domain(String)
    case settings
}

// MARK: - KairosSidebar

struct KairosSidebar: View {
    @Binding var selection: KairosRoute?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \KairosYear.year, order: .reverse) private var years: [KairosYear]
    @Query private var allKeyResults: [KairosKeyResult]

    private var current2026: KairosYear? { years.first { $0.year == 2026 } }

    var body: some View {
        List(selection: $selection) {

            // MARK: Header
            VStack(alignment: .leading, spacing: 2) {
                Text("FOURONEIGHT")
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
            .padding(.vertical, KairosTheme.Spacing.sm)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            // MARK: Core
            Section {
                Label("Dashboard", systemImage: "square.grid.2x2")
                    .tag(KairosRoute.dashboard)
                Label("Weekly Pulse", systemImage: "waveform")
                    .tag(KairosRoute.pulse)
                Label("Monthly Review", systemImage: "bubble.left.and.bubble.right")
                    .tag(KairosRoute.review)
            }
            .listRowBackground(Color.clear)

            // MARK: Domains
            if let year = current2026 {
                Section("2026") {
                    ForEach(year.sortedDomains) { domain in
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
                        .dropDestination(for: KRDrop.self) { items, _ in
                            guard let krID = items.first?.krID else { return false }
                            moveKR(id: krID, toDomain: domain)
                            return true
                        }
                    }
                }
                .listRowBackground(Color.clear)
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
        .foregroundStyle(KairosTheme.Colors.textSecondary)
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
