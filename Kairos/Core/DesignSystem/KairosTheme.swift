import SwiftUI

// MARK: - KairosTheme

enum KairosTheme {

    // MARK: - Colors
    // isDark is set at launch and on toggle. All color properties are computed
    // so every re-render picks up the latest value.

    enum Colors {
        static var isDark: Bool = true

        static var background:      Color { isDark ? Color(hex: "#0A0A0F") : Color(hex: "#F5F5F7") }
        static var surface:         Color { isDark ? Color(hex: "#13131A") : Color(hex: "#FFFFFF") }
        static var surfaceElevated: Color { isDark ? Color(hex: "#1C1C28") : Color(hex: "#EBEBF2") }
        static var border:          Color { isDark ? Color(hex: "#252535") : Color(hex: "#D8D8E8") }
        static var borderSubtle:    Color { isDark ? Color(hex: "#1C1C28") : Color(hex: "#EBEBF2") }

        static var textPrimary:   Color { isDark ? .white                  : Color(hex: "#0A0A18") }
        static var textSecondary: Color { isDark ? Color(hex: "#9A9ABB")   : Color(hex: "#4A4A68") }
        static var textMuted:     Color { isDark ? Color(hex: "#6A6A85")   : Color(hex: "#8A8AA5") }

        static var accent:        Color { isDark ? Color(hex: "#A8A8FF")   : Color(hex: "#5050CC") }
        static var accentSubtle:  Color { isDark ? Color(hex: "#A8A8FF").opacity(0.12) : Color(hex: "#5050CC").opacity(0.10) }

        static func status(_ s: KRStatus) -> Color {
            switch s {
            case .notStarted:  return isDark ? Color(hex: "#3A3A4A") : Color(hex: "#AAAACC")
            case .initialized: return isDark ? Color(hex: "#5A5A7A") : Color(hex: "#7A7A9A")
            case .inProgress:  return Color(hex: "#4A7AA8")
            case .done:        return Color(hex: "#4A9A6A")
            case .blocked:     return Color(hex: "#9A4A4A")
            case .paused:      return Color(hex: "#7A7A4A")
            }
        }

        static func domain(_ name: String) -> Color {
            switch name.lowercased() {
            case "health":        return Color(hex: "#4A9A6A")
            case "work":          return Color(hex: "#4A7AA8")
            case "spirit":        return Color(hex: "#9A6AAA")
            case "sport":         return Color(hex: "#AA7A4A")
            case "kids":          return Color(hex: "#AA9A4A")
            case "love":          return Color(hex: "#AA4A6A")
            case "externalities": return Color(hex: "#6A8AAA")
            default:              return Color(hex: "#6A6A8A")
            }
        }
    }

    // MARK: - Typography

    enum Typography {
        static let displayLarge  = Font.system(size: 34, weight: .bold,     design: .default)
        static let displayMedium = Font.system(size: 24, weight: .semibold, design: .default)
        static let headline      = Font.system(size: 16, weight: .semibold, design: .default)
        static let body          = Font.system(size: 14, weight: .regular,  design: .default)
        static let caption       = Font.system(size: 12, weight: .regular,  design: .default)
        static let monoLarge     = Font.system(size: 24, weight: .medium,   design: .monospaced)
        static let mono          = Font.system(size: 14, weight: .regular,  design: .monospaced)
        static let monoSmall     = Font.system(size: 11, weight: .regular,  design: .monospaced)
        static let label         = Font.system(size: 11, weight: .medium,   design: .default)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 24
        static let xl:  CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Radius

    enum Radius {
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
    }
}

// MARK: - Color Hex Init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Reusable Components

struct KairosLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(KairosTheme.Typography.label)
            .foregroundStyle(KairosTheme.Colors.textMuted)
            .tracking(1.5)
    }
}

struct StatusPill: View {
    let status: KRStatus
    var body: some View {
        Text(status.displayName)
            .font(KairosTheme.Typography.monoSmall)
            .foregroundStyle(KairosTheme.Colors.status(status))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(KairosTheme.Colors.status(status).opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: KairosTheme.Radius.sm))
    }
}

struct KairosDivider: View {
    var body: some View {
        Rectangle()
            .fill(KairosTheme.Colors.border)
            .frame(height: 1)
    }
}

// MARK: - Touch Target Modifier

extension View {
    @ViewBuilder func touchTarget() -> some View {
        #if os(iOS)
        self.frame(minWidth: 44, minHeight: 44)
        #else
        self
        #endif
    }
}
