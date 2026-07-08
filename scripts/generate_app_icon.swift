#!/usr/bin/env swift

import AppKit
import Foundation

private let fileManager = FileManager.default
private let rootURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)
private let mediaDirectory = rootURL.appendingPathComponent("entry/src/main/resources/base/media")
private let assetDirectory = rootURL.appendingPathComponent("assets")
private let releaseDirectory = rootURL.appendingPathComponent("release-assets")

private let backgroundColor = NSColor(calibratedRed: 0.973, green: 0.949, blue: 0.910, alpha: 1.0)
private let foregroundPrimary = NSColor(calibratedRed: 0.122, green: 0.184, blue: 0.229, alpha: 1.0)
private let foregroundSecondary = NSColor(calibratedRed: 0.612, green: 0.628, blue: 0.650, alpha: 0.82)
private let accentColor = NSColor(calibratedRed: 0.949, green: 0.615, blue: 0.106, alpha: 1.0)

private enum IconLayer {
    case background
    case foreground
    case composite
}

private func makeBitmap(size: Int) throws -> NSBitmapImageRep {
    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: size,
            pixelsHigh: size,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
    else {
        throw NSError(domain: "AppIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create bitmap"])
    }
    bitmap.size = NSSize(width: size, height: size)
    return bitmap
}

private func withContext(size: Int, draw: () -> Void) throws -> NSBitmapImageRep {
    let bitmap = try makeBitmap(size: size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current?.imageInterpolation = .high
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}

private func savePNG(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "AppIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to encode PNG \(url.path)"])
    }
    try png.write(to: url, options: .atomic)
    print("Wrote \(url.path)")
}

private func drawRoundedStroke(rect: NSRect, radius: CGFloat, width: CGFloat, color: NSColor) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    path.lineWidth = width
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    color.setStroke()
    path.stroke()
}

private func drawBackground(size: CGFloat) {
    backgroundColor.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()
}

private func drawForeground(size: CGFloat) {
    let scale = size / 1024.0

    drawRoundedStroke(
        rect: NSRect(x: 178 * scale, y: 342 * scale, width: 560 * scale, height: 448 * scale),
        radius: 82 * scale,
        width: 28 * scale,
        color: foregroundSecondary
    )

    drawRoundedStroke(
        rect: NSRect(x: 286 * scale, y: 238 * scale, width: 562 * scale, height: 438 * scale),
        radius: 78 * scale,
        width: 30 * scale,
        color: foregroundPrimary
    )

    let accentPath = NSBezierPath(roundedRect: NSRect(x: 694 * scale, y: 238 * scale, width: 86 * scale, height: 28 * scale),
                                  xRadius: 14 * scale,
                                  yRadius: 14 * scale)
    accentColor.setFill()
    accentPath.fill()
}

private func renderIcon(size: Int, layer: IconLayer, to url: URL) throws {
    let bitmap = try withContext(size: size) {
        let canvasSize = CGFloat(size)
        switch layer {
        case .background:
            drawBackground(size: canvasSize)
        case .foreground:
            NSColor.clear.setFill()
            NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize).fill()
            drawForeground(size: canvasSize)
        case .composite:
            drawBackground(size: canvasSize)
            drawForeground(size: canvasSize)
        }
    }
    try savePNG(bitmap, to: url)
}

try fileManager.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)
try fileManager.createDirectory(at: assetDirectory, withIntermediateDirectories: true)
try fileManager.createDirectory(at: releaseDirectory, withIntermediateDirectories: true)

try renderIcon(size: 1024, layer: .composite, to: assetDirectory.appendingPathComponent("app_icon_source.png"))
try renderIcon(size: 1024, layer: .composite, to: mediaDirectory.appendingPathComponent("app_icon.png"))

for size in [1024, 512, 256, 128, 64, 48, 32, 16] {
    try renderIcon(size: size, layer: .composite, to: mediaDirectory.appendingPathComponent("app_icon_\(size).png"))
}

try renderIcon(size: 1024, layer: .composite, to: releaseDirectory.appendingPathComponent("appgallery-icon-1024.png"))
try renderIcon(size: 216, layer: .composite, to: releaseDirectory.appendingPathComponent("appgallery-icon-216.png"))
try renderIcon(size: 1024, layer: .background, to: releaseDirectory.appendingPathComponent("appgallery-icon-background-1024.png"))
try renderIcon(size: 1024, layer: .foreground, to: releaseDirectory.appendingPathComponent("appgallery-icon-foreground-1024.png"))
