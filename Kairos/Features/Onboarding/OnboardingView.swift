import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - OnboardingView

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    var onComplete: () -> Void

    @State private var showImporter = false
    @State private var showWizard   = false
    @State private var importError: String?
    @State private var showError    = false
    @State private var importDone   = false
    @State private var importSummary: String = ""

    var body: some View {
        ZStack {
            KairosTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo / wordmark
                VStack(spacing: KairosTheme.Spacing.xs) {
                    Text("FOURONEIGHT")
                        .font(KairosTheme.Typography.monoLarge)
                        .foregroundStyle(KairosTheme.Colors.textPrimary)
                        .tracking(6)
                    Text("Your annual operating system")
                        .font(KairosTheme.Typography.body)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                }
                .padding(.bottom, KairosTheme.Spacing.xxl)

                // Cards
                VStack(spacing: KairosTheme.Spacing.md) {

                    // Import card
                    OnboardingCard(
                        icon: "arrow.down.doc.fill",
                        title: "Import your data",
                        subtitle: "Restore from a Kairos backup (.json)",
                        accent: KairosTheme.Colors.accent
                    ) {
                        showImporter = true
                    }

                    // Start fresh card
                    OnboardingCard(
                        icon: "sparkles",
                        title: "Start fresh",
                        subtitle: "Set up your year and key results",
                        accent: KairosTheme.Colors.accent
                    ) {
                        showWizard = true
                    }
                }
                .frame(maxWidth: 460)

                // Skip
                Button("Skip for now") { onComplete() }
                    .buttonStyle(.plain)
                    .font(KairosTheme.Typography.caption)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
                    .padding(.top, KairosTheme.Spacing.xl)

                Spacer()
            }
            .padding(KairosTheme.Spacing.xxl)
        }
        // File importer
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .failure(let error):
                importError = error.localizedDescription
                showError   = true
            case .success(let urls):
                guard let url = urls.first else { return }
                performImport(from: url)
            }
        }
        // Import success
        .alert("Import Complete", isPresented: $importDone) {
            Button("Open Kairos") { onComplete() }
        } message: {
            Text(importSummary)
        }
        // Import error
        .alert("Import Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "Unknown error")
        }
        // Year wizard
        .sheet(isPresented: $showWizard) {
            YearWizardView()
                .onDisappear { onComplete() }
        }
    }

    // MARK: - Import logic (mirrors SettingsView.performImport)

    private func performImport(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            importError = "Permission denied for this file."
            showError   = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: url)

            // Onboarding import = replace all: wipe any data CloudKit may have
            // synced down before the user got here, then restore from backup.
            try KairosExportManager.deleteAllData(in: modelContext)

            let result = try KairosExportManager.importBackup(from: data, into: modelContext)
            importSummary = result.summary
            importDone    = true
        } catch {
            importError = error.localizedDescription
            showError   = true
        }
    }
}

// MARK: - OnboardingCard

private struct OnboardingCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: KairosTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(accent)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(KairosTheme.Typography.headline)
                        .foregroundStyle(KairosTheme.Colors.textPrimary)
                    Text(subtitle)
                        .font(KairosTheme.Typography.caption)
                        .foregroundStyle(KairosTheme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
            }
            .padding(KairosTheme.Spacing.md)
            .background(isHovered ? KairosTheme.Colors.surface.opacity(0.8) : KairosTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
                    .stroke(isHovered ? accent.opacity(0.4) : KairosTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
