//
//  GenerateAppIcon.swift
//  Tools — genereert het app-icoon (1024×1024, opaque) per ASSETS_Recall-Radar.md:
//  radarveeg in licht teal op teal-achtergrond + één amber detectie-stip. GEEN rood.
//  Draai per appearance:
//    swift Tools/GenerateAppIcon.swift light  <out.png>
//    swift Tools/GenerateAppIcon.swift dark   <out.png>
//    swift Tools/GenerateAppIcon.swift tinted <out.png>
//

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let mode = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "light"
let outPath = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "AppIcon.png"

let S = 1024
let cs = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(data: nil, width: S, height: S, bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
func rgb(_ r: Double, _ g: Double, _ b: Double) -> CGColor { CGColor(colorSpace: cs, components: [r, g, b, 1])! }
func hex(_ h: Int) -> CGColor { rgb(Double((h>>16)&0xFF)/255, Double((h>>8)&0xFF)/255, Double(h&0xFF)/255) }

// Palet per appearance.
let tinted = (mode == "tinted")
let bgTop: CGColor, bgBot: CGColor, motif: CGColor
let showAmber: Bool
switch mode {
case "dark":   bgTop = hex(0x0B3E3D); bgBot = hex(0x0F1413); motif = hex(0xCFEFEE); showAmber = true
case "tinted": bgTop = hex(0x111111); bgBot = hex(0x000000); motif = hex(0xF2F2F2); showAmber = false
default:       bgTop = hex(0x0E7C7B); bgBot = hex(0x0B6463); motif = hex(0xEAF6F5); showAmber = true
}

// Achtergrond — verticale gradient, volledig vlak (geen transparante hoeken).
let grad = CGGradient(colorsSpace: cs, colors: [bgTop, bgBot] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: S), end: CGPoint(x: 0, y: 0), options: [])

let center = CGPoint(x: 512, y: 470)
func motifAlpha(_ a: Double) -> CGColor { motif.copy(alpha: a)! }

// Radar-ringen (concentrisch) + dradenkruis.
ctx.setLineWidth(11)
for r in [150.0, 280.0, 410.0] {
    ctx.setStrokeColor(motifAlpha(0.45))
    ctx.addArc(center: center, radius: r, startAngle: 0, endAngle: .pi*2, clockwise: false)
    ctx.strokePath()
}
ctx.setStrokeColor(motifAlpha(0.28)); ctx.setLineWidth(7)
ctx.move(to: CGPoint(x: center.x-410, y: center.y)); ctx.addLine(to: CGPoint(x: center.x+410, y: center.y))
ctx.move(to: CGPoint(x: center.x, y: center.y-410)); ctx.addLine(to: CGPoint(x: center.x, y: center.y+410))
ctx.strokePath()

// Sweep-wig (radar-veeg) met fade.
ctx.saveGState()
ctx.move(to: center)
ctx.addArc(center: center, radius: 410, startAngle: .pi*0.18, endAngle: -.pi*0.22, clockwise: true)
ctx.closePath(); ctx.clip()
let sweep = CGGradient(colorsSpace: cs, colors: [motifAlpha(0.0), motifAlpha(0.40)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(sweep, start: center, end: CGPoint(x: center.x+400, y: center.y-130), options: [])
ctx.restoreGState()

// Detectie-stip — amber (geen rood). In tinted weglaten (monochroom).
let blip = CGPoint(x: center.x+165, y: center.y+105)
if showAmber {
    let amber = hex(0xE0A04A)
    let glow = CGGradient(colorsSpace: cs, colors: [amber.copy(alpha: 0.85)!, amber.copy(alpha: 0)!] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(glow, startCenter: blip, startRadius: 0, endCenter: blip, endRadius: 150, options: [])
    ctx.setFillColor(amber)
} else {
    ctx.setFillColor(motifAlpha(0.95))
}
ctx.addArc(center: blip, radius: 50, startAngle: 0, endAngle: .pi*2, clockwise: false)
ctx.fillPath()

let image = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: outPath) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("icoon (\(mode)) geschreven: \(outPath)")
