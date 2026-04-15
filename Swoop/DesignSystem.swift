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

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable {
    case system = "system"
    case light  = "light"
    case dark   = "dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
}

// MARK: - LiquidGlass (replaces GlassCard)

struct LiquidGlass: ViewModifier {
    var cornerRadius: CGFloat = 20
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.07)
                          : Color.black.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.18 : 0.5),
                                        Color.white.opacity(colorScheme == .dark ? 0.04 : 0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 20) -> some View {
        modifier(LiquidGlass(cornerRadius: cornerRadius))
    }
}

// MARK: - GlassCard (kept for legacy detail views during polish pass)

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

// MARK: - Ambient Glow

struct AmbientGlow: ViewModifier {
    var leadingColor: Color = .swoopPurple
    var trailingColor: Color = .swoopBlue

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    ZStack {
                        Circle()
                            .fill(leadingColor.opacity(0.18))
                            .frame(width: 220, height: 220)
                            .blur(radius: 70)
                            .offset(x: geo.size.width - 80, y: -60)
                        Circle()
                            .fill(trailingColor.opacity(0.12))
                            .frame(width: 200, height: 200)
                            .blur(radius: 70)
                            .offset(x: -40, y: geo.size.height * 0.55)
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            )
    }
}

extension View {
    func ambientGlow(leading: Color = .swoopPurple, trailing: Color = .swoopBlue) -> some View {
        modifier(AmbientGlow(leadingColor: leading, trailingColor: trailing))
    }
}

// MARK: - Adaptive app background

/// Color-scheme-aware background view. Use instead of LinearGradient.appBackground.ignoresSafeArea()
/// so that light-mode selections in Settings produce a visually distinct result.
struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [.bgStart, .bgEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [Color.white, Color(hex: "#f8f8f8")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Score color

extension Double {
    var scoreColor: Color {
        switch self {
        case 67...: return .swoopGreen
        case 34..<67: return .swoopPurple
        default: return .swoopPink
        }
    }
}
