#!/usr/bin/env swift
// Generates FloatingClockOverlay app icon PNGs at all required sizes.
// Usage: swift scripts/create_icon.swift  (run from project root)
import AppKit
import CoreGraphics

func generateIcon(size: Int) -> Data? {
    let s = CGFloat(size)
    let cs = CGColorSpaceCreateDeviceRGB()

    guard let ctx = CGContext(
        data: nil, width: size, height: size,
        bitsPerComponent: 8, bytesPerRow: 0, space: cs,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    // ── Background gradient (blue → purple) ──────────────────────────────
    let gradColors = [CGColor(red: 0.12, green: 0.38, blue: 0.92, alpha: 1.0),
                      CGColor(red: 0.42, green: 0.12, blue: 0.88, alpha: 1.0)] as CFArray
    let locs: [CGFloat] = [0, 1]
    if let grad = CGGradient(colorsSpace: cs, colors: gradColors, locations: locs) {
        ctx.drawLinearGradient(grad,
            start: CGPoint(x: 0, y: 0), end: CGPoint(x: s, y: s), options: [])
    }

    let cx = s / 2, cy = s / 2, r = s * 0.37

    // ── Subtle outer glow ring ────────────────────────────────────────────
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.07))
    ctx.addEllipse(in: CGRect(x: cx - r*1.14, y: cy - r*1.14, width: r*2.28, height: r*2.28))
    ctx.fillPath()

    // ── Clock face (translucent white disc) ───────────────────────────────
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.14))
    ctx.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r*2, height: r*2))
    ctx.fillPath()

    // ── Clock ring ────────────────────────────────────────────────────────
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
    ctx.setLineWidth(max(1, s * 0.026))
    ctx.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r*2, height: r*2))
    ctx.strokePath()

    // ── Hour tick marks ───────────────────────────────────────────────────
    for i in 0..<12 {
        // In CGContext: 0° = right, 90° = up. 12 o'clock = π/2.
        let angle = CGFloat.pi/2 - CGFloat(i) * CGFloat.pi / 6.0
        let isQuarter = (i % 3 == 0)
        let outer = r - s*0.018
        let inner = outer - (isQuarter ? s*0.075 : s*0.045)
        ctx.setLineWidth(isQuarter ? max(1, s*0.028) : max(1, s*0.018))
        ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: isQuarter ? 0.95 : 0.65))
        ctx.move(to:    CGPoint(x: cx + outer*cos(angle), y: cy + outer*sin(angle)))
        ctx.addLine(to: CGPoint(x: cx + inner*cos(angle), y: cy + inner*sin(angle)))
        ctx.strokePath()
    }

    // ── Hour hand (10 o'clock = 150° in math coords = 5π/6) ──────────────
    let hourAngle: CGFloat = .pi * 5 / 6
    let hourLen = r * 0.52
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1.0))
    ctx.setLineWidth(max(1.5, s * 0.048))
    ctx.setLineCap(.round)
    ctx.move(to:    CGPoint(x: cx - hourLen*0.12*cos(hourAngle), y: cy - hourLen*0.12*sin(hourAngle)))
    ctx.addLine(to: CGPoint(x: cx + hourLen*cos(hourAngle),      y: cy + hourLen*sin(hourAngle)))
    ctx.strokePath()

    // ── Minute hand (pointing to 2 = π/6 → 10:10 symmetric) ─────────────
    let minAngle: CGFloat = .pi / 6
    let minLen = r * 0.70
    ctx.setLineWidth(max(1, s * 0.034))
    ctx.move(to:    CGPoint(x: cx - minLen*0.10*cos(minAngle), y: cy - minLen*0.10*sin(minAngle)))
    ctx.addLine(to: CGPoint(x: cx + minLen*cos(minAngle),      y: cy + minLen*sin(minAngle)))
    ctx.strokePath()

    // ── Center jewel ─────────────────────────────────────────────────────
    let jewel = s * 0.035
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1.0))
    ctx.addEllipse(in: CGRect(x: cx - jewel, y: cy - jewel, width: jewel*2, height: jewel*2))
    ctx.fillPath()

    // ── Convert to PNG ────────────────────────────────────────────────────
    guard let cgImage = ctx.makeImage() else { return nil }
    let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: s, height: s))
    guard let tiff = nsImage.tiffRepresentation,
          let bmp  = NSBitmapImageRep(data: tiff),
          let png  = bmp.representation(using: .png, properties: [:]) else { return nil }
    return png
}

// ── Main ──────────────────────────────────────────────────────────────────────

let script = CommandLine.arguments[0]
let projectRoot = URL(fileURLWithPath: script)
    .deletingLastPathComponent()          // scripts/
    .deletingLastPathComponent()          // project root
    .path

let outputDir = "\(projectRoot)/FloatingClockOverlay/Assets.xcassets/AppIcon.appiconset"
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

let sizes = [16, 32, 64, 128, 256, 512, 1024]
var allOK = true

for size in sizes {
    let path = "\(outputDir)/icon_\(size)x\(size).png"
    if let data = generateIcon(size: size) {
        try? data.write(to: URL(fileURLWithPath: path))
        print("  ✓  icon_\(size)x\(size).png")
    } else {
        print("  ✗  icon_\(size)x\(size).png  ← FAILED")
        allOK = false
    }
}

print(allOK ? "\n✓ All icons generated." : "\n⚠ Some icons failed.")
print("  → \(outputDir)")
