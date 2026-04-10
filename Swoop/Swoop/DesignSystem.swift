import SwiftUI

// MARK: - Colors

extension Color {
    static let swoopPurple  = Color(hex: "#a78bfa")
    static let swoopBlue    = Color(hex: "#60a5fa")
    static let swoopPink    = Color(hex: "#f472b6")
    static let swoopGreen   = Color(hex: "#34d399")
    static let bgStart      = Color(hex: "#1a0533")
    static let bgEnd        = Color(hex: "#0d1f4a")
    static let cardSurface  = Color.white.opacity(0.07)
    static let cardBorder   = Color.white.opacity(0.12)

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Gradients

extension LinearGradient {
    static let appBackground = LinearGradient(
        colors: [.bgStart, .bgEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - View modifiers

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.cardSurface)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cardBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
}

// MARK: - Score color

extension Double {
    /// Returns a color representing the score tier (0–100)
    var scoreColor: Color {
        switch self {
        case 67...: return .swoopGreen
        case 34..<67: return .swoopPurple
        default: return .swoopPink
        }
    }
}
