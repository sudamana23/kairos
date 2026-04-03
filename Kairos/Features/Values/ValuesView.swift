import SwiftUI
import SwiftData

struct ValuesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \KairosValue.sortOrder) private var values: [KairosValue]

    @State private var showDiscovery = false
    @State private var editingValue: KairosValue?
    @State private var showAddValue = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.xl) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Values")
                            .font(KairosTheme.Typography.monoLarge)
                            .foregroundStyle(KairosTheme.Colors.textPrimary)
                        Text("The timeless principles your life is built around.")
                            .font(KairosTheme.Typography.monoSmall)
                            .foregroundStyle(KairosTheme.Colors.textMuted)
                    }
                    Spacer()
                    Button { showDiscovery = true } label: {
                        Label("Discover", systemImage: "sparkles")
                            .font(KairosTheme.Typography.body)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(KairosTheme.Colors.accent)

                    Button { showAddValue = true } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
                    .padding(.leading, KairosTheme.Spacing.sm)
                }

                if values.isEmpty {
                    emptyState
                } else {
                    valuesList
                }
            }
            .padding(KairosTheme.Spacing.xl)
        }
        .background(KairosTheme.Colors.background)
        .sheet(isPresented: $showDiscovery) { ValuesDiscoveryView() }
        .sheet(item: $editingValue) { v in ValueEditSheet(value: v) }
        .sheet(isPresented: $showAddValue) { ValueAddSheet() }
    }

    private var emptyState: some View {
        VStack(spacing: KairosTheme.Spacing.md) {
            Text("✦")
                .font(.system(size: 40))
            Text("No values yet")
                .font(KairosTheme.Typography.monoLarge)
                .foregroundStyle(KairosTheme.Colors.textPrimary)
            Text("Your values are the timeless principles that guide every goal.\nStart with 3–5 that feel deeply true.")
                .font(KairosTheme.Typography.body)
                .foregroundStyle(KairosTheme.Colors.textMuted)
                .multilineTextAlignment(.center)
            Button("Discover my values") { showDiscovery = true }
                .buttonStyle(.plain)
                .foregroundStyle(KairosTheme.Colors.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(KairosTheme.Spacing.xxl)
    }

    private var valuesList: some View {
        VStack(spacing: KairosTheme.Spacing.sm) {
            ForEach(values) { value in
                ValueRow(
                    value: value,
                    onEdit: { editingValue = value },
                    onDelete: { deleteValue(value) }
                )
            }
        }
    }

    private func deleteValue(_ value: KairosValue) {
        for domain in value.domains { domain.value = nil }
        modelContext.delete(value)
        try? modelContext.save()
        // Re-sort remaining
        let remaining = values.filter { $0.id != value.id }
        for (i, v) in remaining.enumerated() { v.sortOrder = i }
        try? modelContext.save()
    }
}

// MARK: - ValueRow

private struct ValueRow: View {
    let value: KairosValue
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: KairosTheme.Spacing.md) {
            // Colour accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: value.colorHex.isEmpty ? "#4A9A6A" : value.colorHex))
                .frame(width: 4)
                .frame(minHeight: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(value.name.isEmpty ? "Unnamed" : value.name)
                    .font(KairosTheme.Typography.monoLarge)
                    .foregroundStyle(KairosTheme.Colors.textPrimary)
                if !value.reflection.isEmpty {
                    Text(value.reflection)
                        .font(KairosTheme.Typography.body)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Domain count pill
            let count = value.domains.count
            if count > 0 {
                Text("\(count) domain\(count == 1 ? "" : "s")")
                    .font(KairosTheme.Typography.monoSmall)
                    .foregroundStyle(KairosTheme.Colors.textMuted)
                    .padding(.horizontal, KairosTheme.Spacing.sm)
                    .padding(.vertical, KairosTheme.Spacing.xs)
                    .background(KairosTheme.Colors.surfaceElevated)
                    .clipShape(Capsule())
            }

            // Action buttons — visible on hover
            if isHovered {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                }
                .buttonStyle(.plain)
                .help("Edit value")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(KairosTheme.Colors.textMuted)
                }
                .buttonStyle(.plain)
                .help("Delete value")
            }
        }
        .padding(KairosTheme.Spacing.md)
        .background(KairosTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KairosTheme.Radius.md)
                .stroke(KairosTheme.Colors.border, lineWidth: 1)
        )
        .onHover { isHovered = $0 }
    }
}

// MARK: - Colour swatches shared constant

