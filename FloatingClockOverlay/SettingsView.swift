import SwiftUI

// MARK: - Root Settings View

struct SettingsView: View {
    @ObservedObject private var s = ClockSettings.shared

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                generalSection
                modeSection
                appearanceSection
                typographySection
                windowSection
                aboutSection
                quitButton
            }
            .padding(24)
        }
        .frame(width: 460)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "clock.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.blue)
                .symbolRenderingMode(.hierarchical)
            Text("Floating Clock Overlay")
                .font(.title2.bold())
            Text("A transparent always-on-top clock for macOS")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    // MARK: General

    private var generalSection: some View {
        SettingsCard(label: "GENERAL", icon: "gearshape") {
            ToggleRow(icon: "eye",            label: "Show Overlay",     value: $s.isVisible)
            SettingsDivider()
            ToggleRow(icon: "cursorarrow.rays", label: "Click-Through",
                      value: $s.isClickThrough,
                      hint: s.isClickThrough ? "Clicks pass to apps below" : "Drag mode active")
            SettingsDivider()
            ToggleRow(icon: "dock.rectangle", label: "Show in Dock",
                      value: Binding(get: { s.showInDock },
                                     set: { s.showInDock = $0; s.applyDockVisibility($0) }))
            SettingsDivider()
            ToggleRow(icon: "power.circle",   label: "Launch at Login",
                      value: Binding(get: { s.launchAtLogin },
                                     set: { s.launchAtLogin = $0; s.applyLaunchAtLogin($0) }),
                      hint: "Requires app in /Applications folder")
        }
    }

    // MARK: Mode

    private var modeSection: some View {
        SettingsCard(label: "MODE", icon: "square.3.layers.3d") {
            VStack(spacing: 0) {
                Picker("", selection: $s.overlayMode) {
                    ForEach(OverlayMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(12)

                if s.overlayMode != .clock {
                    Divider()
                    TimerStopwatchControlsView()
                        .padding(12)
                }
            }
        }
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        SettingsCard(label: "APPEARANCE", icon: "paintpalette") {
            VStack(spacing: 0) {
                // Theme picker
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "theatermasks").frame(width: 20).foregroundStyle(.secondary)
                        Text("Theme").font(.callout)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(ClockTheme.allCases) { theme in
                                ThemeCard(theme: theme, selected: s.selectedTheme == theme)
                                    .onTapGesture { s.selectedTheme = theme }
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    .padding(.bottom, 10)
                }

                Divider()

                SliderRow(icon: "circle.lefthalf.filled", label: "Window Opacity",
                          value: $s.windowOpacity, range: 0.1...1.0,
                          display: { "\(Int($0 * 100))%" })

                SettingsDivider()

                // Accent / Glow color (used by Neon + Custom)
                SettingsRow(icon: "bolt.fill", label: "Accent / Glow Color") {
                    ColorPicker("", selection: s.accentColorBinding).labelsHidden().frame(width: 28)
                }

                // Custom-theme extras
                if s.selectedTheme == .custom {
                    SettingsDivider()
                    SettingsRow(icon: "rectangle.fill", label: "Background Color") {
                        ColorPicker("", selection: s.bgColorBinding).labelsHidden().frame(width: 28)
                    }
                    SettingsDivider()
                    SliderRow(icon: "square.fill.on.square", label: "Background Opacity",
                              value: $s.backgroundOpacity, range: 0.0...1.0,
                              display: { "\(Int($0 * 100))%" })
                    SettingsDivider()
                    SliderRow(icon: "rectangle.roundedtop", label: "Corner Radius",
                              value: $s.cornerRadius, range: 0...32,
                              display: { "\(Int($0))pt" })
                    SettingsDivider()
                    SliderRow(icon: "rectangle.and.pencil.and.ellipsis", label: "Border Opacity",
                              value: $s.borderOpacity, range: 0.0...1.0,
                              display: { "\(Int($0 * 100))%" })
                    SettingsDivider()
                    SliderRow(icon: "shadow", label: "Shadow Strength",
                              value: $s.shadowStrength, range: 0.0...1.0,
                              display: { "\(Int($0 * 100))%" })
                }

                if s.selectedTheme == .transparent || s.selectedTheme == .minimal {
                    SettingsDivider()
                    SliderRow(icon: "square.fill.on.square", label: "Background Opacity",
                              value: $s.backgroundOpacity, range: 0.0...1.0,
                              display: { "\(Int($0 * 100))%" })
                }
            }
        }
    }

    // MARK: Typography

    private var typographySection: some View {
        SettingsCard(label: "TYPOGRAPHY", icon: "textformat") {
            VStack(spacing: 0) {
                SettingsRow(icon: "character.textbox", label: "Font") {
                    Picker("", selection: $s.fontFamily) {
                        ForEach(ClockFontFamily.allCases) { f in Text(f.label).tag(f) }
                    }
                    .labelsHidden()
                    .frame(width: 130)
                }
                SettingsDivider()
                SettingsRow(icon: "bold", label: "Weight") {
                    Picker("", selection: $s.fontWeight) {
                        ForEach(ClockFontWeight.allCases) { w in Text(w.label).tag(w) }
                    }
                    .labelsHidden()
                    .frame(width: 110)
                }
                SettingsDivider()
                SliderRow(icon: "textformat.size", label: "Font Size",
                          value: $s.fontSize, range: 16...80,
                          display: { "\(Int($0))pt" })
                SettingsDivider()
                SliderRow(icon: "arrow.left.and.right.text.vertical", label: "Letter Spacing",
                          value: $s.letterSpacing, range: -4...20,
                          display: { "\(Int($0))pt" })
                SettingsDivider()
                SettingsRow(icon: "textformat.alt", label: "Text Color") {
                    ColorPicker("", selection: s.textColorBinding).labelsHidden().frame(width: 28)
                }

                // Time format
                Divider().padding(.vertical, 4)
                SettingsRow(icon: "clock.badge", label: "Hour Format") {
                    Picker("", selection: $s.use24Hour) {
                        Text("12-hour").tag(false)
                        Text("24-hour").tag(true)
                    }
                    .pickerStyle(.segmented).labelsHidden().frame(width: 130)
                }
                SettingsDivider()
                ToggleRow(icon: "timer", label: "Show Seconds", value: $s.showSeconds)
                if !s.use24Hour {
                    SettingsDivider()
                    ToggleRow(icon: "a.magnify", label: "Show AM/PM", value: $s.showAmPm)
                    if s.showAmPm {
                        SettingsDivider()
                        SettingsRow(icon: "textformat.abc", label: "AM/PM Style") {
                            Picker("", selection: $s.amPmUppercase) {
                                Text("AM / PM").tag(true)
                                Text("am / pm").tag(false)
                            }
                            .pickerStyle(.segmented).labelsHidden().frame(width: 130)
                        }
                    }
                }
            }
        }
    }

    // MARK: Window

    private var windowSection: some View {
        SettingsCard(label: "WINDOW", icon: "macwindow") {
            VStack(spacing: 0) {
                // Size buttons
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .frame(width: 20).foregroundStyle(.secondary)
                        Text("Size").font(.callout)
                    }
                    HStack(spacing: 8) {
                        ForEach([SizePreset.small, .medium, .large, .extraLarge], id: \.self) { preset in
                            Button(preset.label) {
                                s.isFullScreen = false
                                s.sizePreset = preset
                            }
                            .buttonStyle(.bordered)
                            .tint(s.sizePreset == preset && !s.isFullScreen ? .accentColor : nil)
                        }
                    }
                }
                .padding(12)

                SettingsDivider()

                // Reset
                HStack {
                    Button {
                        s.isFullScreen = false
                        s.sizePreset = .medium
                        NotificationCenter.default.post(name: .moveToPreset, object: ClockSettings.PositionPreset.reset)
                    } label: {
                        Label("Reset Size & Position", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(12)
            }
        }
    }

    // MARK: About

    private var aboutSection: some View {
        SettingsCard(label: "ABOUT", icon: "info.circle") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Floating Clock Overlay").font(.headline)
                HStack(spacing: 8) {
                    Image(systemName: "person.circle.fill").foregroundStyle(.blue).font(.title3)
                    Text("Created by **Yousa Bin Sadeque**").font(.callout)
                }
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green).font(.title3)
                    Text("Free for personal and educational use.").font(.callout)
                }
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lock.shield.fill").foregroundStyle(.orange).font(.title3)
                    Text("Commercial, business, corporate, resale, SaaS, paid redistribution, internal company use, client work, contract work, monetized use, or use as a feature inside another app/product/service requires prior written permission from Yousa Bin Sadeque.")
                        .font(.caption).fixedSize(horizontal: false, vertical: true)
                }
                Divider().padding(.vertical, 2)
                HStack {
                    Text("Copyright © 2026 Yousa Bin Sadeque. All rights reserved.")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("v\(appVersion)").font(.caption.monospacedDigit()).foregroundStyle(.tertiary)
                }
            }
            .padding(12)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var quitButton: some View {
        Button(role: .destructive) {
            // Goes through AppDelegate.quitApp() so allowQuit is set before terminate
            NotificationCenter.default.post(name: .quitApp, object: nil)
        } label: {
            Label("Quit Floating Clock Overlay", systemImage: "power")
                .frame(maxWidth: .infinity).padding(.vertical, 2)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(NSColor.systemRed).opacity(0.85))
        .controlSize(.large)
        .padding(.top, 4).padding(.bottom, 8)
    }
}

