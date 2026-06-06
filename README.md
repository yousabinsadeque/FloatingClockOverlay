# Floating Clock Overlay

A polished, transparent always-on-top clock overlay for macOS — built with Swift, SwiftUI, and AppKit.

**Created by Yousa Bin Sadeque**

> **Screenshot placeholder** — add a screenshot of your setup here.

---

## Features

- Transparent floating clock/timer/stopwatch overlay, always above every window
- Appears on every Space and over full-screen apps
- Click-through by default — clicks pass to apps behind it
- Draggable and resizable when click-through is OFF
- **7 visual themes:** Transparent, Glass (iOS 26 liquid glass), Dark, Light, Neon, Minimal, Custom
- **Font controls:** family (System / Rounded / Monospaced / Serif), weight, size, letter spacing
- **AM/PM toggle** with uppercase/lowercase style options
- **4 size presets:** Small, Medium, Large, Extra Large + free resize
- **Timer** and **Stopwatch** modes with lap support
- macOS notification when countdown timer finishes
- **Settings window** — every option live-updates the overlay
- **Menu bar icon** with full quick-access controls (Theme / Size / Mode submenus)
- Global keyboard shortcut **⌘ ⌥ C** to toggle click-through
- All settings saved to `UserDefaults` and restored on relaunch
- Menu bar app — keeps running even when the settings window is closed

---

## Installation for Normal Users

1. Download **FloatingClockOverlay.dmg**.
2. Open the DMG file.
3. Drag **FloatingClockOverlay.app** into the **Applications** folder.
4. Open **FloatingClockOverlay** from Applications or Launchpad.
5. The clock overlay will appear on your screen. Use the menu bar icon (🕐) to access settings and controls.

> **Note:** Because the app is not signed with an Apple Developer certificate, macOS may show a warning the first time you open it. To open it:
> - Right-click (or Control-click) the app → click **Open** → click **Open** again in the dialog.
> - Future signed and notarized releases will remove this warning.

---

## Developer Build Instructions

Requires macOS 12+, Xcode 14+, and Swift 5.7+.

```bash
cd ~/Desktop/FloatingClockOverlay

make build          # compile the app
make run            # compile + launch
make install-local  # copy .app into /Applications (prompts for sudo)
make package-dmg    # create dist/FloatingClockOverlay.dmg
make clean          # wipe build artefacts
make open-xcode     # open the Xcode project
```

---

## Using the App

Once running the app shows a **clock icon in the menu bar**.

### Click-through mode

| State | Behaviour |
|---|---|
| Click-Through **ON** ✓ (default) | Clicks pass through to apps below |
| Click-Through **OFF** | Overlay is draggable and resizable |

Toggle via menu bar → **Toggle Click-Through**, or press **⌘ ⌥ C**.

> ⌘ ⌥ C requires **System Settings → Privacy & Security → Accessibility → Floating Clock Overlay → enable**.

### Resizing the overlay

1. Turn off click-through (menu bar or ⌘ ⌥ C).
2. Drag any edge or corner of the overlay to resize.
3. Turn click-through back on when done.

Or use **Settings → Window → Size** to choose a preset (Small / Medium / Large / Extra Large).

### Themes

Open **Settings → Appearance** and tap a theme card:

| Theme | Description |
|---|---|
| Transparent | Classic — black background at chosen opacity |
| Glass | iOS 26 liquid glass with blur, glare, and rim highlights |
| Dark | Solid dark rounded card |
| Light | Solid light rounded card |
| Neon | Dark background with glowing accent color |
| Minimal | Text only, no background |
| Custom | Full control: bg color, opacity, corner radius, border, shadow |

---

## Project Structure

```
FloatingClockOverlay/
├── FloatingClockOverlay.xcodeproj/
├── FloatingClockOverlay/                 Source files
│   ├── main.swift                        App entry point
│   ├── AppDelegate.swift                 App lifecycle, menu bar, shortcuts
│   ├── ClockSettings.swift               All settings (ObservableObject + UserDefaults)
│   ├── Theme.swift                       Theme/font/size/alignment enums + ThemeStyle
│   ├── ClockView.swift                   Overlay SwiftUI view (all modes, all themes)
│   ├── ClockWindowController.swift       NSWindow — sizing, position, resize
│   ├── SettingsView.swift                Full settings UI
│   ├── SettingsWindowController.swift    Settings NSWindow
│   ├── OverlayMode.swift                 Clock / Timer / Stopwatch enum
│   ├── TimeController.swift              Timer & stopwatch state
│   ├── TimerStopwatchControlsView.swift  Timer/stopwatch controls in settings
│   └── Assets.xcassets/                  App icon
├── scripts/
│   ├── create_icon.swift                 Icon generator
│   └── embed_icon.sh                     Post-build icon embedding
├── Makefile
├── README.md
├── LICENSE
├── NOTICE
└── CONTRIBUTING.md
```

---

## Credits

**Created by Yousa Bin Sadeque**

Built with Swift, SwiftUI, and AppKit. No Electron. No JavaScript. No web tech.

---

## License

Floating Clock Overlay is **source-available** and free for personal, educational, and non-commercial use.

Commercial use, business use, corporate use, resale, paid redistribution, SaaS use, internal company use, client work, contract work, monetized use, or use as a feature inside another app, product, platform, or service requires prior written permission from Yousa Bin Sadeque.

See [LICENSE](LICENSE) for full terms.

Copyright © 2026 Yousa Bin Sadeque. All rights reserved.
