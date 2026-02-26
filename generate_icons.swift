#!/usr/bin/swift
// generate_icons.swift
// Run with: swift generate_icons.swift
// Generates 1024x1024 PNG icons for each AppTheme into the asset catalog.

import CoreGraphics
import ImageIO
import Foundation

// MARK: - Color helpers

struct RGBColor {
    let r, g, b: CGFloat
    var cgColor: CGColor { CGColor(red: r, green: g, blue: b, alpha: 1) }
    /// Blend self over white at given opacity (simulates .opacity() on white bg)
    func blendedOverWhite(opacity: CGFloat) -> RGBColor {
        RGBColor(r: r * opacity + 1.0 * (1 - opacity),
                 g: g * opacity + 1.0 * (1 - opacity),
                 b: b * opacity + 1.0 * (1 - opacity))
    }
}

// MARK: - Theme definitions (mirror Color+Trino.swift)

struct IconTheme {
    let name: String
    let accent: RGBColor    // intensity3 / full
    let light: RGBColor     // intensity1 / 1-of-3
    let mid: RGBColor       // intensity2 / 2-of-3
}

let orange = RGBColor(r: 1.0,  g: 107/255.0, b: 53/255.0)
let green  = RGBColor(r: 0.20, g: 0.75,       b: 0.45)
let teal   = RGBColor(r: 0.17, g: 0.72,       b: 0.68)

let themes: [IconTheme] = [
    IconTheme(
        name: "AppIcon",
        accent: orange,
        light:  RGBColor(r: 1.0, g: 180/255.0, b: 150/255.0),
        mid:    RGBColor(r: 1.0, g: 140/255.0, b: 90/255.0)
    ),
    IconTheme(
        name: "AppIconGreen",
        accent: green,
        light:  green.blendedOverWhite(opacity: 0.30),
        mid:    green.blendedOverWhite(opacity: 0.60)
    ),
    IconTheme(
        name: "AppIconTeal",
        accent: teal,
        light:  teal.blendedOverWhite(opacity: 0.30),
        mid:    teal.blendedOverWhite(opacity: 0.60)
    ),
]

// MARK: - Icon rendering

let iconSize = 1024
let svgSize: CGFloat = 666.0
let scale = CGFloat(iconSize) / svgSize

/// Convert SVG coordinate (y-down) to CoreGraphics coordinate (y-up).
func cgPoint(_ svgX: CGFloat, _ svgY: CGFloat) -> CGPoint {
    CGPoint(x: svgX * scale, y: (svgSize - svgY) * scale)
}

func renderIcon(_ theme: IconTheme) -> CGImage? {
    guard let ctx = CGContext(
        data: nil,
        width: iconSize, height: iconSize,
        bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    // White background
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: iconSize, height: iconSize))

    // Rounded-corner clip (rx=80 in SVG space → scale to icon space)
    let cornerRadius = 80.0 * scale
    let clipPath = CGPath(
        roundedRect: CGRect(x: 0, y: 0, width: CGFloat(iconSize), height: CGFloat(iconSize)),
        cornerWidth: cornerRadius, cornerHeight: cornerRadius,
        transform: nil
    )
    ctx.addPath(clipPath)
    ctx.clip()

    // ------------------------------------------------------------------
    // SVG paths (from icon.svg viewBox 0 0 666 666):
    //   Path 2 (light):  M0 416.25 L312.188 312.188 L416.25 0 H0 V416.25 Z
    //   Path 1 (accent): M312.188 312.188 L666 666 V0 H416.25 L312.188 312.188 Z
    //   Path 3 (mid):    M666 666 L312.188 312.188 L0 416.25 V666 H666 Z
    // ------------------------------------------------------------------

    func fill(_ points: [(CGFloat, CGFloat)], color: RGBColor) {
        let path = CGMutablePath()
        path.move(to: cgPoint(points[0].0, points[0].1))
        for pt in points.dropFirst() { path.addLine(to: cgPoint(pt.0, pt.1)) }
        path.closeSubpath()
        ctx.addPath(path)
        ctx.setFillColor(color.cgColor)
        ctx.fillPath()
    }

    // Draw back-to-front; paths tile perfectly so order doesn't affect result.
    fill([(0, 416.25), (312.188, 312.188), (416.25, 0), (0, 0)],                      color: theme.light)
    fill([(312.188, 312.188), (666, 666), (666, 0), (416.25, 0)],                      color: theme.accent)
    fill([(666, 666), (312.188, 312.188), (0, 416.25), (0, 666)],                      color: theme.mid)

    return ctx.makeImage()
}

// MARK: - Write to asset catalog

let scriptURL  = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let assetsDir  = scriptURL.appendingPathComponent("Trino/Assets.xcassets")

for theme in themes {
    let iconsetDir = assetsDir.appendingPathComponent("\(theme.name).appiconset")
    try? FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

    guard let image = renderIcon(theme) else {
        print("ERROR: could not render \(theme.name)"); continue
    }

    let pngURL = iconsetDir.appendingPathComponent("\(theme.name).png")
    guard let dest = CGImageDestinationCreateWithURL(pngURL as CFURL, "public.png" as CFString, 1, nil) else {
        print("ERROR: could not create destination for \(theme.name)"); continue
    }
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else {
        print("ERROR: could not write \(pngURL.path)"); continue
    }
    print("✓ \(pngURL.path)")
}
print("Done.")
