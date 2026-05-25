import AppKit
import Foundation

let previewSize: CGFloat = 128
let iconSize: CGFloat = 18

let outDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("icon_options")
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

func renderIcon(name: String, _ draw: (CGFloat) -> Void) {
    // Save large preview
    let preview = NSImage(size: NSSize(width: previewSize, height: previewSize))
    preview.lockFocus()
    let scale = previewSize / iconSize
    NSGraphicsContext.current?.cgContext.scaleBy(x: scale, y: scale)
    draw(iconSize)
    preview.unlockFocus()

    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(previewSize),
        pixelsHigh: Int(previewSize), bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    preview.draw(in: CGRect(x: 0, y: 0, width: previewSize, height: previewSize),
                 from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!
        .write(to: outDir.appendingPathComponent("\(name).png"))
}

// ── Option 1: Clipboard Outline ──
renderIcon(name: "01_clipboard_outline") { s in
    let lineW: CGFloat = 1.4
    let inset = lineW/2 + 1
    let board = CGRect(x: inset, y: inset+2, width: s-inset*2, height: s-inset*2-2)
    let clip = CGRect(x: s/2-4, y: 1, width: 8, height: 3)
    let path = NSBezierPath(); path.lineWidth = lineW; path.lineCapStyle = .round; path.lineJoinStyle = .round
    path.move(to: NSPoint(x: clip.minX, y: clip.maxY))
    path.line(to: NSPoint(x: clip.minX, y: clip.minY))
    path.line(to: NSPoint(x: clip.maxX, y: clip.minY))
    path.line(to: NSPoint(x: clip.maxX, y: clip.maxY))
    path.move(to: NSPoint(x: board.minX, y: board.maxY))
    path.line(to: NSPoint(x: board.minX, y: board.minY+2))
    path.appendArc(from: NSPoint(x: board.minX, y: board.minY+2),
                   to: NSPoint(x: board.minX+2, y: board.minY), radius: 2)
    path.line(to: NSPoint(x: board.maxX-2, y: board.minY))
    path.appendArc(from: NSPoint(x: board.maxX-2, y: board.minY),
                   to: NSPoint(x: board.maxX, y: board.minY+2), radius: 2)
    path.line(to: NSPoint(x: board.maxX, y: board.maxY))
    path.close()
    path.stroke()
}

// ── Option 2: Filled Clipboard ──
renderIcon(name: "02_clipboard_filled") { s in
    let board = CGRect(x: 1, y: 3, width: s-2, height: s-4)
    let clip = CGRect(x: s/2-4, y: 1, width: 8, height: 3)
    let path = NSBezierPath(roundedRect: board, xRadius: 2.5, yRadius: 2.5)
    path.fill()
    let clipPath = NSBezierPath(roundedRect: clip, xRadius: 1.5, yRadius: 1.5)
    clipPath.fill()
    // notch in board
    let notch = NSBezierPath()
    notch.move(to: NSPoint(x: clip.minX+1, y: board.maxY))
    notch.line(to: NSPoint(x: clip.minX+1, y: board.maxY-1.5))
    notch.line(to: NSPoint(x: clip.maxX-1, y: board.maxY-1.5))
    notch.line(to: NSPoint(x: clip.maxX-1, y: board.maxY))
    notch.stroke()
}

// ── Option 3: Paperclip ──
renderIcon(name: "03_paperclip") { s in
    let lineW: CGFloat = 1.5
    let r = s * 0.2
    let path = NSBezierPath(); path.lineWidth = lineW; path.lineCapStyle = .round; path.lineJoinStyle = .round
    // outer loop
    path.move(to: NSPoint(x: s*0.65, y: s*0.25))
    path.line(to: NSPoint(x: s*0.65, y: s*0.75))
    path.appendArc(from: NSPoint(x: s*0.65, y: s*0.75),
                   to: NSPoint(x: s*0.35, y: s*0.75), radius: r)
    path.line(to: NSPoint(x: s*0.35, y: s*0.35))
    path.appendArc(from: NSPoint(x: s*0.35, y: s*0.35),
                   to: NSPoint(x: s*0.65, y: s*0.35), radius: r*0.8)
    path.stroke()
}

// ── Option 4: Two overlapping squares (history/copy) ──
renderIcon(name: "04_double_square") { s in
    let lineW: CGFloat = 1.3
    let offset: CGFloat = 2.5
    let size: CGFloat = s - 6
    // back square
    var back = CGRect(x: s/2 - size/2 + offset, y: 3 - offset, width: size*0.65, height: size*0.7)
    let path = NSBezierPath(); path.lineWidth = lineW; path.lineCapStyle = .round
    path.append(NSBezierPath(roundedRect: back, xRadius: 2, yRadius: 2))
    // front square
    var front = CGRect(x: s/2 - size/2 - offset*0.3, y: 3 + offset*0.3, width: size*0.65, height: size*0.7)
    path.append(NSBezierPath(roundedRect: front, xRadius: 2, yRadius: 2))
    path.stroke()
}

// ── Option 5: Clipboard with list lines ──
renderIcon(name: "05_clipboard_lines") { s in
    let lineW: CGFloat = 1.2
    let inset = lineW/2 + 1
    let board = CGRect(x: inset, y: inset+1, width: s-inset*2, height: s-inset*2-1)
    let clip = CGRect(x: s/2-4, y: 1, width: 8, height: 2.5)
    let path = NSBezierPath(); path.lineWidth = lineW; path.lineCapStyle = .round; path.lineJoinStyle = .round
    // clip
    path.move(to: NSPoint(x: clip.minX, y: clip.maxY))
    path.line(to: NSPoint(x: clip.minX, y: clip.minY))
    path.line(to: NSPoint(x: clip.maxX, y: clip.minY))
    path.line(to: NSPoint(x: clip.maxX, y: clip.maxY))
    // board
    path.move(to: NSPoint(x: board.minX, y: board.maxY))
    path.line(to: NSPoint(x: board.minX, y: board.minY+2))
    path.appendArc(from: NSPoint(x: board.minX, y: board.minY+2),
                   to: NSPoint(x: board.minX+2, y: board.minY), radius: 2)
    path.line(to: NSPoint(x: board.maxX-2, y: board.minY))
    path.appendArc(from: NSPoint(x: board.maxX-2, y: board.minY),
                   to: NSPoint(x: board.maxX, y: board.minY+2), radius: 2)
    path.line(to: NSPoint(x: board.maxX, y: board.maxY))
    path.close()
    path.stroke()
    // lines inside
    let lx = board.minX + 3.5
    let lw = board.width - 7
    for i in 0..<2 {
        let ly = board.maxY - CGFloat(i+1) * 4
        let line = NSBezierPath(rect: CGRect(x: lx, y: ly, width: lw, height: 1))
        line.fill()
    }
}

// ── Option 6: Simple list icon (three horizontal lines with a clip) ──
renderIcon(name: "06_list_clip") { s in
    let lineW: CGFloat = 1.3
    let lx = s * 0.22
    let lw = s * 0.56
    let path = NSBezierPath(); path.lineWidth = lineW; path.lineCapStyle = .round
    // three lines
    for i in 0..<3 {
        let y = s * (0.65 - CGFloat(i) * 0.18)
        path.move(to: NSPoint(x: lx, y: y))
        path.line(to: NSPoint(x: lx + lw, y: y))
    }
    // clip on left
    path.move(to: NSPoint(x: lx - 1, y: s*0.75))
    path.line(to: NSPoint(x: lx - 1, y: s*0.78))
    path.appendArc(from: NSPoint(x: lx - 1, y: s*0.78),
                   to: NSPoint(x: lx + 2, y: s*0.82), radius: 1.5)
    path.stroke()
}

print("Generated \(6) icon options to: \(outDir.path)")
print("Opening in Finder...")
