//
//  GenerateAppIcon.swift
//  Tools — genereert het app-icoon (1024×1024, opaque) per ASSETS-brief.
//  Motief: "retour-doos" (product teruggeroepen) — SF Symbol shippingbox.and.arrow.backward,
//  gecentreerd in wit op een teal achtergrond. Geen rood.
//  Draai per appearance:
//    swift Tools/GenerateAppIcon.swift light  <out.png>
//    swift Tools/GenerateAppIcon.swift dark   <out.png>
//    swift Tools/GenerateAppIcon.swift tinted <out.png>
//

import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let mode = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "light"
let outPath = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "AppIcon.png"

let S = 1024
let cs = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(data: nil, width: S, height: S, bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!  // opaque, geen alpha
func hex(_ h: Int) -> CGColor { CGColor(colorSpace: cs, components: [Double((h>>16)&0xFF)/255, Double((h>>8)&0xFF)/255, Double(h&0xFF)/255, 1])! }

let bgTop: CGColor, bgBot: CGColor
let symColor: NSColor
switch mode {
case "dark":   bgTop = hex(0x0B3E3D); bgBot = hex(0x0F1413); symColor = NSColor(white: 0.94, alpha: 1)
case "tinted": bgTop = hex(0x111111); bgBot = hex(0x000000); symColor = NSColor(white: 0.96, alpha: 1)
default:       bgTop = hex(0x0E7C7B); bgBot = hex(0x0B6463); symColor = NSColor(white: 0.97, alpha: 1)
}

// Achtergrond (vol vlak, opaque).
let grad = CGGradient(colorsSpace: cs, colors: [bgTop, bgBot] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: Double(S)), end: CGPoint(x: 0, y: 0), options: [])

// SF Symbol → CGImage, gecentreerd.
let cfg = NSImage.SymbolConfiguration(pointSize: Double(S) * 0.46, weight: .medium)
    .applying(NSImage.SymbolConfiguration(paletteColors: [symColor]))
let nsImage = NSImage(systemSymbolName: "shippingbox.and.arrow.backward", accessibilityDescription: nil)!
    .withSymbolConfiguration(cfg)!
var rect = CGRect(x: 0, y: 0, width: nsImage.size.width, height: nsImage.size.height)
let symbol = nsImage.cgImage(forProposedRect: &rect, context: nil, hints: nil)!
let sw = Double(symbol.width), sh = Double(symbol.height)
ctx.draw(symbol, in: CGRect(x: (Double(S)-sw)/2, y: (Double(S)-sh)/2, width: sw, height: sh))

let image = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: outPath) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("icoon (\(mode)) geschreven: \(outPath)")
