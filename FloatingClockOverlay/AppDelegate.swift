import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    private var clockWindowController:    ClockWindowController?
    private var settingsWindowController: SettingsWindowController?
    private var statusItem:               NSStatusItem?
    private var globalMonitor:            Any?

    // Set to true only by the explicit "Quit" menu action.
    // Every other termination path is blocked.
    private var allowQuit = false

    // Dynamic menu items refreshed in menuWillOpen
    private var showHideItem:      NSMenuItem?
    private var clickThroughItem:  NSMenuItem?
    private var launchAtLoginItem: NSMenuItem?
    private var clockModeItem:     NSMenuItem?
    private var timerModeItem:     NSMenuItem?
    private var stopwatchModeItem: NSMenuItem?
    private var timerStartItem:    NSMenuItem?
    private var timerResetItem:    NSMenuItem?
    private var swStartItem:       NSMenuItem?
    private var swLapItem:         NSMenuItem?
    private var swResetItem:       NSMenuItem?

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // LSUIElement = YES in Info.plist makes this an accessory (menu-bar-only) app.
        // We still call this defensively in case the policy ever needs adjusting.
        NSApp.setActivationPolicy(.accessory)

        clockWindowController = ClockWindowController()
        setupStatusBar()
        setupGlobalKeyboardShortcut()

        // Allow the Settings quit button to trigger a real quit via notification.
        NotificationCenter.default.addObserver(
            self, selector: #selector(quitApp),
            name: .quitApp, object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        clockWindowController?.savePosition()
        if let m = globalMonitor { NSEvent.removeMonitor(m) }
    }

    // ── Gate: only allow termination when allowQuit is true ──────────────────
    // This blocks accidental ⌘Q or any programmatic terminate unless it came
    // from our explicit quitApp() action.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        return allowQuit ? .terminateNow : .terminateCancel
    }

    // Closing the last window (e.g. Settings) must never quit the app.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    // MARK: - Quit (the only real exit path)

    @objc private func quitApp() {
        clockWindowController?.savePosition()
        allowQuit = true
        NSApp.terminate(nil)
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.image = NSImage(
            systemSymbolName: "clock.fill",
            accessibilityDescription: "Floating Clock Overlay"
        )

        let menu = NSMenu()
        menu.delegate = self

        // ── Primary actions ───────────────────────────────────────────────
        menu.addItem(NSMenuItem(title: "Open Settings",
                                action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())

        let show = NSMenuItem(title: "Show Overlay",
                              action: #selector(toggleVisibility), keyEquivalent: "")
        let ct   = NSMenuItem(title: "Click-Through: ON ✓",
                              action: #selector(toggleClickThrough), keyEquivalent: "")
        showHideItem = show; clickThroughItem = ct
        menu.addItem(show)
        menu.addItem(ct)
        menu.addItem(.separator())

        // ── Launch at Login ───────────────────────────────────────────────
        let loginItem = NSMenuItem(title: "Launch at Login",
                                   action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem = loginItem
        menu.addItem(loginItem)
        menu.addItem(.separator())

        // ── Theme submenu ─────────────────────────────────────────────────
        let themeItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        themeItem.submenu = buildThemeMenu()
        menu.addItem(themeItem)

        // ── Size submenu ──────────────────────────────────────────────────
        let sizeItem = NSMenuItem(title: "Size", action: nil, keyEquivalent: "")
        sizeItem.submenu = buildSizeMenu()
        menu.addItem(sizeItem)

        // ── Mode submenu ──────────────────────────────────────────────────
        let modeItem = NSMenuItem(title: "Mode", action: nil, keyEquivalent: "")
        modeItem.submenu = buildModeMenu()
        menu.addItem(modeItem)
        menu.addItem(.separator())

        // ── Timer quick controls ──────────────────────────────────────────
        let tStart = NSMenuItem(title: "Timer: Start", action: #selector(timerStartPause), keyEquivalent: "")
        let tReset = NSMenuItem(title: "Timer: Reset", action: #selector(timerReset),      keyEquivalent: "")
        timerStartItem = tStart; timerResetItem = tReset
        menu.addItem(tStart); menu.addItem(tReset)
        menu.addItem(.separator())

        // ── Stopwatch quick controls ──────────────────────────────────────
        let swStart = NSMenuItem(title: "Stopwatch: Start", action: #selector(swStartPause), keyEquivalent: "")
        let swLap   = NSMenuItem(title: "Stopwatch: Lap",   action: #selector(swLap),        keyEquivalent: "")
        let swReset = NSMenuItem(title: "Stopwatch: Reset", action: #selector(swReset),      keyEquivalent: "")
        swStartItem = swStart; swLapItem = swLap; swResetItem = swReset
        menu.addItem(swStart); menu.addItem(swLap); menu.addItem(swReset)
        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: "Reset Position",
                                action: #selector(resetPosition), keyEquivalent: ""))
        menu.addItem(.separator())

        // ── The ONLY real quit path ───────────────────────────────────────
        menu.addItem(NSMenuItem(title: "Quit Floating Clock Overlay",
                                action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    // MARK: - Submenus

    private func buildThemeMenu() -> NSMenu {
        let m = NSMenu()
        for theme in ClockTheme.allCases {
            let item = NSMenuItem(title: theme.label, action: #selector(setTheme(_:)), keyEquivalent: "")
            item.representedObject = theme.rawValue
            item.target = self
            m.addItem(item)
        }
        return m
    }

    private func buildSizeMenu() -> NSMenu {
        let m = NSMenu()
        for preset in SizePreset.allCases {
            let item = NSMenuItem(title: preset.label, action: #selector(setSize(_:)), keyEquivalent: "")
            item.representedObject = preset.rawValue
            item.target = self
            m.addItem(item)
        }
        return m
    }

    private func buildModeMenu() -> NSMenu {
        let m = NSMenu()
        let ci = NSMenuItem(title: "Clock",     action: #selector(setModeClock),     keyEquivalent: "")
        let ti = NSMenuItem(title: "Timer",     action: #selector(setModeTimer),     keyEquivalent: "")
        let si = NSMenuItem(title: "Stopwatch", action: #selector(setModeStopwatch), keyEquivalent: "")
        clockModeItem = ci; timerModeItem = ti; stopwatchModeItem = si
        m.addItem(ci); m.addItem(ti); m.addItem(si)
        return m
    }

    // MARK: - menuWillOpen — refresh all dynamic labels/states

    func menuWillOpen(_ menu: NSMenu) {
        let s  = ClockSettings.shared
        let tc = TimeController.shared

        showHideItem?.title      = s.isVisible      ? "Hide Overlay"         : "Show Overlay"
        clickThroughItem?.title  = s.isClickThrough ? "Click-Through: ON ✓" : "Click-Through: OFF"
        launchAtLoginItem?.state = s.launchAtLogin  ? .on                   : .off

        clockModeItem?.state     = s.overlayMode == .clock     ? .on : .off
        timerModeItem?.state     = s.overlayMode == .timer     ? .on : .off
        stopwatchModeItem?.state = s.overlayMode == .stopwatch ? .on : .off

        let inTimer = s.overlayMode == .timer
        timerStartItem?.isEnabled = inTimer
        timerResetItem?.isEnabled = inTimer
        switch tc.timerState {
        case .idle:     timerStartItem?.title = "Timer: Start"
        case .running:  timerStartItem?.title = "Timer: Pause"
        case .paused:   timerStartItem?.title = "Timer: Resume"
        case .finished: timerStartItem?.title = "Timer: Restart"
        }

        let inSW = s.overlayMode == .stopwatch
        swStartItem?.isEnabled = inSW
        swLapItem?.isEnabled   = inSW && tc.stopwatchState == .running
        swResetItem?.isEnabled = inSW
        switch tc.stopwatchState {
        case .idle:    swStartItem?.title = "Stopwatch: Start"
        case .running: swStartItem?.title = "Stopwatch: Pause"
        case .paused:  swStartItem?.title = "Stopwatch: Resume"
        }

        // Checkmarks for theme and size submenus
        for item in menu.items {
            if item.title == "Theme", let sub = item.submenu {
                for i in sub.items {
                    i.state = (i.representedObject as? String) == s.selectedTheme.rawValue ? .on : .off
                }
            }
            if item.title == "Size", let sub = item.submenu {
                for i in sub.items {
                    i.state = (i.representedObject as? String) == s.sizePreset.rawValue ? .on : .off
                }
            }
        }
    }

    // MARK: - Menu Actions

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.show()
    }

    @objc private func toggleVisibility()    { ClockSettings.shared.isVisible.toggle() }
    @objc private func toggleClickThrough()  { ClockSettings.shared.isClickThrough.toggle() }
    @objc private func resetPosition() {
        NotificationCenter.default.post(name: .moveToPreset, object: ClockSettings.PositionPreset.reset)
    }
    @objc private func toggleLaunchAtLogin() {
        let s = ClockSettings.shared
        s.launchAtLogin = !s.launchAtLogin
        s.applyLaunchAtLogin(s.launchAtLogin)
    }

    @objc private func setTheme(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String, let t = ClockTheme(rawValue: raw) {
            ClockSettings.shared.selectedTheme = t
        }
    }
    @objc private func setSize(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String, let p = SizePreset(rawValue: raw) {
            ClockSettings.shared.sizePreset = p
        }
    }
    @objc private func setModeClock()     { ClockSettings.shared.overlayMode = .clock }
    @objc private func setModeTimer()     { ClockSettings.shared.overlayMode = .timer }
    @objc private func setModeStopwatch() { ClockSettings.shared.overlayMode = .stopwatch }

    @objc private func timerStartPause() {
        switch TimeController.shared.timerState {
        case .idle, .paused:  TimeController.shared.timerStart()
        case .running:        TimeController.shared.timerPause()
        case .finished:       TimeController.shared.timerReset(); TimeController.shared.timerStart()
        }
    }
    @objc private func timerReset() { TimeController.shared.timerReset() }

    @objc private func swStartPause() {
        switch TimeController.shared.stopwatchState {
        case .idle, .paused: TimeController.shared.stopwatchStart()
        case .running:       TimeController.shared.stopwatchPause()
        }
    }
    @objc private func swLap()   { TimeController.shared.stopwatchLap() }
    @objc private func swReset() { TimeController.shared.stopwatchReset() }

    // MARK: - Global Keyboard Shortcut — ⌘⌥C (toggle click-through)

    private func setupGlobalKeyboardShortcut() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == [.command, .option] && event.keyCode == 8 { // 8 = C
                DispatchQueue.main.async { self?.toggleClickThrough() }
            }
        }
    }
}
