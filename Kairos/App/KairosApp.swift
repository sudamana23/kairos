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
        do {
            // TODO(icloud): uncomment when Apple Developer Program is active
            // let cloudConfig = ModelConfiguration(
            //     cloudKitDatabase: .private("iCloud.com.damianspendel.kairos")
            // )
            // modelContainer = try ModelContainer(for: schema, configurations: cloudConfig)
            modelContainer = try ModelContainer(for: schema)
        } catch {
            fatalError("Kairos: failed to create ModelContainer — \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .modelContainer(modelContainer)
                .task { await SeedData.seedIfNeeded(in: modelContainer) }
                .task {
                    let granted = await NotificationManager.shared.requestPermission()
                    if granted { await NotificationManager.shared.scheduleAll() }
                }
                .onOpenURL { url in
                    // Handle Oura OAuth callback: kairos://oauth/callback?code=...
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
    @Binding var selection: KairosRoute
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \KairosYear.year, order: .reverse) private var years: [KairosYear]
    @Query private var allKeyResults: [KairosKeyResult]

    private var current2026: KairosYear? { years.first { $0.year == 2026 } }

    var body: some View {
        List(selection: $selection) {

            // MARK: Header
            VStack(alignment: .leading, spacing: 2) {
                Text("KAIROS")
                    .font(KairosTheme.Typography.monoLarge)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                    .tracking(3)
                if let intention = current2026?.intention, !intention.isEmpty {
                    Text(intention)
                        .font(KairosTheme.Typography.monoSmall)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                        .italic()
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
                            Text(domain.emoji)
                            Text(domain.name)
                                .foregroundStyle(KairosTheme.Colors.textPrimary)
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
