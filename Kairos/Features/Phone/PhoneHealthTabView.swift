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
        .onChange(of: hk.snapshot) { _, newSnap in
            guard let snap = newSnap, let year = currentYear else { return }
            year.storedHealthSnapshot = snap
            try? modelContext.save()
        }
    }

    // Small informational note about cross-device sync
    private var syncNote: some View {
        HStack(spacing: KairosTheme.Spacing.sm) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.caption)
                .foregroundStyle(KairosTheme.Colors.accent)
            Text("Health data captured here syncs to your Mac automatically via iCloud.")
                .font(KairosTheme.Typography.caption)
                .foregroundStyle(KairosTheme.Colors.textMuted)
        }
        .padding(.horizontal, KairosTheme.Spacing.md)
        .padding(.vertical, KairosTheme.Spacing.sm)
        .background(KairosTheme.Colors.accentSubtle)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
    }
}
