import SwiftUI
import CoreData

// MARK: - CloudKitSyncMonitor
//
// Listens to NSPersistentCloudKitContainer sync events (posted by SwiftData's
// underlying store) and exposes a simple SyncState for the UI.

@MainActor
@Observable
final class CloudKitSyncMonitor {
    static let shared = CloudKitSyncMonitor()

    enum SyncState {
        case idle       // no events received yet
        case syncing    // import or export in progress
        case synced     // last event completed successfully
        case error      // last event failed
    }

    private(set) var state: SyncState = .idle
    private(set) var lastError: String? = nil
    /// Incremented on every remote store change — views that read this
    /// will automatically re-render and pick up CloudKit-delivered deletions.
    private(set) var remoteChangeToken: Int = 0
    private var observers: [NSObjectProtocol] = []

    private init() {
        let syncObserver = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // queue: .main guarantees we are on the main thread; assert that for the compiler.
            MainActor.assumeIsolated {
                guard let self,
                      let event = notification.userInfo?[
                          NSPersistentCloudKitContainer.eventNotificationUserInfoKey
                      ] as? NSPersistentCloudKitContainer.Event else { return }

                if event.endDate == nil {
                    self.state = .syncing
                } else if event.succeeded {
                    self.state = .synced
                    self.lastError = nil
                } else {
                    let msg = event.error?.localizedDescription ?? "Unknown CloudKit error"
                    self.lastError = msg
                    self.state = .error
                    print("[CloudKit] Sync error: \(msg)")
                }
            }
        }

        // NSPersistentStoreRemoteChange fires when CloudKit delivers any change
        // (inserts, updates, deletions) to the local store. Bumping remoteChangeToken
        // ensures @Observable views re-render and @Query picks up the deletion.
        let remoteObserver = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.remoteChangeToken += 1
            }
        }

        observers = [syncObserver, remoteObserver]
    }
}

// MARK: - SyncStatusBadge

struct SyncStatusBadge: View {
    var monitor: CloudKitSyncMonitor = .shared
    @State private var spinning = false

    var body: some View {
        Group {
            switch monitor.state {
            case .idle:
                Image(systemName: "icloud")
                    .foregroundStyle(KairosTheme.Colors.textMuted.opacity(0.4))
            case .syncing:
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(KairosTheme.Colors.accent)
                    .rotationEffect(.degrees(spinning ? 360 : 0))
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            spinning = true
                        }
                    }
                    .onDisappear { spinning = false }
            case .synced:
                Image(systemName: "checkmark.icloud")
                    .foregroundStyle(KairosTheme.Colors.status(.done))
            case .error:
                Image(systemName: "xmark.icloud")
                    .foregroundStyle(KairosTheme.Colors.status(.blocked))
                    .help(monitor.lastError ?? "CloudKit sync error")
            }
        }
        .font(.caption)
    }
}