// MARK: - Theme Preview Cards

struct ThemeCard: View {
    let theme: ClockTheme
    let selected: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                preview
                Text("10:10")
                    .font(.system(size: 11, weight: .light, design: .monospaced))
                    .foregroundColor(previewTextColor)
                    .shadow(color: neonColor?.opacity(0.8) ?? .clear, radius: 4)
            }
            .frame(width: 76, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(selected ? Color.accentColor : Color(NSColor.separatorColor).opacity(0.5),
                                  lineWidth: selected ? 2 : 0.5)
            )

            Text(theme.label)
                .font(.caption2)
                .foregroundStyle(selected ? Color.accentColor : Color.secondary)
        }
    }

    @ViewBuilder private var preview: some View {
        switch theme {
        case .transparent:
            ZStack {
                checkerboard
                Color.black.opacity(0.35)
            }
        case .glass:
            // Mini preview of the iOS 26 glass layers
            ZStack {
                checkerboard
                iOSGlassCard(cornerRadius: 8)
            }
        case .dark:
            Color(white: 0.08).opacity(0.92)
        case .light:
            Color(white: 0.97).opacity(0.93)
        case .neon:
            Color.black.opacity(0.9)
        case .minimal:
            checkerboard
        case .custom:
            LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var previewTextColor: Color {
        switch theme {
        case .light:       return Color(white: 0.1)
        case .neon:        return .cyan
        case .transparent, .glass, .dark, .minimal, .custom: return .white
        }
    }

    private var neonColor: Color? {
        theme == .neon ? .cyan : nil
    }

    private var checkerboard: some View {
        Canvas { ctx, size in
            let sq: CGFloat = 8
            var fill = false
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                fill = Int(y / sq) % 2 == 0
                while x < size.width {
                    ctx.fill(Path(CGRect(x: x, y: y, width: sq, height: sq)),
                             with: .color(fill ? Color(white: 0.6) : Color(white: 0.8)))
                    fill.toggle(); x += sq
                }
                y += sq
            }
        }
    }
}

