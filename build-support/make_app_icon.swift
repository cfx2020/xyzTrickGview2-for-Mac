#!/usr/bin/swift
import AppKit
import Foundation

struct IconSpec {
    let filename: String
    let pixelSize: Int
}

let args = CommandLine.arguments
if args.count != 2 {
    fputs("Usage: make_app_icon.swift <output.icns>\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: args[1])
let fileManager = FileManager.default
let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("xyzmonitor-iconset-\(UUID().uuidString)")
let iconsetURL = tempRoot.appendingPathComponent("XYZMonitor.iconset")

let specs: [IconSpec] = [
    IconSpec(filename: "icon_16x16.png", pixelSize: 16),
    IconSpec(filename: "icon_16x16@2x.png", pixelSize: 32),
    IconSpec(filename: "icon_32x32.png", pixelSize: 32),
    IconSpec(filename: "icon_32x32@2x.png", pixelSize: 64),
    IconSpec(filename: "icon_128x128.png", pixelSize: 128),
    IconSpec(filename: "icon_128x128@2x.png", pixelSize: 256),
    IconSpec(filename: "icon_256x256.png", pixelSize: 256),
    IconSpec(filename: "icon_256x256@2x.png", pixelSize: 512),
    IconSpec(filename: "icon_512x512.png", pixelSize: 512),
    IconSpec(filename: "icon_512x512@2x.png", pixelSize: 1024)
]

func renderIcon(pixelSize: Int) -> NSImage {
    let canvas = NSImage(size: NSSize(width: pixelSize, height: pixelSize))
    canvas.lockFocus()
    defer { canvas.unlockFocus() }

    let bounds = NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize)
    let inset = CGFloat(pixelSize) * 0.08
    let backgroundRect = bounds.insetBy(dx: inset, dy: inset)
    let backgroundPath = NSBezierPath(
        roundedRect: backgroundRect,
        xRadius: CGFloat(pixelSize) * 0.22,
        yRadius: CGFloat(pixelSize) * 0.22
    )

    NSColor(calibratedWhite: 0.12, alpha: 1.0).setFill()
    backgroundPath.fill()

    NSColor(calibratedWhite: 1.0, alpha: 0.06).setStroke()
    backgroundPath.lineWidth = max(1.0, CGFloat(pixelSize) * 0.015)
    backgroundPath.stroke()

    let symbolPointSize = CGFloat(pixelSize) * 0.56
    let baseConfig = NSImage.SymbolConfiguration(
        pointSize: symbolPointSize,
        weight: .semibold,
        scale: .large
    )
    let colorConfig = NSImage.SymbolConfiguration(hierarchicalColor: .systemBlue)

    guard let symbolImageRaw = NSImage(systemSymbolName: "cube.transparent", accessibilityDescription: nil)?.withSymbolConfiguration(baseConfig)?.withSymbolConfiguration(colorConfig) else {
        return canvas
    }

    let symbolImage = symbolImageRaw.copy() as? NSImage ?? symbolImageRaw
    symbolImage.isTemplate = false

    let symbolRect = NSRect(
        x: (CGFloat(pixelSize) - symbolPointSize) / 2.0,
        y: (CGFloat(pixelSize) - symbolPointSize) / 2.0,
        width: symbolPointSize,
        height: symbolPointSize
    )
    symbolImage.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 1.0)

    return canvas
}

func pngData(from image: NSImage) -> Data? {
    guard let tiffData = image.tiffRepresentation,
          let bitmapRep = NSBitmapImageRep(data: tiffData) else {
        return nil
    }
    return bitmapRep.representation(using: .png, properties: [:])
}

func runProcess(_ executableURL: URL, arguments: [String]) throws {
    let process = Process()
    process.executableURL = executableURL
    process.arguments = arguments

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        throw NSError(domain: "make_app_icon", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: output])
    }
}

do {
    try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

    for spec in specs {
        let image = renderIcon(pixelSize: spec.pixelSize)
        guard let png = pngData(from: image) else {
            throw NSError(domain: "make_app_icon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG for \(spec.filename)"])
        }
        let fileURL = iconsetURL.appendingPathComponent(spec.filename)
        try png.write(to: fileURL)
    }

    if fileManager.fileExists(atPath: outputURL.path) {
        try fileManager.removeItem(at: outputURL)
    }

    try runProcess(
        URL(fileURLWithPath: "/usr/bin/iconutil"),
        arguments: ["-c", "icns", "-o", outputURL.path, iconsetURL.path]
    )

    try? fileManager.removeItem(at: tempRoot)
    print("✓ Icon created: \(outputURL.path)")
} catch {
    fputs("Error: \(error.localizedDescription)\n", stderr)
    try? fileManager.removeItem(at: tempRoot)
    exit(1)
}
