#!/usr/bin/env swift

import AppKit
import Foundation

private let fileManager = FileManager.default
private let rootURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)
private let defaultSourceURL = rootURL.appendingPathComponent("assets/app_icon_source.png")
private let defaultOutputDirectory = URL(fileURLWithPath: "entry/src/main/resources/base/media")
private let arguments = Array(CommandLine.arguments.dropFirst())

private let sourceURL: URL
private let outputDirectory: URL

if arguments.count >= 2 {
    sourceURL = URL(fileURLWithPath: arguments[0])
    outputDirectory = URL(fileURLWithPath: arguments[1])
} else if let firstArgument = arguments.first {
    let candidate = URL(fileURLWithPath: firstArgument)
    var isDirectory: ObjCBool = false
    if fileManager.fileExists(atPath: candidate.path, isDirectory: &isDirectory), !isDirectory.boolValue {
        sourceURL = candidate
        outputDirectory = defaultOutputDirectory
    } else {
        sourceURL = defaultSourceURL
        outputDirectory = candidate
    }
} else {
    sourceURL = defaultSourceURL
    outputDirectory = defaultOutputDirectory
}

private func loadImage(from url: URL) throws -> NSImage {
    guard let image = NSImage(contentsOf: url), image.isValid else {
        throw NSError(domain: "AppIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to load icon source at \(url.path)"])
    }
    return image
}

private func renderPNG(from image: NSImage, size: Int, to url: URL) throws {
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
        throw NSError(domain: "AppIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to create bitmap \(url.path)"])
    }

    let targetSize = NSSize(width: size, height: size)
    bitmap.size = targetSize
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current?.imageInterpolation = .high
    image.draw(in: NSRect(origin: .zero, size: targetSize), from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "AppIcon", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to encode PNG \(url.path)"])
    }
    try png.write(to: url, options: .atomic)
}

try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let sourceImage = try loadImage(from: sourceURL)
try renderPNG(from: sourceImage, size: 1024, to: outputDirectory.appendingPathComponent("app_icon.png"))

for size in [1024, 512, 256, 128, 64, 48, 32, 16] {
    let url = outputDirectory.appendingPathComponent("app_icon_\(size).png")
    try renderPNG(from: sourceImage, size: size, to: url)
    print("Wrote \(url.path)")
}
