import SwiftUI
import WidgetKit

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: KairosEntry

    private var data: KairosWidgetData? { entry.data }
    private var progress: Double { data?.yearProgress ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // App name
            Text("FOURONEIGHT")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .tracking(1)

            Spacer()

            // Progress ring + percentage
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.18), lineWidth: 5)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 1) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                    Text(String(data?.currentYear ?? 2026))
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 72, height: 72)
            .frame(maxWidth: .infinity)

            Spacer()

            // Pulse summary
            HStack(spacing: 3) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.yellow)
                Text(pulseText)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .containerBackground(.background, for: .widget)
    }

    private var pulseText: String {
        guard let data else { return "—" }
        guard let pulseDate = data.lastPulseDate else { return "No pulse yet" }
        let days = Calendar.current.dateComponents([.day], from: pulseDate, to: .now).day ?? 0
        let when = days == 0 ? "Today" : "\(days)d ago"
        return "\(when) · \(data.lastPulseEnergy)/5"
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: KairosEntry

    private var data: KairosWidgetData? { entry.data }
    private var progress: Double { data?.yearProgress ?? 0 }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {

            // ── Left column ──
            VStack(alignment: .leading, spacing: 6) {

                Text("FOURONEIGHT")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .tracking(1)

                if let intention = data?.intention, !intention.isEmpty {
                    Text(intention)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Overall progress
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 30, weight: .bold, design: .monospaced))
                    Text("of \(data?.currentYear ?? 2026) complete")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Pulse summary
                HStack(spacing: 3) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.yellow)
                    Text(pulseText)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 1)

            // ── Right column: domains ──
            VStack(alignment: .leading, spacing: 8) {
                let domains = data?.domains ?? []
                ForEach(domains.prefix(4), id: \.name) { domain in
                    DomainProgressRow(domain: domain)
                }
                if domains.isEmpty {
                    Text("Open FourOneEight\nto sync data.")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(14)
        .containerBackground(.background, for: .widget)
    }

    private var pulseText: String {
        guard let data else { return "—" }
        guard let pulseDate = data.lastPulseDate else { return "No pulse yet" }
        let days = Calendar.current.dateComponents([.day], from: pulseDate, to: .now).day ?? 0
        let when = days == 0 ? "Today" : "\(days)d ago"
        return "Pulse \(when) · \(data.lastPulseEnergy)/5"
    }
}

// MARK: - Domain Progress Row

private struct DomainProgressRow: View {
    let domain: KairosWidgetData.DomainSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 3) {
                Text(domain.emoji)
                    .font(.system(size: 9))
                Text(domain.name)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                Spacer()
                Text("\(Int(domain.progress * 100))%")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 2)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(widgetHex: domain.colorHex))
                        .frame(width: geo.size.width * max(0, min(1, domain.progress)), height: 2)
                }
            }
            .frame(height: 2)
        }
    }
}

// MARK: - Hex Color Helper (widget-local, no KairosTheme dependency)

extension Color {
    init(widgetHex hex: String) {
        let clean   = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value:  UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >>  8) & 0xFF) / 255
        let b = Double( value        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    KairosSmallWidget()
} timeline: {
    KairosEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    KairosMediumWidget()
} timeline: {
    KairosEntry.placeholder
}
