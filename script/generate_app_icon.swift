import AppKit
import Foundation

let outputURL = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "SessionHopper.icns")
let fileManager = FileManager.default
let tempRoot = fileManager.temporaryDirectory
    .appending(path: "SessionHopperIcon-\(UUID().uuidString)")
let iconsetURL = tempRoot.appending(path: "SessionHopper.iconset")

try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let iconFiles: [(name: String, size: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for iconFile in iconFiles {
    let image = makeIcon(size: iconFile.size)
    let destination = iconsetURL.appending(path: iconFile.name)
    try writePNG(image: image, to: destination)
}

try? fileManager.removeItem(at: outputURL)

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = [
    "-c",
    "icns",
    iconsetURL.path,
    "-o",
    outputURL.path
]
try process.run()
process.waitUntilExit()

try? fileManager.removeItem(at: tempRoot)

if process.terminationStatus != 0 {
    throw NSError(
        domain: "SessionHopperIconGenerator",
        code: Int(process.terminationStatus),
        userInfo: [NSLocalizedDescriptionKey: "iconutil failed"]
    )
}

private func makeIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    guard let context = NSGraphicsContext.current?.cgContext else {
        return image
    }

    let size = CGFloat(size)
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    context.clear(rect)

    let iconRect = rect.insetBy(dx: size * 0.055, dy: size * 0.055)
    let backgroundPath = CGPath(
        roundedRect: iconRect,
        cornerWidth: size * 0.2,
        cornerHeight: size * 0.2,
        transform: nil
    )

    context.saveGState()
    context.addPath(backgroundPath)
    context.clip()

    let colors = [
        cgColor(red: 26, green: 188, blue: 142),
        cgColor(red: 12, green: 140, blue: 94),
        cgColor(red: 7, green: 92, blue: 70)
    ] as CFArray
    let locations: [CGFloat] = [0, 0.54, 1]

    if let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors,
        locations: locations
    ) {
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: iconRect.minX, y: iconRect.maxY),
            end: CGPoint(x: iconRect.maxX, y: iconRect.minY),
            options: []
        )
    }

    context.setFillColor(NSColor.white.withAlphaComponent(0.15).cgColor)
    context.fillEllipse(in: CGRect(
        x: iconRect.minX + size * 0.08,
        y: iconRect.maxY - size * 0.28,
        width: size * 0.48,
        height: size * 0.34
    ))
    context.restoreGState()

    context.setStrokeColor(NSColor.white.cgColor)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setLineWidth(max(1.4, size * 0.072))

    context.beginPath()
    context.move(to: CGPoint(x: size * 0.3, y: size * 0.37))
    context.addLine(to: CGPoint(x: size * 0.45, y: size * 0.5))
    context.addLine(to: CGPoint(x: size * 0.3, y: size * 0.63))
    context.strokePath()

    let cursorRect = CGRect(
        x: size * 0.52,
        y: size * 0.36,
        width: size * 0.2,
        height: size * 0.07
    )
    let cursorPath = CGPath(
        roundedRect: cursorRect,
        cornerWidth: size * 0.025,
        cornerHeight: size * 0.025,
        transform: nil
    )
    context.setFillColor(NSColor.white.withAlphaComponent(0.96).cgColor)
    context.addPath(cursorPath)
    context.fillPath()

    drawSpark(in: context, size: size)

    return image
}

private func drawSpark(in context: CGContext, size: CGFloat) {
    let center = CGPoint(x: size * 0.7, y: size * 0.68)
    let long = size * 0.11
    let short = size * 0.04

    context.setFillColor(NSColor.white.withAlphaComponent(0.95).cgColor)
    context.beginPath()
    context.move(to: CGPoint(x: center.x, y: center.y + long))
    context.addLine(to: CGPoint(x: center.x + short, y: center.y + short))
    context.addLine(to: CGPoint(x: center.x + long, y: center.y))
    context.addLine(to: CGPoint(x: center.x + short, y: center.y - short))
    context.addLine(to: CGPoint(x: center.x, y: center.y - long))
    context.addLine(to: CGPoint(x: center.x - short, y: center.y - short))
    context.addLine(to: CGPoint(x: center.x - long, y: center.y))
    context.addLine(to: CGPoint(x: center.x - short, y: center.y + short))
    context.closePath()
    context.fillPath()
}

private func writePNG(image: NSImage, to url: URL) throws {
    guard let tiffData = image.tiffRepresentation,
          let representation = NSBitmapImageRep(data: tiffData),
          let pngData = representation.representation(using: .png, properties: [:]) else {
        throw NSError(
            domain: "SessionHopperIconGenerator",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Could not create PNG data"]
        )
    }

    try pngData.write(to: url)
}

private func cgColor(red: CGFloat, green: CGFloat, blue: CGFloat) -> CGColor {
    NSColor(
        calibratedRed: red / 255.0,
        green: green / 255.0,
        blue: blue / 255.0,
        alpha: 1
    ).cgColor
}
