import SwiftUI
import SwiftData

// MARK: - PhoneHealthTabView
// iPhone Health tab: HealthKit capture + metrics display.
// Data is stored on KairosYear and syncs to Mac via CloudKit.

struct PhoneHealthTabView: View {
    @Query(sort: \KairosYear.year, order: .reverse) private var allYears: [KairosYear]
    private var years: [KairosYear] { allYears.filter { !$0.isArchived } }
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var hk = HealthKitManager.shared

    private var currentYear: KairosYear? { years.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: KairosTheme.Spacing.lg) {
                    syncNote
                    HealthPanel(
                        storedSnapshot: currentYear?.storedHealthSnapshot,
                        storedSnapshotDate: currentYear?.latestHealthSnapshotCapturedAt ?? .distantPast
                    )
                }
                .padding(KairosTheme.Spacing.md)
            }
            .background(KairosTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Health")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
        .task {
            // Refresh health data every time the tab is opened so the snapshot stays current.
            if hk.isAuthorized {
                await hk.fetchCurrentSnapshot()
            }
        }
        .onAppear {
            // Save any snapshot already loaded (e.g. from a previous session).
            if let snap = hk.snapshot, let year = currentYear {
                year.storedHealthSnapshot = snap
                try? modelContext.save()
            }
        }
        .onChange(of: hk.snapshot) { _, newSnap in
            guard let snap = newSnap, let year = currentYear else { return }
            year.storedHealthSnapshot = snap
            try? modelContext.save()
        }
    }

    private static let snapshotFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    // Small informational note about cross-device sync
    private var syncNote: some View {
        HStack(spacing: KairosTheme.Spacing.sm) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.caption)
                .foregroundStyle(KairosTheme.Colors.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Health data captured here syncs to your Mac via iCloud.")
                    .font(KairosTheme.Typography.caption)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
                if let year = currentYear, year.latestHealthSnapshotCapturedAt > .distantPast {
                    Text("Last synced \(Self.snapshotFormatter.localizedString(for: year.latestHealthSnapshotCapturedAt, relativeTo: Date()))")
                        .font(KairosTheme.Typography.caption)
                        .foregroundStyle(KairosTheme.Colors.textMuted.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, KairosTheme.Spacing.md)
        .padding(.vertical, KairosTheme.Spacing.sm)
        .background(KairosTheme.Colors.accentSubtle)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
    }
}
