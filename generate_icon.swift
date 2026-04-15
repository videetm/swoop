#!/usr/bin/env swift
import CoreGraphics
import CoreFoundation
import CoreText
import ImageIO
import Foundation

let size = CGSize(width: 1024, height: 1024)
let colorSpace = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(
    data: nil,
    width: Int(size.width),
    height: Int(size.height),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

let w = size.width
let h = size.height

// ── Background gradient: #1a0533 → #0d1f4a ──────────────────────────────────
let bgColors = [
    CGColor(colorSpace: colorSpace, components: [0x1a/255.0, 0x05/255.0, 0x33/255.0, 1])!,
    CGColor(colorSpace: colorSpace, components: [0x0d/255.0, 0x1f/255.0, 0x4a/255.0, 1])!
]
let bgGrad = CGGradient(colorsSpace: colorSpace,
                        colors: bgColors as CFArray,
                        locations: [0, 1])!
ctx.drawLinearGradient(bgGrad,
                       start: CGPoint(x: 0, y: h),
                       end: CGPoint(x: w, y: 0),
                       options: [])

// ── Outer glow ring (blurred halo) ──────────────────────────────────────────
let cx = w / 2, cy = h / 2
let ringRadius: CGFloat = 340
let lineWidth: CGFloat = 72

// Glow: draw several wide, low-alpha strokes behind the ring
for i in 1...4 {
    let extra = CGFloat(i) * 18
    ctx.setLineWidth(lineWidth + extra * 2)
    ctx.setAlpha(0.06)
    ctx.setStrokeColor(CGColor(colorSpace: colorSpace,
                               components: [0xa7/255.0, 0x8b/255.0, 0xfa/255.0, 1])!)
    ctx.addArc(center: CGPoint(x: cx, y: cy),
               radius: ringRadius,
               startAngle: .pi * 0.15,
               endAngle: .pi * 1.85,
               clockwise: false)
    ctx.strokePath()
}
ctx.setAlpha(1.0)

// ── Main ring arc: purple → blue gradient ───────────────────────────────────
// Draw as a stroked arc using a clipping trick
let arcStart: CGFloat = .pi * 0.15   // bottom-right gap
let arcEnd: CGFloat   = .pi * 1.85   // bottom-left gap

// Clip to a thick annulus path so gradient fill becomes a ring stroke
let outerR = ringRadius + lineWidth / 2
let innerR = ringRadius - lineWidth / 2
let clipPath = CGMutablePath()
clipPath.addArc(center: CGPoint(x: cx, y: cy), radius: outerR,
                startAngle: arcStart, endAngle: arcEnd, clockwise: false)
clipPath.addArc(center: CGPoint(x: cx, y: cy), radius: innerR,
                startAngle: arcEnd, endAngle: arcStart, clockwise: true)
clipPath.closeSubpath()

ctx.saveGState()
ctx.addPath(clipPath)
ctx.clip()

// Gradient: swoopPurple #a78bfa → swoopBlue #60a5fa
let ringColors = [
    CGColor(colorSpace: colorSpace, components: [0xa7/255.0, 0x8b/255.0, 0xfa/255.0, 1])!,
    CGColor(colorSpace: colorSpace, components: [0x60/255.0, 0xa5/255.0, 0xfa/255.0, 1])!
]
let ringGrad = CGGradient(colorsSpace: colorSpace,
                          colors: ringColors as CFArray,
                          locations: [0, 1])!
ctx.drawLinearGradient(ringGrad,
                       start: CGPoint(x: cx - ringRadius, y: cy),
                       end: CGPoint(x: cx + ringRadius, y: cy),
                       options: [])
ctx.restoreGState()

// ── Dot cap at start of arc (swoopPink accent) ───────────────────────────────
let dotAngle = arcStart
let dotX = cx + ringRadius * cos(dotAngle)
let dotY = cy + ringRadius * sin(dotAngle)
let dotR = lineWidth / 2
ctx.setFillColor(CGColor(colorSpace: colorSpace,
                         components: [0xf4/255.0, 0x72/255.0, 0xb6/255.0, 1])!)
ctx.addArc(center: CGPoint(x: dotX, y: dotY), radius: dotR,
           startAngle: 0, endAngle: .pi * 2, clockwise: false)
ctx.fillPath()

// ── "S" lettermark in centre ─────────────────────────────────────────────────
let fontSize: CGFloat = 260
let font = CTFontCreateWithName("SF Pro Display" as CFString, fontSize, nil)
let fallbackFont = CTFontCreateWithName("HelveticaNeue-Bold" as CFString, fontSize, nil)
let attrs: [CFString: Any] = [
    kCTFontAttributeName: font,
    kCTForegroundColorAttributeName: CGColor(colorSpace: colorSpace,
                                             components: [1, 1, 1, 0.95])!
]
let attrStr = CFAttributedStringCreate(nil, "S" as CFString, attrs as CFDictionary)!
let line = CTLineCreateWithAttributedString(attrStr)
let bounds = CTLineGetImageBounds(line, ctx)
let tx = cx - bounds.width / 2 - bounds.origin.x
let ty = cy - bounds.height / 2 - bounds.origin.y
ctx.textPosition = CGPoint(x: tx, y: ty)
CTLineDraw(line, ctx)

// ── Export PNG ────────────────────────────────────────────────────────────────
let image = ctx.makeImage()!
let outputURL = URL(fileURLWithPath: "Swoop/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
let dest = CGImageDestinationCreateWithURL(outputURL as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("✓ Icon saved to \(outputURL.path)")
