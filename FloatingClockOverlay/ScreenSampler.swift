import AppKit
import CoreGraphics

enum ScreenSampler {
    static var clockWindowNumber: CGWindowID = 0
    static weak var clockWindow: NSWindow?

    static func averageBrightnessUnderClock() -> CGFloat {
        guard let window = clockWindow else { return -1 }
        let frame = window.frame
        let x = frame.origin.x
        let y = frame.origin.y
        let w = frame.width
        let h = frame.height

        guard w > 0, h > 0 else { return -1 }

        let mainH = NSScreen.screens.map { $0.frame.maxY }.max() ?? 0
        let cgRect = CGRect(x: x, y: mainH - y - h, width: w, height: h)

        // Method 1: Screen capture (requires Screen Recording permission)
        if CGPreflightScreenCaptureAccess() {
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

    static func requestPermissionIfNeeded() {
        if !CGPreflightScreenCaptureAccess() {
            CGRequestScreenCaptureAccess()
        }
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

            // Skip our own window
            if CGWindowID(windowNum) == clockWindowNumber {
                foundOurWindow = true
                continue
            }

            // Only consider windows below ours (after ours in the z-order list)
            if !foundOurWindow { continue }

            // Skip very high-level windows (menu bar, etc.)
            if layer > 20 { continue }

            // Check if window bounds contain our point
            if let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
               let wx = boundsDict["X"] as? CGFloat,
               let wy = boundsDict["Y"] as? CGFloat,
               let ww = boundsDict["Width"] as? CGFloat,
               let wh = boundsDict["Height"] as? CGFloat {
                let windowRect = CGRect(x: wx, y: wy, width: ww, height: wh)
                if windowRect.contains(point) {
                    // Found a window below us at this point
                    // Check the owning app's appearance
                    if let ownerPID = info[kCGWindowOwnerPID as String] as? Int32 {
                        let app = NSRunningApplication(processIdentifier: ownerPID)
                        // Most apps follow the system appearance
                        // Check if the app has an effective appearance set
                        if let appName = app?.localizedName {
                            // Use NSAppearance to detect dark mode for the app
                            let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                            return isDark ? 0.2 : 0.8
                        }
                    }
                    // Default: assume the window follows system appearance
                    let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                    return isDark ? 0.2 : 0.8
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
        let sampleX = relX * imgW
        let sampleY = (1.0 - relY) * imgH

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
