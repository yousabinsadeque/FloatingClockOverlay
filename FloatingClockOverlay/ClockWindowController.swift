import AppKit
import SwiftUI
import Combine

class ClockWindowController: NSWindowController, NSWindowDelegate {

    private let s = ClockSettings.shared
    private var cancellables = Set<AnyCancellable>()
    private var savedFrameBeforeFullscreen: NSRect?

    init() {
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.borderless, .resizable],   // always resizable
            backing: .buffered,
            defer: false
        )
        super.init(window: window)
        configureWindow()
        setupObservers()
        setupAlwaysOnTop()     // ← keeps clock above every app on every switch
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Initial Setup

    private func configureWindow() {
        guard let window = window else { return }

        window.delegate                    = self
        window.level                       = .screenSaver   // above everything
        window.isOpaque                    = false
        window.backgroundColor             = .clear
        window.hasShadow                   = false
        // canJoinAllSpaces  → visible on every Space
        // fullScreenAuxiliary → visible over full-screen apps
        // stationary        → doesn't move during Spaces animation
        window.collectionBehavior          = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.isMovableByWindowBackground = true
        window.ignoresMouseEvents          = s.isClickThrough
        window.alphaValue                  = s.windowOpacity
        // Sensible drag-resize limits
        window.minSize = NSSize(width: 80,   height: 30)
        window.maxSize = NSSize(width: 3000, height: 1000)

        window.contentView = NSHostingView(rootView: ClockView())

        if s.isFullScreen {
            applyFullScreen(true, animate: false)
        } else {
            applyPreset(s.sizePreset, animate: false)
            restorePosition()
        }

        if s.isVisible { window.orderFrontRegardless() }
    }

    private func restorePosition() {
        guard let window = window else { return }
        if s.windowX >= 0 && s.windowY >= 0 {
            window.setFrameOrigin(NSPoint(x: s.windowX, y: s.windowY))
        } else {
            moveToPreset(.topRight)
        }
    }

    // MARK: - Always On Top (across every app switch)

    private func setupAlwaysOnTop() {
        // Every time the user switches to any app, push the clock back to front.
        // The .screenSaver level already beats normal windows; this call handles
        // edge cases (full-screen games, presentation tools, etc.).
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(bringToFront),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func bringToFront() {
        guard s.isVisible else { return }
        // Small delay so the newly activated app finishes raising its own windows first.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            // orderFrontRegardless bypasses the normal "active app" restriction.
            self?.window?.orderFrontRegardless()
        }
    }

    // MARK: - Observers

    private func setupObservers() {
        s.$isClickThrough
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ct in
                // .resizable stays in the mask always — mouse events are what
                // control whether the user can interact (drag/resize).
                self?.window?.ignoresMouseEvents = ct
            }
            .store(in: &cancellables)

        s.$windowOpacity
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.window?.alphaValue = $0 }
            .store(in: &cancellables)

        s.$isVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] visible in
                guard let self = self else { return }
                if visible {
                    self.window?.orderFrontRegardless()
                } else {
                    self.window?.orderOut(nil)
                }
            }
            .store(in: &cancellables)

        s.$isFullScreen
            .receive(on: DispatchQueue.main)
            .sink { [weak self] fs in self?.applyFullScreen(fs, animate: true) }
            .store(in: &cancellables)

        s.$sizePreset
            .receive(on: DispatchQueue.main)
            .sink { [weak self] preset in
                guard let self = self, !self.s.isFullScreen else { return }
                self.applyPreset(preset, animate: false)
            }
            .store(in: &cancellables)

        Publishers.MergeMany(
            s.$fontSize.map    { _ in () }.eraseToAnyPublisher(),
            s.$showSeconds.map { _ in () }.eraseToAnyPublisher(),
            s.$use24Hour.map   { _ in () }.eraseToAnyPublisher(),
            s.$showAmPm.map    { _ in () }.eraseToAnyPublisher(),
            s.$fontFamily.map  { _ in () }.eraseToAnyPublisher()
        )
        .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
        .sink { [weak self] in
            guard let self = self,
                  !self.s.isFullScreen,
                  self.s.sizePreset != .custom else { return }
            self.applyPreset(self.s.sizePreset, animate: false)
        }
        .store(in: &cancellables)

        NotificationCenter.default.addObserver(
            self, selector: #selector(handlePositionPreset(_:)),
            name: .moveToPreset, object: nil
        )
    }

    // MARK: - Full Screen

    func applyFullScreen(_ enable: Bool, animate: Bool) {
        guard let window = window, let screen = NSScreen.main else { return }
        if enable {
            if savedFrameBeforeFullscreen == nil {
                savedFrameBeforeFullscreen = window.frame
            }
            window.setFrame(screen.frame, display: true, animate: animate)
        } else {
            if let saved = savedFrameBeforeFullscreen {
                window.setFrame(saved, display: true, animate: animate)
                savedFrameBeforeFullscreen = nil
            } else {
                applyPreset(s.sizePreset, animate: animate)
            }
        }
    }

    // MARK: - Size Presets

    func applyPreset(_ preset: SizePreset, animate: Bool) {
        guard let window = window else { return }

        if preset == .fullScreen {
            s.isFullScreen = true
            return
        }

        let size: NSSize
        if preset == .custom {
            size = NSSize(width: s.customWidth, height: s.customHeight)
        } else if let ps = preset.contentSize {
            size = ps
        } else {
            return
        }

        window.setContentSize(size)
        if let screen = NSScreen.main {
            var frame = window.frame
            frame.origin.x = min(frame.origin.x, screen.visibleFrame.maxX - frame.width)
            frame.origin.y = min(frame.origin.y, screen.visibleFrame.maxY - frame.height)
            frame.origin.x = max(frame.origin.x, screen.visibleFrame.minX)
            frame.origin.y = max(frame.origin.y, screen.visibleFrame.minY)
            window.setFrameOrigin(frame.origin)
        }
    }

    // MARK: - Position Presets

    @objc private func handlePositionPreset(_ note: Notification) {
        if let preset = note.object as? ClockSettings.PositionPreset {
            moveToPreset(preset)
        }
    }

    func moveToPreset(_ preset: ClockSettings.PositionPreset) {
        guard let window = window, let screen = NSScreen.main else { return }
        let f = screen.visibleFrame
        let w = window.frame.width
        let h = window.frame.height
        let p: CGFloat = 20

        let origin: NSPoint
        switch preset {
        case .topLeft:     origin = NSPoint(x: f.minX + p,     y: f.maxY - h - p)
        case .topRight:    origin = NSPoint(x: f.maxX - w - p, y: f.maxY - h - p)
        case .bottomLeft:  origin = NSPoint(x: f.minX + p,     y: f.minY + p)
        case .bottomRight: origin = NSPoint(x: f.maxX - w - p, y: f.minY + p)
        case .center:      origin = NSPoint(x: f.midX - w/2,   y: f.midY - h/2)
        case .reset:       origin = NSPoint(x: f.maxX - w - p, y: f.maxY - h - p)
        }

        window.setFrameOrigin(origin)
        savePosition()
    }

    // MARK: - Persistence

    func savePosition() {
        guard let origin = window?.frame.origin else { return }
        s.windowX = origin.x
        s.windowY = origin.y
    }

    // MARK: - NSWindowDelegate

    func windowDidResize(_ notification: Notification) {
        guard !s.isFullScreen else { return }
        if let window = window {
            s.customWidth  = Double(window.frame.width)
            s.customHeight = Double(window.frame.height)
            if s.sizePreset != .custom { s.sizePreset = .custom }
        }
    }

    func windowDidMove(_ notification: Notification) {
        savePosition()
    }
}
