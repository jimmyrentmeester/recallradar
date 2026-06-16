//
//  GenerateAppIcon.swift
//  Tools — genereert het 1024×1024 (opaque) app-icoon via CoreGraphics.
//  Draai:  swift Tools/GenerateAppIcon.swift RecallRadar/Assets.xcassets/AppIcon.appiconset/AppIcon.png
//  App Store-iconen mogen GEEN alpha hebben → we renderen volledig opaque.
//

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let outPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "AppIcon.png"

let S = 1024
let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: S, height: S, bitsPerComponent: 8, bytesPerRow: 0,
                          space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    fatalError("geen context")
}

func rgb(_ r: Double, _ g: Double, _ b: Double) -> CGColor {
    CGColor(colorSpace: cs, components: [r, g, b, 1])!
}

// Achtergrond: diagonale gradient (indigo → teal) — vertrouwd, modern.
let grad = CGGradient(colorsSpace: cs,
                      colors: [rgb(0.13, 0.22, 0.55), rgb(0.08, 0.62, 0.66)] as CFArray,
                      locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: S), end: CGPoint(x: S, y: 0), options: [])

let center = CGPoint(x: 512, y: 470)

// Radar-ringen.
ctx.setLineWidth(10)
for r in [150.0, 270.0, 390.0] {
    ctx.setStrokeColor(rgb(1, 1, 1).copy(alpha: 0.28)!)
    ctx.addArc(center: center, radius: r, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.strokePath()
}
// Dradenkruis.
ctx.setStrokeColor(rgb(1, 1, 1).copy(alpha: 0.18)!)
ctx.setLineWidth(6)
ctx.move(to: CGPoint(x: center.x - 390, y: center.y)); ctx.addLine(to: CGPoint(x: center.x + 390, y: center.y))
ctx.move(to: CGPoint(x: center.x, y: center.y - 390)); ctx.addLine(to: CGPoint(x: center.x, y: center.y + 390))
ctx.strokePath()

// Sweep-wig (radar-veeg) met fade.
ctx.saveGState()
ctx.move(to: center)
ctx.addArc(center: center, radius: 390, startAngle: .pi * 0.16, endAngle: -.pi * 0.20, clockwise: true)
ctx.closePath()
ctx.clip()
let sweep = CGGradient(colorsSpace: cs,
                       colors: [rgb(1, 1, 1).copy(alpha: 0.0)!, rgb(1, 1, 1).copy(alpha: 0.34)!] as CFArray,
                       locations: [0, 1])!
ctx.drawLinearGradient(sweep, start: center,
                       end: CGPoint(x: center.x + 380, y: center.y - 120), options: [])
ctx.restoreGState()

// De "blip" die de radar opvangt — alert-accent met gloed.
let blip = CGPoint(x: center.x + 150, y: center.y + 95)
let glow = CGGradient(colorsSpace: cs,
                      colors: [rgb(1.0, 0.42, 0.32).copy(alpha: 0.9)!, rgb(1.0, 0.42, 0.32).copy(alpha: 0)!] as CFArray,
                      locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: blip, startRadius: 0, endCenter: blip, endRadius: 130, options: [])
ctx.setFillColor(rgb(1.0, 0.36, 0.28))
ctx.addArc(center: blip, radius: 46, startAngle: 0, endAngle: .pi * 2, clockwise: false)
ctx.fillPath()

guard let image = ctx.makeImage() else { fatalError("geen image") }
let url = URL(fileURLWithPath: outPath)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("geen destination")
}
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("icoon geschreven: \(outPath)")