private let kValueColorSwatches: [String] = [
    "#4A9A6A", "#5A7AB5", "#A0522D", "#8B6B8B", "#B8860B",
    "#C0504A", "#4A7A8B", "#6B8B4A", "#7A5A9A", "#8B7A4A"
]

// MARK: - ValueAddSheet

private struct ValueAddSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \KairosValue.sortOrder) private var existingValues: [KairosValue]

    @State private var name = ""
    @State private var emoji = ""
    @State private var reflection = ""
    @State private var selectedColor = "#4A9A6A"

    var body: some View {
        valueForm(
            title: "New Value",
            name: $name,
            emoji: $emoji,
            reflection: $reflection,
            selectedColor: $selectedColor,
            onSave: {
                let v = KairosValue(
                    name: name,
                    reflection: reflection,
                    emoji: emoji,
                    colorHex: selectedColor,
                    sortOrder: existingValues.count
                )
                modelContext.insert(v)
                try? modelContext.save()
                dismiss()
            },
            onCancel: { dismiss() }
        )
    }
}

// MARK: - ValueEditSheet

private struct ValueEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let value: KairosValue

    @State private var name: String
    @State private var emoji: String
    @State private var reflection: String
    @State private var selectedColor: String

    init(value: KairosValue) {
        self.value = value
        _name = State(initialValue: value.name)
        _emoji = State(initialValue: value.emoji)
        _reflection = State(initialValue: value.reflection)
        _selectedColor = State(initialValue: value.colorHex.isEmpty ? "#4A9A6A" : value.colorHex)
    }

    var body: some View {
        valueForm(
            title: "Edit Value",
            name: $name,
            emoji: $emoji,
            reflection: $reflection,
            selectedColor: $selectedColor,
            onSave: {
                value.name = name
                value.emoji = emoji
                value.reflection = reflection
                value.colorHex = selectedColor
                try? modelContext.save()
                dismiss()
            },
            onCancel: { dismiss() }
        )
    }
}

// MARK: - Shared form builder

@ViewBuilder
private func valueForm(
    title: String,
    name: Binding<String>,
    emoji: Binding<String>,
    reflection: Binding<String>,
    selectedColor: Binding<String>,
    onSave: @escaping () -> Void,
    onCancel: @escaping () -> Void
) -> some View {
    VStack(spacing: 0) {
        // Header
        HStack {
            Text(title)
                .font(KairosTheme.Typography.monoLarge)
                .foregroundStyle(KairosTheme.Colors.textPrimary)
            Spacer()
            Button("Cancel", action: onCancel)
                .buttonStyle(.plain)
                .foregroundStyle(KairosTheme.Colors.textMuted)
        }
        .padding(KairosTheme.Spacing.xl)

        KairosDivider()

        ScrollView {
            VStack(alignment: .leading, spacing: KairosTheme.Spacing.lg) {

                // Name
                VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                    KairosLabel(text: "Name")
                    TextField("e.g. Presence", text: name)
                        .textFieldStyle(.plain)
                        .font(KairosTheme.Typography.headline)
                        .foregroundStyle(KairosTheme.Colors.textPrimary)
                        .padding(KairosTheme.Spacing.sm)
                        .background(KairosTheme.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
                }

                // Colour swatches
                VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                    KairosLabel(text: "Colour")
                    HStack(spacing: KairosTheme.Spacing.sm) {
                        ForEach(kValueColorSwatches, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.8), lineWidth: selectedColor.wrappedValue == hex ? 2 : 0)
                                )
                                .onTapGesture { selectedColor.wrappedValue = hex }
                        }
                    }
                }

                // Reflection
                VStack(alignment: .leading, spacing: KairosTheme.Spacing.xs) {
                    KairosLabel(text: "Reflection")
                    TextEditor(text: reflection)
                        .font(KairosTheme.Typography.body)
                        .foregroundStyle(KairosTheme.Colors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .background(KairosTheme.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
                        .frame(minHeight: 100, maxHeight: 180)
                }

                // Save button
                HStack {
                    Spacer()
                    Button("Save") { onSave() }
                        .buttonStyle(.plain)
                        .padding(.horizontal, KairosTheme.Spacing.lg)
                        .padding(.vertical, KairosTheme.Spacing.sm)
                        .background(name.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? KairosTheme.Colors.border
                            : KairosTheme.Colors.accent)
                        .foregroundStyle(KairosTheme.Colors.background)
                        .font(KairosTheme.Typography.headline)
                        .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
                        .disabled(name.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(KairosTheme.Spacing.xl)
        }
    }
    .background(KairosTheme.Colors.background)
    .frame(minWidth: 420, minHeight: 420)
}
