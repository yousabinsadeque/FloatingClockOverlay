import AppKit
import CoreGraphics

enum ScreenSampler {
    static var clockWindowNumber: CGWindowID = 0
    static weak var clockWindow: NSWindow?
    /// The clock card's frame in SwiftUI window coordinates (top-left origin).
    static var cardRectInWindow: CGRect?

    static func averageBrightnessUnderClock() -> CGFloat {
        guard let window = clockWindow else { return -1 }
        let frame = window.frame
        var x = frame.origin.x
        var y = frame.origin.y
        var w = frame.width
        var h = frame.height

        // Sample only under the card (matters in full-screen mode, where the
        // window spans the whole display but the card is a small clock).
        if let card = cardRectInWindow, card.width > 0, card.height > 0,
           card.width <= frame.width + 1, card.height <= frame.height + 1 {
            x = frame.minX + card.minX
            y = frame.maxY - card.maxY
            w = card.width
            h = card.height
        }

        guard w > 0, h > 0 else { return -1 }

        // Cocoa's origin is the bottom-left of the primary display; CoreGraphics'
        // is the top-left of it. Flip against the primary display's height, not
        // the tallest screen's top edge, or multi-monitor setups sample the wrong spot.
        let mainH = NSScreen.screens.first?.frame.height ?? 0
        let cgRect = CGRect(x: x, y: mainH - y - h, width: w, height: h)

        // Method 1: Screen capture (requires Screen Recording permission)
        if hasCapturePermission {
            let listOption: CGWindowListOption = clockWindowNumber > 0
                ? .optionOnScreenBelowWindow
                : .optionOnScreenOnly
            let windowID = clockWindowNumber > 0 ? clockWindowNumber : CGWindowID(0)

            if let image = CGWindowListCreateImage(
                cgRect, listOption, windowID,
                [.boundsIgnoreFraming, .nominalResolution]
            ) {
                return brightnessOfImage(image)
            }
        }

        // Method 2: Check window list below the clock for dark/light appearance
        let centerCG = CGPoint(x: x + w / 2, y: mainH - y - h / 2)
        if let windowBrightness = brightnessFromWindowList(at: centerCG) {
            return windowBrightness
        }

        // Method 3: Sample the desktop wallpaper directly (no permission needed)
        return wallpaperBrightness(x: x, y: y, w: w, h: h)
    }

    // Without this grant only the approximate fallbacks below are available.
    // Ad-hoc signed builds get a new signature on every rebuild, which silently
    // invalidates a previously granted permission.
    static var hasCapturePermission: Bool { CGPreflightScreenCaptureAccess() }

    static func requestPermissionIfNeeded() {
        if !hasCapturePermission {
            CGRequestScreenCaptureAccess()
        }
    }

    static func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Perceived brightness (0–1) of a SwiftUI/AppKit color, or nil if it can't be resolved.
    static func luminance(of color: NSColor) -> CGFloat? {
        guard let c = color.usingColorSpace(.sRGB) else { return nil }
        return 0.2126 * c.redComponent + 0.7152 * c.greenComponent + 0.0722 * c.blueComponent
    }

    // Use CGWindowListCopyWindowInfo to find windows below the clock and check
    // if they're likely light or dark based on their owner app's appearance
    private static func brightnessFromWindowList(at point: CGPoint) -> CGFloat? {
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else { return nil }

        var foundOurWindow = false

        for info in windowList {
            let windowNum = info[kCGWindowNumber as String] as? Int ?? 0
            let layer = info[kCGWindowLayer as String] as? Int ?? 0

            if CGWindowID(windowNum) == clockWindowNumber {
                foundOurWindow = true
                continue
            }

            if !foundOurWindow { continue }
            if layer > 20 { continue }

            if let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
               let wx = boundsDict["X"] as? CGFloat,
               let wy = boundsDict["Y"] as? CGFloat,
               let ww = boundsDict["Width"] as? CGFloat,
               let wh = boundsDict["Height"] as? CGFloat {
                let windowRect = CGRect(x: wx, y: wy, width: ww, height: wh)
                if windowRect.contains(point) {
                    // Try capturing this specific window's image
                    if let img = CGWindowListCreateImage(
                        .null, .optionIncludingWindow, CGWindowID(windowNum),
                        [.boundsIgnoreFraming, .nominalResolution]) {
                        return brightnessOfImage(img)
                    }
                    // No capture permission — use system appearance as heuristic
                    let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                    return isDark ? 0.15 : 0.85
                }
            }
        }

        return nil
    }

    private static func wallpaperBrightness(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) -> CGFloat {
        let clockCenter = NSPoint(x: x + w / 2, y: y + h / 2)
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(clockCenter) }) ?? NSScreen.main else { return -1 }
        guard let wallpaperURL = NSWorkspace.shared.desktopImageURL(for: screen) else { return -1 }
        guard let image = NSImage(contentsOf: wallpaperURL) else { return -1 }
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return -1 }

        let sf = screen.frame
        let relX = (clockCenter.x - sf.origin.x) / sf.width
        let relY = (clockCenter.y - sf.origin.y) / sf.height

        let imgW = CGFloat(cgImage.width)
        let imgH = CGFloat(cgImage.height)

        // Map screen position → image pixel. Most wallpapers are "fill screen"
        // (scaled proportionally, overflow cropped), so a plain relX * imgW is
        // off whenever the image and screen aspect ratios differ.
        let options = NSWorkspace.shared.desktopImageOptions(for: screen)
        let stretched = (options?[.imageScaling] as? UInt).flatMap(NSImageScaling.init(rawValue:)) == .scaleAxesIndependently
        var sampleX = relX * imgW
        var sampleY = (1.0 - relY) * imgH
        if !stretched {
            let scale = max(sf.width / imgW, sf.height / imgH)
            let shownW = imgW * scale, shownH = imgH * scale
            let offsetX = (shownW - sf.width) / 2
            let offsetY = (shownH - sf.height) / 2
            sampleX = (relX * sf.width + offsetX) / scale
            sampleY = ((1.0 - relY) * sf.height + offsetY) / scale
        }

        let sampleSize = 40
        let cropRect = CGRect(
            x: max(0, sampleX - CGFloat(sampleSize / 2)),
            y: max(0, sampleY - CGFloat(sampleSize / 2)),
            width: CGFloat(sampleSize),
            height: CGFloat(sampleSize)
        )

        guard let cropped = cgImage.cropping(to: cropRect) else { return -1 }
        return brightnessOfImage(cropped)
    }

    private static func brightnessOfImage(_ image: CGImage) -> CGFloat {
        let sampleSize = 8
        guard let ctx = CGContext(
            data: nil,
            width: sampleSize, height: sampleSize,
            bitsPerComponent: 8, bytesPerRow: sampleSize * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return -1 }

        ctx.draw(image, in: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize))

        guard let data = ctx.data else { return -1 }
        let ptr = data.bindMemory(to: UInt8.self, capacity: sampleSize * sampleSize * 4)

        var totalBrightness: Double = 0
        let pixelCount = sampleSize * sampleSize
        for i in 0..<pixelCount {
            let offset = i * 4
            let r = Double(ptr[offset])     / 255.0
            let g = Double(ptr[offset + 1]) / 255.0
            let b = Double(ptr[offset + 2]) / 255.0
            totalBrightness += 0.2126 * r + 0.7152 * g + 0.0722 * b
        }

        return CGFloat(totalBrightness / Double(pixelCount))
    }
}