// MARK: - Reusable Components

struct SettingsCard<Content: View>: View {
    let label: String
    let icon:  String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption.weight(.semibold))
                Text(label).font(.caption.weight(.semibold))
            }
            .foregroundStyle(.secondary)
            .padding(.leading, 2)

            VStack(spacing: 0) { content() }
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color(NSColor.separatorColor).opacity(0.6), lineWidth: 0.5))
        }
    }
}

struct SettingsRow<Control: View>: View {
    let icon: String; let label: String
    @ViewBuilder let control: () -> Control

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).frame(width: 20).foregroundStyle(.secondary)
            Text(label).font(.callout)
            Spacer()
            control()
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
    }
}

struct ToggleRow: View {
    let icon: String; let label: String
    @Binding var value: Bool
    var hint: String? = nil

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).frame(width: 20).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.callout)
                if let hint { Text(hint).font(.caption2).foregroundStyle(.tertiary) }
            }
            Spacer()
            Toggle("", isOn: $value).labelsHidden().toggleStyle(.switch)
        }
        .padding(.horizontal, 12).padding(.vertical, hint != nil ? 8 : 10)
    }
}

struct SliderRow: View {
    let icon: String; let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let display: (Double) -> String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: icon).frame(width: 20).foregroundStyle(.secondary)
                Text(label).font(.callout)
                Spacer()
                Text(display(value)).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    .frame(width: 46, alignment: .trailing)
            }
            Slider(value: $value, in: range).padding(.leading, 30)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
    }
}

struct SettingsDivider: View {
    var body: some View { Divider().padding(.leading, 42) }
}
