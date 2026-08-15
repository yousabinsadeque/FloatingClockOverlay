import AppKit
import CoreGraphics

enum ScreenSampler {

    static func averageBrightnessUnderClock() -> CGFloat {
        guard let screen = NSScreen.main else { return 0.0 }

        let s = ClockSettings.shared
        let x = s.windowX
        let y = s.windowY
        let w = s.customWidth
        let h = s.customHeight

        guard x >= 0, y >= 0, w > 0, h > 0 else { return 0.0 }

        // AppKit coordinates are bottom-left origin; CGWindowList uses top-left
        let screenH = screen.frame.height
        let cgRect = CGRect(x: x, y: screenH - y - h, width: w, height: h)

        // Capture everything below our window (exclude our own app's windows)
        guard let image = CGWindowListCreateImage(
            cgRect,
            .optionOnScreenBelowWindow,
            CGWindowID(0),
            [.boundsIgnoreFraming, .nominalResolution]
        ) else { return 0.0 }

        // Downsample to a tiny bitmap for speed
        let sampleSize = 8
        guard let ctx = CGContext(
            data: nil,
            width: sampleSize, height: sampleSize,
            bitsPerComponent: 8, bytesPerRow: sampleSize * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return 0.0 }

        ctx.draw(image, in: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize))

        guard let data = ctx.data else { return 0.0 }
        let ptr = data.bindMemory(to: UInt8.self, capacity: sampleSize * sampleSize * 4)

        var totalBrightness: Double = 0
        let pixelCount = sampleSize * sampleSize
        for i in 0..<pixelCount {
            let offset = i * 4
            let r = Double(ptr[offset])     / 255.0
            let g = Double(ptr[offset + 1]) / 255.0
            let b = Double(ptr[offset + 2]) / 255.0
            // Perceived brightness (ITU-R BT.709)
            totalBrightness += 0.2126 * r + 0.7152 * g + 0.0722 * b
        }

        return CGFloat(totalBrightness / Double(pixelCount))
    }
}
