import AppKit
import Foundation

let sizes: [(CGFloat, String)] = [
    (16, "16x16"), (32, "16x16@2x"),
    (32, "32x32"), (64, "32x32@2x"),
    (128, "128x128"), (256, "128x128@2x"),
    (256, "256x256"), (512, "256x256@2x"),
    (512, "512x512"), (1024, "512x512@2x"),
]

let iconset = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("AppIcon.iconset")
try? FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    // ── Background: rounded rect with blue gradient ──
    let bg = NSBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size, height: size),
                          xRadius: size * 0.22, yRadius: size * 0.22)
    let gradient = NSGradient(
        starting: NSColor(red: 0.17, green: 0.42, blue: 0.95, alpha: 1),
        ending: NSColor(red: 0.08, green: 0.28, blue: 0.80, alpha: 1)
    )!
    gradient.draw(in: bg, angle: 170)

    // ── Clipboard board ──
    let margin = size * 0.18
    let boardW = size - margin * 2
    let boardH = size - margin * 2
    let boardX = margin
    let boardY = margin - size * 0.03

    let board = NSBezierPath(roundedRect: CGRect(x: boardX, y: boardY, width: boardW, height: boardH),
                             xRadius: size * 0.06, yRadius: size * 0.06)
    NSColor.white.setFill()
    board.fill()

    // ── Top clip ──
    let clipW = size * 0.34
    let clipH = size * 0.14
    let clipX = (size - clipW) / 2
    let clipY = boardY + boardH - clipH * 0.8

    let topClip = NSBezierPath(roundedRect: CGRect(x: clipX, y: clipY, width: clipW, height: clipH),
                               xRadius: size * 0.03, yRadius: size * 0.03)
    NSColor(white: 0.88, alpha: 1).setFill()
    topClip.fill()

    // ── Simulated image ──
    let imgW = boardW * 0.72
    let imgH = boardH * 0.38
    let imgX = boardX + (boardW - imgW) / 2
    let imgY = boardY + boardH * 0.52

    let imgRect = NSBezierPath(roundedRect: CGRect(x: imgX, y: imgY, width: imgW, height: imgH),
                               xRadius: size * 0.035, yRadius: size * 0.035)

    let imgGradient = NSGradient(
        starting: NSColor(red: 0.45, green: 0.70, blue: 1.0, alpha: 1),
        ending: NSColor(red: 0.25, green: 0.50, blue: 0.90, alpha: 1)
    )!
    imgGradient.draw(in: imgRect, angle: 180)

    // Mountain in image
    let mtnBase = imgY + imgH * 0.15
    let mtnH = imgH * 0.65
    let mtnPath = NSBezierPath()
    mtnPath.move(to: NSPoint(x: imgX + imgW * 0.05, y: mtnBase))
    mtnPath.line(to: NSPoint(x: imgX + imgW * 0.30, y: mtnBase + mtnH))
    mtnPath.line(to: NSPoint(x: imgX + imgW * 0.55, y: mtnBase + mtnH * 0.4))
    mtnPath.line(to: NSPoint(x: imgX + imgW * 0.95, y: mtnBase))
    mtnPath.close()
    NSColor(white: 1, alpha: 0.6).setFill()
    mtnPath.fill()

    // Snow cap
    let snowPath = NSBezierPath()
    snowPath.move(to: NSPoint(x: imgX + imgW * 0.48, y: mtnBase + mtnH * 0.5))
    snowPath.line(to: NSPoint(x: imgX + imgW * 0.55, y: mtnBase + mtnH * 0.4))
    snowPath.line(to: NSPoint(x: imgX + imgW * 0.62, y: mtnBase + mtnH * 0.5))
    snowPath.close()
    NSColor.white.setFill()
    snowPath.fill()

    // Sun
    let sunR = imgW * 0.12
    let sunCenter = NSPoint(x: imgX + imgW * 0.77, y: imgY + imgH * 0.80)
    let sunPath = NSBezierPath(ovalIn: CGRect(x: sunCenter.x - sunR, y: sunCenter.y - sunR,
                                               width: sunR * 2, height: sunR * 2))
    NSColor(red: 1, green: 0.85, blue: 0.3, alpha: 0.85).setFill()
    sunPath.fill()

    // ── Text lines ──
    let lineCount = 3
    let lineH = size * 0.025
    let lineW = boardW * 0.68
    let lineX = boardX + boardW * 0.16
    let startY = boardY + boardH * 0.35

    for i in 0..<lineCount {
        let w = i == lineCount - 1 ? lineW * 0.55 : lineW
        let y = startY - CGFloat(i) * lineH * 2.5
        let line = NSBezierPath(roundedRect: CGRect(x: lineX, y: y, width: w, height: lineH),
                                xRadius: lineH / 2, yRadius: lineH / 2)
        let alpha: CGFloat = 1.0 - CGFloat(i) * 0.18
        NSColor(red: 0.17, green: 0.42, blue: 0.95, alpha: alpha).setFill()
        line.fill()
    }

    image.unlockFocus()
    return image
}

let master = drawIcon(size: 1024)

for (size, name) in sizes {
    let pngURL = iconset.appendingPathComponent("icon_\(name).png")
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size),
        pixelsHigh: Int(size),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    master.draw(in: CGRect(x: 0, y: 0, width: size, height: size),
                from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    try rep.representation(using: .png, properties: [:])?.write(to: pngURL)
}

print("Done: \(iconset.path)")
