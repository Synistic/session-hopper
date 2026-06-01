import AppKit

enum AppIconFactory {
    static let accent = NSColor(
        calibratedRed: 12.0 / 255.0,
        green: 140.0 / 255.0,
        blue: 94.0 / 255.0,
        alpha: 1
    )

    static let accentLight = NSColor(
        calibratedRed: 26.0 / 255.0,
        green: 188.0 / 255.0,
        blue: 142.0 / 255.0,
        alpha: 1
    )

    static let accentDark = NSColor(
        calibratedRed: 7.0 / 255.0,
        green: 92.0 / 255.0,
        blue: 70.0 / 255.0,
        alpha: 1
    )

    static func makeStatusBarIcon() -> NSImage {
        makeIcon(size: 22, insetRatio: 0.08)
    }

    static func makeAppIcon(size: CGFloat) -> NSImage {
        makeIcon(size: size, insetRatio: 0.055)
    }

    private static func makeIcon(size: CGFloat, insetRatio: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        defer { image.unlockFocus() }

        guard let context = NSGraphicsContext.current?.cgContext else {
            return image
        }

        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        context.clear(rect)

        let inset = size * insetRatio
        let iconRect = rect.insetBy(dx: inset, dy: inset)
        let cornerRadius = size * 0.2
        let backgroundPath = CGPath(
            roundedRect: iconRect,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )

        context.saveGState()
        context.addPath(backgroundPath)
        context.clip()

        let colors = [
            accentLight.cgColor,
            accent.cgColor,
            accentDark.cgColor
        ] as CFArray
        let locations: [CGFloat] = [0, 0.54, 1]
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: locations
        )
        if let gradient {
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

        image.isTemplate = false
        return image
    }

    private static func drawSpark(in context: CGContext, size: CGFloat) {
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
}
