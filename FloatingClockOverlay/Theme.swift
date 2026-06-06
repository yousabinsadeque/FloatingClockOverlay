import SwiftUI
import AppKit

// MARK: - Clock Theme

enum ClockTheme: String, CaseIterable, Identifiable {
    case transparent = "transparent"
    case glass       = "glass"
    case dark        = "dark"
    case light       = "light"
    case neon        = "neon"
    case minimal     = "minimal"
    case custom      = "custom"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .transparent: return "Transparent"
        case .glass:       return "Glass"
        case .dark:        return "Dark"
        case .light:       return "Light"
        case .neon:        return "Neon"
        case .minimal:     return "Minimal"
        case .custom:      return "Custom"
        }
    }
    var icon: String {
        switch self {
        case .transparent: return "circle.dashed"
        case .glass:       return "circle.hexagongrid"
        case .dark:        return "moon.fill"
        case .light:       return "sun.max.fill"
        case .neon:        return "bolt.fill"
        case .minimal:     return "minus.circle"
        case .custom:      return "slider.horizontal.3"
        }
    }
}

// MARK: - Theme Style

struct ThemeStyle {
    var useVibrancy:    Bool
    var useGlass:       Bool       // true = render iOSGlassCard instead of flat color
    var bgColor:        Color
    var bgOpacity:      Double
    var textColor:      Color
    var cornerRadius:   Double
    var borderColor:    Color
    var borderOpacity:  Double
    var shadowOpacity:  Double
    var useNeonGlow:    Bool
    var glowColor:      Color
}

extension ClockTheme {
    func resolved(using s: ClockSettings) -> ThemeStyle {
        let cr = s.cornerRadius

        switch self {
        case .transparent:
            return ThemeStyle(useVibrancy: false, useGlass: false,
                              bgColor: .black, bgOpacity: s.backgroundOpacity,
                              textColor: s.textColor, cornerRadius: cr,
                              borderColor: .white, borderOpacity: 0,
                              shadowOpacity: s.shadowStrength,
                              useNeonGlow: false, glowColor: .clear)

        case .glass:
            // Routed to iOSGlassCard — all the visual work happens there.
            return ThemeStyle(useVibrancy: true, useGlass: true,
                              bgColor: .clear, bgOpacity: 0,
                              textColor: .white, cornerRadius: cr,
                              borderColor: .white, borderOpacity: 0,  // glass handles its own border
                              shadowOpacity: 0.25,
                              useNeonGlow: false, glowColor: .clear)

        case .dark:
            return ThemeStyle(useVibrancy: false, useGlass: false,
                              bgColor: Color(white: 0.08), bgOpacity: 0.92,
                              textColor: .white, cornerRadius: cr,
                              borderColor: .white, borderOpacity: 0.12,
                              shadowOpacity: 0.7,
                              useNeonGlow: false, glowColor: .clear)

        case .light:
            return ThemeStyle(useVibrancy: false, useGlass: false,
                              bgColor: Color(white: 0.97), bgOpacity: 0.93,
                              textColor: Color(white: 0.08), cornerRadius: cr,
                              borderColor: Color(white: 0.5), borderOpacity: 0.12,
                              shadowOpacity: 0.15,
                              useNeonGlow: false, glowColor: .clear)

        case .neon:
            return ThemeStyle(useVibrancy: false, useGlass: false,
                              bgColor: Color(white: 0.03), bgOpacity: 0.90,
                              textColor: s.accentColor, cornerRadius: cr,
                              borderColor: s.accentColor, borderOpacity: 0.8,
                              shadowOpacity: 0,
                              useNeonGlow: true, glowColor: s.accentColor)

        case .minimal:
            return ThemeStyle(useVibrancy: false, useGlass: false,
                              bgColor: .clear, bgOpacity: 0,
                              textColor: s.textColor, cornerRadius: 0,
                              borderColor: .clear, borderOpacity: 0,
                              shadowOpacity: s.shadowStrength,
                              useNeonGlow: false, glowColor: .clear)

        case .custom:
            return ThemeStyle(useVibrancy: false, useGlass: false,
                              bgColor: s.bgColor, bgOpacity: s.backgroundOpacity,
                              textColor: s.textColor, cornerRadius: cr,
                              borderColor: s.accentColor, borderOpacity: s.borderOpacity,
                              shadowOpacity: s.shadowStrength,
                              useNeonGlow: false, glowColor: .clear)
        }
    }
}

// MARK: - iOS 26 Liquid Glass Card
//
// Replicates the layered glass material Apple uses in iOS 26 / visionOS:
//
//  Layer 1 – NSVisualEffectView (real-time blur of whatever is behind the window)
//  Layer 2 – Subtle white tint   (~6 % opacity)  ← "glass body"
//  Layer 3 – Top specular glare  (bright→clear gradient from top edge)
//  Layer 4 – Inner rim highlight (bright stroke just inside the outer edge)
//  Layer 5 – Outer hairline border (gradient: light top, darker bottom)
//
// The result matches the frosted, luminous quality of iOS 26 widgets.

struct iOSGlassCard: View {
    var cornerRadius: Double

    @Environment(\.colorScheme) private var colorScheme

    // Adapt brightness to the current appearance
    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        let cr = max(8, cornerRadius)

