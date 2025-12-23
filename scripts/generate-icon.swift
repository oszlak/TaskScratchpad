#!/usr/bin/env swift

import Cocoa

// Icon design: A warm-colored notepad with a checkmark
func generateIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    
    image.lockFocus()
    
    let context = NSGraphicsContext.current!.cgContext
    
    // Background circle with gradient
    let bgRect = CGRect(x: size * 0.08, y: size * 0.08, width: size * 0.84, height: size * 0.84)
    
    // Warm peach gradient
    let colors = [
        NSColor(red: 0.91, green: 0.66, blue: 0.49, alpha: 1.0).cgColor, // #E8A87C
        NSColor(red: 0.89, green: 0.49, blue: 0.38, alpha: 1.0).cgColor  // #E27D60
    ]
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!
    
    // Draw rounded rectangle background
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: size * 0.2, cornerHeight: size * 0.2, transform: nil)
    context.addPath(bgPath)
    context.clip()
    context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])
    context.resetClip()
    
    // Draw notepad shape (white with slight transparency)
    let padRect = CGRect(x: size * 0.22, y: size * 0.18, width: size * 0.56, height: size * 0.64)
    let padPath = CGPath(roundedRect: padRect, cornerWidth: size * 0.06, cornerHeight: size * 0.06, transform: nil)
    
    context.setFillColor(NSColor.white.withAlphaComponent(0.95).cgColor)
    context.addPath(padPath)
    context.fillPath()
    
    // Draw lines on notepad
    context.setStrokeColor(NSColor(red: 0.91, green: 0.66, blue: 0.49, alpha: 0.4).cgColor)
    context.setLineWidth(size * 0.015)
    
    let lineSpacing = size * 0.1
    for i in 1...4 {
        let y = padRect.minY + CGFloat(i) * lineSpacing
        context.move(to: CGPoint(x: padRect.minX + size * 0.06, y: y))
        context.addLine(to: CGPoint(x: padRect.maxX - size * 0.06, y: y))
    }
    context.strokePath()
    
    // Draw checkmark
    context.setStrokeColor(NSColor(red: 0.255, green: 0.702, blue: 0.639, alpha: 1.0).cgColor) // #41B3A3
    context.setLineWidth(size * 0.05)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    
    let checkStart = CGPoint(x: size * 0.35, y: size * 0.52)
    let checkMid = CGPoint(x: size * 0.45, y: size * 0.42)
    let checkEnd = CGPoint(x: size * 0.65, y: size * 0.65)
    
    context.move(to: checkStart)
    context.addLine(to: checkMid)
    context.addLine(to: checkEnd)
    context.strokePath()
    
    // Add subtle shadow to the notepad
    context.setShadow(offset: CGSize(width: 0, height: -size * 0.02), blur: size * 0.04, color: NSColor.black.withAlphaComponent(0.15).cgColor)
    
    image.unlockFocus()
    
    return image
}

func saveIcon(image: NSImage, to path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG data")
        return
    }
    
    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("Saved: \(path)")
    } catch {
        print("Error saving \(path): \(error)")
    }
}

// Create iconset directory
let iconsetPath = "AppIcon.iconset"
let fm = FileManager.default

if fm.fileExists(atPath: iconsetPath) {
    try? fm.removeItem(atPath: iconsetPath)
}
try! fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

// Generate all required sizes
let sizes: [(name: String, size: CGFloat)] = [
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

for (name, size) in sizes {
    let icon = generateIcon(size: size)
    saveIcon(image: icon, to: "\(iconsetPath)/\(name)")
}

print("\nNow run: iconutil -c icns AppIcon.iconset")
print("This will create AppIcon.icns")

