import AppKit
import SwiftUI

class SettingsWindowController: NSWindowController, NSWindowDelegate {

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 780),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Floating Clock Overlay"
        window.titlebarAppearsTransparent = false
        window.center()
        window.setFrameAutosaveName("FloatingClockSettings")
        window.contentView = NSHostingView(rootView: SettingsView())
        window.minSize = NSSize(width: 460, height: 500)
        window.maxSize = NSSize(width: 460, height: 1800)

        super.init(window: window)

        // We are the delegate so we can intercept the close button.
        window.delegate = self
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Show

    func show() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - NSWindowDelegate

    // Red close button (and ⌘W) calls this. Return false to prevent the window
    // from actually closing — we hide it instead so the app keeps running.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)   // hide the window
        return false           // do NOT close or deallocate it
    }
}
