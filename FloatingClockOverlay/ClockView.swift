import SwiftUI

struct ClockView: View {
    @ObservedObject private var s  = ClockSettings.shared
    @ObservedObject private var tc = TimeController.shared

    @State private var clockTime = Date()
    @State private var flashOn   = true

    private let clockTimer = Timer.publish(every: 1.0,  on: .main, in: .common).autoconnect()
    private let flashTimer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if s.isFullScreen {
                // Full-screen: clock floats at the chosen alignment point
                ZStack(alignment: s.clockAlignment.swiftUIAlignment) {
                    Color.clear
                    clockCard.padding(24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Normal: card always fills the entire window frame so
                // dragging any edge to resize also resizes the card.
                clockCard
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onReceive(clockTimer) { clockTime = $0 }
        .onReceive(flashTimer) { _ in
            if s.overlayMode == .timer && tc.timerState == .finished {
                flashOn.toggle()
            } else {
                flashOn = true
            }
        }
    }

    // MARK: - Card

    // The card fills whatever frame the window gives it.
    // In click-through mode it looks exactly as before.
    // In interactive (drag/resize) mode it gains a dashed outline + corner
    // dots so the user can see the window boundary and resize handles.
    private var clockCard: some View {
        let style = s.selectedTheme.resolved(using: s)
        return ZStack {
            backgroundLayer(style)
            centeredContent(style)
            borderLayer(style)
            if !s.isClickThrough { resizeHandles }
        }
    }

    // MARK: - Background

    @ViewBuilder
    private func backgroundLayer(_ style: ThemeStyle) -> some View {
        if style.useGlass {
            // iOS 26 liquid glass: blur + glare + rim + hairline border
            iOSGlassCard(cornerRadius: style.cornerRadius)
        } else if style.bgOpacity > 0 {
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .fill(style.bgColor.opacity(style.bgOpacity))
        }
    }

    // MARK: - Text

    private func centeredContent(_ style: ThemeStyle) -> some View {
        VStack(spacing: 2) {
            Text(displayString)
                .font(.system(size: s.fontSize,
                              weight: s.fontWeight.weight,
                              design: s.fontFamily.design))
                .tracking(s.letterSpacing)
                .foregroundColor(activeTextColor(style))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.4)   // shrink gracefully in tiny windows
                .lineLimit(1)
                .shadow(
                    color:  glowOrShadow(style, opacity: flashOn ? 0.9 : 0.4),
                    radius: style.useNeonGlow ? 10 : 3,
                    x: 0, y: style.useNeonGlow ? 0 : 1
                )
                .shadow(
                    color:  glowOrShadow(style, opacity: flashOn ? 0.5 : 0.2),
                    radius: style.useNeonGlow ? 22 : 8,
                    x: 0, y: style.useNeonGlow ? 0 : 4
                )

            if s.overlayMode != .clock {
                Text(modeBadge)
                    .font(.system(size: max(9, s.fontSize * 0.18),
                                  weight: .medium, design: .monospaced))
                    .foregroundStyle(style.textColor.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Border

    @ViewBuilder
    private func borderLayer(_ style: ThemeStyle) -> some View {
        if style.borderOpacity > 0 {
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .strokeBorder(style.borderColor.opacity(style.borderOpacity), lineWidth: 1.5)
        }
    }

    // MARK: - Resize Handle Overlay
    // Shown only when click-through is OFF (interactive / drag-resize mode).
    // Gives the user a clear visual of where the window edges and corners are.

    private var resizeHandles: some View {
        ZStack {
            // Dashed outline = window boundary
            RoundedRectangle(cornerRadius: max(4, s.cornerRadius))
                .strokeBorder(
                    Color.white.opacity(0.55),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                )

            // Corner dots = drag targets
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let r: CGFloat = 5
                let p: CGFloat = 5

                ForEach(
                    [CGPoint(x: p+r, y: p+r),
                     CGPoint(x: w-p-r, y: p+r),
                     CGPoint(x: p+r,   y: h-p-r),
                     CGPoint(x: w-p-r, y: h-p-r)],
                    id: \.x
                ) { pt in
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.45), radius: 2)
                        .frame(width: r*2, height: r*2)
                        .position(pt)
                }
            }
        }
    }

    // MARK: - Display helpers

    private var displayString: String {
        switch s.overlayMode {
        case .clock:     return clockTimeString
        case .timer:     return tc.timerRemaining.hmsString
        case .stopwatch: return tc.stopwatchElapsed.hmsString
        }
    }

    private var clockTimeString: String {
        let f = DateFormatter()
        if s.use24Hour {
            f.dateFormat = s.showSeconds ? "HH:mm:ss" : "HH:mm"
        } else if s.showAmPm {
            f.dateFormat = s.showSeconds ? "h:mm:ss a" : "h:mm a"
        } else {
            f.dateFormat = s.showSeconds ? "h:mm:ss" : "h:mm"
        }
        var result = f.string(from: clockTime)
        if !s.use24Hour && s.showAmPm && !s.amPmUppercase {
            result = result
                .replacingOccurrences(of: " AM", with: " am")
                .replacingOccurrences(of: " PM", with: " pm")
        }
        return result
    }

    private func activeTextColor(_ style: ThemeStyle) -> Color {
        if s.overlayMode == .timer && tc.timerState == .finished {
            return flashOn ? .red : style.textColor
        }
        return style.textColor
    }

    private func glowOrShadow(_ style: ThemeStyle, opacity: Double) -> Color {
        style.useNeonGlow
            ? style.glowColor.opacity(opacity)
            : Color.black.opacity(style.shadowOpacity * opacity)
    }

    private var modeBadge: String {
        switch s.overlayMode {
        case .clock: return ""
        case .timer:
            switch tc.timerState {
            case .running:  return "TIMER ▶"
            case .paused:   return "TIMER ⏸"
            case .finished: return "TIMER ✓"
            case .idle:     return "TIMER"
            }
        case .stopwatch:
            switch tc.stopwatchState {
            case .running: return "STOPWATCH ▶"
            case .paused:  return "STOPWATCH ⏸"
            case .idle:    return "STOPWATCH"
            }
        }
    }
}
