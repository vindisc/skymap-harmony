import AppKit
import CoreGraphics
import Foundation

struct ColorStop {
    let position: CGFloat
    let color: NSColor
}

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    let red = CGFloat((hex >> 16) & 0xff) / 255
    let green = CGFloat((hex >> 8) & 0xff) / 255
    let blue = CGFloat(hex & 0xff) / 255
    return NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}

func gradient(_ context: CGContext, from start: CGPoint, to end: CGPoint, stops: [ColorStop]) {
    let colors = stops.map { $0.color.cgColor } as CFArray
    let locations = stops.map(\.position)
    let space = CGColorSpaceCreateDeviceRGB()
    guard let gradient = CGGradient(colorsSpace: space, colors: colors, locations: locations) else { return }
    context.drawLinearGradient(gradient, start: start, end: end, options: [])
}

func roundedRect(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func drawIcon(size: Int) throws -> CGImage {
    let pixelSize = CGFloat(size)
    let scale = pixelSize / 1024
    func s(_ value: CGFloat) -> CGFloat { value * scale }
    func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        CGRect(x: s(x), y: s(y), width: s(width), height: s(height))
    }
    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: s(x), y: s(y)) }

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw NSError(domain: "AppIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create bitmap context"])
    }

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.translateBy(x: 0, y: pixelSize)
    context.scaleBy(x: 1, y: -1)
    context.clear(CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))

    let basePath = roundedRect(rect(72, 56, 880, 856), radius: s(198))
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -s(24)), blur: s(28), color: color(0x182231, 0.18).cgColor)
    context.addPath(basePath)
    context.setFillColor(color(0xF8F6F0).cgColor)
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(basePath)
    context.clip()
    gradient(context, from: point(198, 118), to: point(844, 902), stops: [
        ColorStop(position: 0, color: color(0xFFFDF8)),
        ColorStop(position: 0.58, color: color(0xF8F6F0)),
        ColorStop(position: 1, color: color(0xECEFF3))
    ])
    context.restoreGState()

    context.saveGState()
    context.addPath(roundedRect(rect(76, 60, 872, 848), radius: s(194)))
    context.setLineWidth(s(18))
    context.setStrokeColor(color(0xFFFFFF, 0.72).cgColor)
    context.strokePath()
    context.addPath(roundedRect(rect(92, 82, 840, 820), radius: s(174)))
    context.setLineWidth(s(10))
    context.setStrokeColor(color(0xD8D5CC, 0.34).cgColor)
    context.strokePath()
    context.restoreGState()

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -s(13)), blur: s(16), color: color(0x1A2530, 0.18).cgColor)
    context.addPath(roundedRect(rect(259, 248, 506, 396), radius: s(57)))
    context.clip()
    gradient(context, from: point(304, 250), to: point(717, 706), stops: [
        ColorStop(position: 0, color: color(0x405061)),
        ColorStop(position: 1, color: color(0x263341))
    ])
    context.restoreGState()

    context.saveGState()
    context.addPath(roundedRect(rect(299, 292, 427, 310), radius: s(37)))
    context.clip()
    gradient(context, from: point(286, 246), to: point(737, 695), stops: [
        ColorStop(position: 0, color: color(0xFFFFFF)),
        ColorStop(position: 0.72, color: color(0xFFFDF8)),
        ColorStop(position: 1, color: color(0xF3F0E8))
    ])
    context.restoreGState()

    context.addPath(roundedRect(rect(352.5, 346.5, 319, 209), radius: s(26)))
    context.setLineWidth(s(30))
    context.setStrokeColor(color(0x2F4051).cgColor)
    context.strokePath()

    context.addPath(roundedRect(rect(385.5, 378.5, 253, 144), radius: s(12)))
    context.setFillColor(color(0xFFFDF8).cgColor)
    context.fillPath()

    context.addPath(roundedRect(rect(418.5, 485, 187, 20), radius: s(10)))
    context.setFillColor(color(0x2D3D4D).cgColor)
    context.fillPath()

    let indicatorCenterY: CGFloat = 734
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -s(5)), blur: s(6), color: color(0x1A2530, 0.16).cgColor)
    context.addPath(roundedRect(rect(504, indicatorCenterY - 10, 168, 20), radius: s(10)))
    context.setFillColor(color(0x2D3D4D).cgColor)
    context.fillPath()
    context.restoreGState()

    let blueCenter = point(392, indicatorCenterY)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -s(7)), blur: s(9), color: color(0x1E5DA8, 0.18).cgColor)
    context.addEllipse(in: CGRect(x: blueCenter.x - s(48), y: blueCenter.y - s(48), width: s(96), height: s(96)))
    context.clip()
    gradient(context, from: point(362, 708), to: point(430, 778), stops: [
        ColorStop(position: 0, color: color(0x5FA0E8)),
        ColorStop(position: 0.58, color: color(0x3F86D6)),
        ColorStop(position: 1, color: color(0x2B6FBE))
    ])
    context.restoreGState()

    context.addEllipse(in: CGRect(x: blueCenter.x - s(42), y: blueCenter.y - s(42), width: s(84), height: s(84)))
    context.setLineWidth(s(7))
    context.setStrokeColor(color(0x2D72CC, 0.38).cgColor)
    context.strokePath()

    context.addEllipse(in: rect(376, 708, 32, 25))
    context.setFillColor(color(0xFFFFFF, 0.28).cgColor)
    context.fillPath()

    guard let image = context.makeImage() else {
        throw NSError(domain: "AppIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to create CGImage"])
    }
    return image
}

func writePNG(_ image: CGImage, to url: URL) throws {
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
