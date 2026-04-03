import SwiftUI
import SwiftData
import CloudKit

@main
struct KairosApp: App {
    let modelContainer: ModelContainer

    init() {
        // Initialise the sync monitor before the container so its observer
        // is registered before CloudKit starts firing events.
        _ = CloudKitSyncMonitor.shared

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

    // CloudKit-backed store. IMPORTANT: this file must ONLY ever be opened with
    // cloudKitDatabase: .private(…). Opening it in local-only mode corrupts
    // CloudKit's internal metadata tables (history tokens, zone state), causing
    // CKInternalErrorDomain Code=1011 on every subsequent launch.
    private static var storeURL: URL = {
        let fm = FileManager.default
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appending(path: "com.damianspendel.kairos", directoryHint: .isDirectory)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appending(path: "kairos.store", directoryHint: .notDirectory)
    }()

    // Separate file for the local-only fallback. Must be a different path from storeURL
    // so the CloudKit store's metadata is never written by a non-CloudKit container.
    private static var localStoreURL: URL = {
        let fm = FileManager.default
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appending(path: "com.damianspendel.kairos", directoryHint: .isDirectory)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appending(path: "kairos-local.store", directoryHint: .notDirectory)
    }()

    // JSON written here before a restart-for-import; consumed once on the next launch.
    static var pendingImportURL: URL = {
        let fm = FileManager.default
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appending(path: "com.damianspendel.kairos", directoryHint: .isDirectory)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appending(path: "pending-import.json", directoryHint: .notDirectory)
    }()

    // MARK: - Import + restart

    /// Save `data` for the next launch, wipe the local CloudKit store AND delete
    /// the server-side zone, then terminate the process.
    ///
    /// Deleting the zone server-side:
    /// - Forces ALL devices to invalidate their local CloudKit caches
    /// - Allows the Mac (even if its CloudKit init was stuck in Code=1011) to
    ///   reset and pull down the fresh data after relaunch
    /// - Removes any zombie/stale records from previous failed sync attempts
    ///
    /// On relaunch: fresh local store → CloudKit creates a new zone → pending
    /// import is applied → CloudKit pushes everything via initial-export, which
    /// handles large batches cleanly. Other devices get a zone-change
    /// notification and download from scratch.
    static func scheduleImportAndRestart(data: Data) async {
        try? data.write(to: pendingImportURL)
        deleteStore()
        await deleteCloudKitZone()
        exit(0)
    }

    private static func deleteCloudKitZone() async {
        let container = CKContainer(identifier: "iCloud.com.damianspendel.kairos")
        let zoneID = CKRecordZone.ID(
            zoneName: "com.apple.coredata.cloudkit.zone",
            ownerName: CKCurrentUserDefaultName
        )
        do {
            try await container.privateCloudDatabase.deleteRecordZone(withID: zoneID)
            print("[Kairos] ✓ Deleted CloudKit zone — will be recreated fresh on relaunch")
        } catch {
            // Zone may not exist yet (e.g. CloudKit never successfully initialised)
            print("[Kairos] CloudKit zone delete skipped: \(error.localizedDescription)")
        }
    }

    /// Wipe the local CloudKit store and restart. Use on a device where CloudKit
    /// is stuck (red badge) after another device has already imported and uploaded.
    /// The device will re-download everything from iCloud on the next launch.
    static func resetSyncAndRestart() {
        deleteStore()
        exit(0)
    }

    // MARK: - Pending import (applied once on first launch after scheduleImportAndRestart)

    static func applyPendingImportIfNeeded(context: ModelContext) {
        let url = pendingImportURL
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return }
        defer { try? FileManager.default.removeItem(at: url) }
        do {
            let result = try KairosExportManager.importBackup(from: data, into: context)
            print("[Kairos] ✓ Applied pending import: \(result.summary)")
        } catch {
            print("[Kairos] ✗ Pending import failed: \(error)")
        }
    }

    private static func makeContainer(schema: Schema) -> ModelContainer {
        let cloudConfig = ModelConfiguration(
            url: storeURL,
            cloudKitDatabase: .private("iCloud.com.damianspendel.kairos")
        )
        // Uses localStoreURL — a DIFFERENT file — so the CloudKit store is never
        // opened in non-CloudKit mode, preserving its internal metadata.
        let localConfig = ModelConfiguration(url: localStoreURL, cloudKitDatabase: .none)

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
                    // Apply a pending import from a previous restart-for-import operation.
                    // Runs before notifications so CloudKit has the data immediately.
                    Self.applyPendingImportIfNeeded(context: modelContainer.mainContext)
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
    @AppStorage("isDarkMode") private var isDarkMode = true

    private var current2026: KairosYear? { years.first { $0.year == 2026 } }

    var body: some View {
        List(selection: $selection) {

            // MARK: Header
            HStack(alignment: .top) {
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
                Spacer()
                SyncStatusBadge()
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
        .foregroundStyle(KairosTheme.Colors.textPrimary)
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
