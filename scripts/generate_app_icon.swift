import AppKit
import CoreGraphics
import Foundation

private struct ColorStop {
    let position: CGFloat
    let color: NSColor
}

private func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    let red = CGFloat((hex >> 16) & 0xff) / 255
    let green = CGFloat((hex >> 8) & 0xff) / 255
    let blue = CGFloat(hex & 0xff) / 255
    return NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}

private func gradient(_ context: CGContext, from start: CGPoint, to end: CGPoint, stops: [ColorStop]) {
    let colors = stops.map { $0.color.cgColor } as CFArray
    let locations = stops.map(\.position)
    let space = CGColorSpaceCreateDeviceRGB()
    guard let gradient = CGGradient(colorsSpace: space, colors: colors, locations: locations) else { return }
    context.drawLinearGradient(gradient, start: start, end: end, options: [])
}

private func roundedRect(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

private func drawRoundedGradient(
    _ context: CGContext,
    rect: CGRect,
    radius: CGFloat,
    from start: CGPoint,
    to end: CGPoint,
    stops: [ColorStop]
) {
    context.saveGState()
    context.addPath(roundedRect(rect, radius: radius))
    context.clip()
    gradient(context, from: start, to: end, stops: stops)
    context.restoreGState()
}

private func fillRounded(_ context: CGContext, rect: CGRect, radius: CGFloat, color fill: NSColor) {
    context.addPath(roundedRect(rect, radius: radius))
    context.setFillColor(fill.cgColor)
    context.fillPath()
}

private func strokeRounded(
    _ context: CGContext,
    rect: CGRect,
    radius: CGFloat,
    color stroke: NSColor,
    lineWidth: CGFloat
) {
    context.addPath(roundedRect(rect, radius: radius))
    context.setStrokeColor(stroke.cgColor)
    context.setLineWidth(lineWidth)
    context.strokePath()
}

private func drawIcon(size: Int) throws -> CGImage {
    let pixelSize = CGFloat(size)
    let scale = pixelSize / 1024
    func s(_ value: CGFloat) -> CGFloat { value * scale }
    func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        CGRect(x: s(x), y: s(y), width: s(width), height: s(height))
    }
    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: s(x), y: s(y)) }

    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw NSError(domain: "AppIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create bitmap context"])
    }

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.interpolationQuality = .high
    context.translateBy(x: 0, y: pixelSize)
    context.scaleBy(x: 1, y: -1)
    context.clear(CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))

    let baseRect = rect(42, 42, 940, 940)
    let baseRadius = s(220)

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -s(30)), blur: s(42), color: color(0x1F2937, 0.26).cgColor)
    fillRounded(context, rect: baseRect, radius: baseRadius, color: color(0xF6F3EA))
    context.restoreGState()

    drawRoundedGradient(
        context,
        rect: baseRect,
        radius: baseRadius,
        from: point(134, 84),
        to: point(884, 924),
        stops: [
            ColorStop(position: 0.00, color: color(0xFFFDF7)),
            ColorStop(position: 0.52, color: color(0xF4F0E6)),
            ColorStop(position: 1.00, color: color(0xE8EDF1))
        ]
    )

    strokeRounded(context, rect: baseRect.insetBy(dx: s(10), dy: s(10)), radius: s(210), color: color(0xFFFFFF, 0.82), lineWidth: s(16))
    strokeRounded(context, rect: baseRect.insetBy(dx: s(30), dy: s(32)), radius: s(190), color: color(0xCFC7BA, 0.36), lineWidth: s(6))

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -s(18)), blur: s(24), color: color(0x142033, 0.24).cgColor)
    drawRoundedGradient(
        context,
        rect: rect(160, 220, 704, 508),
        radius: s(88),
        from: point(198, 234),
        to: point(812, 742),
        stops: [
            ColorStop(position: 0.00, color: color(0x4D6174)),
            ColorStop(position: 0.62, color: color(0x324353)),
            ColorStop(position: 1.00, color: color(0x243241))
        ]
    )
    context.restoreGState()

    drawRoundedGradient(
        context,
        rect: rect(218, 276, 588, 392),
        radius: s(62),
        from: point(236, 276),
        to: point(792, 692),
        stops: [
            ColorStop(position: 0.00, color: color(0xFFFFFF)),
            ColorStop(position: 0.68, color: color(0xFFFDF8)),
            ColorStop(position: 1.00, color: color(0xEEE8DD))
        ]
    )

    context.saveGState()
    context.addPath(roundedRect(rect(288, 344, 448, 250), radius: s(40)))
    context.setLineWidth(s(35))
    context.setStrokeColor(color(0x2B3B4D).cgColor)
    context.strokePath()
    context.restoreGState()

    drawRoundedGradient(
        context,
        rect: rect(326, 382, 372, 174),
        radius: s(20),
        from: point(334, 384),
        to: point(700, 558),
        stops: [
            ColorStop(position: 0.00, color: color(0xFFFDF8)),
            ColorStop(position: 0.58, color: color(0xF6F0E6)),
            ColorStop(position: 1.00, color: color(0xE8EEF2))
        ]
    )

    fillRounded(context, rect: rect(358, 514, 184, 22), radius: s(11), color: color(0x2B3B4D, 0.92))
    fillRounded(context, rect: rect(568, 514, 92, 22), radius: s(11), color: color(0xD59A3A, 0.82))

    let accentCenter = point(382, 774)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -s(7)), blur: s(11), color: color(0x176BC1, 0.28).cgColor)
    context.addEllipse(in: CGRect(x: accentCenter.x - s(54), y: accentCenter.y - s(54), width: s(108), height: s(108)))
    context.clip()
    gradient(context, from: point(336, 724), to: point(434, 828), stops: [
        ColorStop(position: 0.00, color: color(0x7DBAF4)),
        ColorStop(position: 0.52, color: color(0x3F93E5)),
        ColorStop(position: 1.00, color: color(0x1F6FC8))
    ])
    context.restoreGState()

    context.addEllipse(in: CGRect(x: accentCenter.x - s(46), y: accentCenter.y - s(46), width: s(92), height: s(92)))
    context.setLineWidth(s(8))
    context.setStrokeColor(color(0xFFFFFF, 0.40).cgColor)
    context.strokePath()

    context.addEllipse(in: rect(360, 740, 38, 28))
    context.setFillColor(color(0xFFFFFF, 0.30).cgColor)
    context.fillPath()

    fillRounded(context, rect: rect(486, 754, 206, 26), radius: s(13), color: color(0x2B3B4D, 0.90))
    fillRounded(context, rect: rect(486, 800, 122, 18), radius: s(9), color: color(0xD59A3A, 0.76))

    guard let image = context.makeImage() else {
        throw NSError(domain: "AppIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to create image"])
    }
    return image
}

private func writePNG(_ image: CGImage, to url: URL) throws {
    let bitmap = NSBitmapImageRep(cgImage: image)
    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "AppIcon", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to encode PNG"])
    }
    try png.write(to: url, options: .atomic)
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "entry/src/main/resources/base/media")
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for size in [1024, 512, 256, 128, 64, 48, 32, 16] {
    let image = try drawIcon(size: size)
    let url = outputDirectory.appendingPathComponent("app_icon_\(size).png")
    try writePNG(image, to: url)
    print("Wrote \(url.path)")
}