        ZStack {
            // ── 1. Real blur of background content ───────────────────────────
            VisualEffectBackground(material: .hudWindow, blending: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: cr, style: .continuous))

            // ── 2. Glass body tint ────────────────────────────────────────────
            // Dark mode: almost no tint. Light mode: slightly more white.
            RoundedRectangle(cornerRadius: cr, style: .continuous)
                .fill(Color.white.opacity(isDark ? 0.05 : 0.12))

            // ── 3. Top specular glare ─────────────────────────────────────────
            // Bright gradient from top edge to ~60 % of the height, then clear.
            // Clipped to the top half so the bottom stays clean.
            RoundedRectangle(cornerRadius: cr, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(isDark ? 0.28 : 0.45), location: 0.00),
                            .init(color: Color.white.opacity(isDark ? 0.10 : 0.18), location: 0.30),
                            .init(color: Color.white.opacity(0.03),                 location: 0.55),
                            .init(color: Color.clear,                               location: 0.80),
                        ],
                        startPoint: .top,
                        endPoint:   .bottom
                    )
                )
                .padding(.horizontal, 1)
                .padding(.top, 1)

            // ── 4. Inner rim (bright highlight just inside the shape edge) ────
            RoundedRectangle(cornerRadius: cr, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(isDark ? 0.35 : 0.55), location: 0.0),
                            .init(color: Color.white.opacity(isDark ? 0.08 : 0.15), location: 0.5),
                            .init(color: Color.white.opacity(0.04),                 location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint:   .bottom
                    ),
                    lineWidth: 1.5
                )

            // ── 5. Outer hairline border ──────────────────────────────────────
            // 0.5 pt, very subtle — adds depth without looking painted.
            RoundedRectangle(cornerRadius: cr, style: .continuous)
                .strokeBorder(Color.white.opacity(isDark ? 0.12 : 0.22), lineWidth: 0.5)
        }
    }
}

// MARK: - NSVisualEffectView wrapper

struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blending: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material     = material
        v.blendingMode = blending
        v.state        = .active
        return v
    }
    func updateNSView(_ v: NSVisualEffectView, context: Context) {
        v.material     = material
        v.blendingMode = blending
    }
}

// MARK: - Font Family

enum ClockFontFamily: String, CaseIterable, Identifiable {
    case system     = "system"
    case rounded    = "rounded"
    case monospaced = "monospaced"
    case serif      = "serif"

    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var design: Font.Design {
        switch self {
        case .system:     return .default
        case .rounded:    return .rounded
        case .monospaced: return .monospaced
        case .serif:      return .serif
        }
    }
}

// MARK: - Font Weight

enum ClockFontWeight: String, CaseIterable, Identifiable {
    case thin     = "thin"
    case light    = "light"
    case regular  = "regular"
    case medium   = "medium"
    case semibold = "semibold"
    case bold     = "bold"

    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var weight: Font.Weight {
        switch self {
        case .thin:     return .thin
        case .light:    return .light
        case .regular:  return .regular
        case .medium:   return .medium
        case .semibold: return .semibold
        case .bold:     return .bold
        }
    }
}

// MARK: - Size Preset

enum SizePreset: String, CaseIterable, Identifiable {
    case small      = "small"
    case medium     = "medium"
    case large      = "large"
    case extraLarge = "extraLarge"
    case fullScreen = "fullScreen"
    case custom     = "custom"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .small:      return "Small"
        case .medium:     return "Medium"
        case .large:      return "Large"
        case .extraLarge: return "Extra Large"
        case .fullScreen: return "Full Screen"
        case .custom:     return "Custom"
        }
    }
    var contentSize: NSSize? {
        switch self {
        case .small:      return NSSize(width: 160, height: 50)
        case .medium:     return NSSize(width: 260, height: 70)
        case .large:      return NSSize(width: 380, height: 90)
        case .extraLarge: return NSSize(width: 520, height: 120)
        default:          return nil
        }
    }
}

// MARK: - Clock Alignment

enum ClockAlignment: String, CaseIterable, Identifiable {
    case topLeft      = "topLeft"
    case topCenter    = "topCenter"
    case topRight     = "topRight"
    case centerLeft   = "centerLeft"
    case center       = "center"
    case centerRight  = "centerRight"
    case bottomLeft   = "bottomLeft"
    case bottomCenter = "bottomCenter"
    case bottomRight  = "bottomRight"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .topLeft:      return "arrow.up.left"
        case .topCenter:    return "arrow.up"
        case .topRight:     return "arrow.up.right"
        case .centerLeft:   return "arrow.left"
        case .center:       return "dot.scope"
        case .centerRight:  return "arrow.right"
        case .bottomLeft:   return "arrow.down.left"
        case .bottomCenter: return "arrow.down"
        case .bottomRight:  return "arrow.down.right"
        }
    }
    var swiftUIAlignment: Alignment {
        switch self {
        case .topLeft:      return .topLeading
        case .topCenter:    return .top
        case .topRight:     return .topTrailing
        case .centerLeft:   return .leading
        case .center:       return .center
        case .centerRight:  return .trailing
        case .bottomLeft:   return .bottomLeading
        case .bottomCenter: return .bottom
        case .bottomRight:  return .bottomTrailing
        }
    }
}
