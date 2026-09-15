import AppKit
import CoreGraphics

/// Gera o iconset do Ember. Desenhado por código para que qualquer ajuste seja
/// um diff revisável e as dez resoluções saiam sempre consistentes.
///
/// A forma: uma brasa acesa sobre fundo escuro — o que fica queimando enquanto
/// o resto descansa.
func drawIcon(size: CGFloat, context ctx: CGContext) {
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    ctx.setAllowsAntialiasing(true)

    let inset = size * 0.086
    let plate = rect.insetBy(dx: inset, dy: inset)
    let radius = plate.width * 0.2237
    let shape = CGPath(roundedRect: plate, cornerWidth: radius, cornerHeight: radius, transform: nil)

    // Fundo: carvão, quase preto, esquentando de baixo para cima.
    ctx.saveGState()
    ctx.addPath(shape)
    ctx.clip()
    let bg = [
        NSColor(srgbRed: 0.12, green: 0.11, blue: 0.13, alpha: 1).cgColor,
        NSColor(srgbRed: 0.18, green: 0.13, blue: 0.13, alpha: 1).cgColor,
        NSColor(srgbRed: 0.28, green: 0.15, blue: 0.11, alpha: 1).cgColor,
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: bg, locations: [0, 0.6, 1]) {
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: plate.maxY),
                               end: CGPoint(x: 0, y: plate.minY),
                               options: [])
    }

    // O brilho da brasa: um halo radial quente, bem embaixo do centro.
    let heart = CGPoint(x: rect.midX, y: rect.midY - size * 0.04)
    let glow = [
        NSColor(srgbRed: 1.0, green: 0.86, blue: 0.45, alpha: 0.95).cgColor,
        NSColor(srgbRed: 1.0, green: 0.52, blue: 0.13, alpha: 0.75).cgColor,
        NSColor(srgbRed: 0.85, green: 0.20, blue: 0.05, alpha: 0.0).cgColor,
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: glow, locations: [0, 0.35, 1]) {
        ctx.drawRadialGradient(gradient,
                               startCenter: heart, startRadius: 0,
                               endCenter: heart, endRadius: size * 0.34,
                               options: [])
    }

    // A chama: uma gota assimétrica, mais estreita em cima.
    let flame = CGMutablePath()
    let base = size * 0.17
    flame.move(to: CGPoint(x: rect.midX, y: heart.y + size * 0.20))
    flame.addCurve(to: CGPoint(x: rect.midX + base, y: heart.y - size * 0.02),
                   control1: CGPoint(x: rect.midX + base * 0.55, y: heart.y + size * 0.13),
                   control2: CGPoint(x: rect.midX + base, y: heart.y + size * 0.08))
    flame.addCurve(to: CGPoint(x: rect.midX, y: heart.y - size * 0.15),
                   control1: CGPoint(x: rect.midX + base, y: heart.y - size * 0.10),
                   control2: CGPoint(x: rect.midX + base * 0.5, y: heart.y - size * 0.15))
    flame.addCurve(to: CGPoint(x: rect.midX - base, y: heart.y - size * 0.02),
                   control1: CGPoint(x: rect.midX - base * 0.5, y: heart.y - size * 0.15),
                   control2: CGPoint(x: rect.midX - base, y: heart.y - size * 0.10))
    flame.addCurve(to: CGPoint(x: rect.midX, y: heart.y + size * 0.20),
                   control1: CGPoint(x: rect.midX - base, y: heart.y + size * 0.08),
                   control2: CGPoint(x: rect.midX - base * 0.55, y: heart.y + size * 0.13))
    flame.closeSubpath()

    ctx.saveGState()
    ctx.addPath(flame)
    ctx.clip()
    let fire = [
        NSColor(srgbRed: 1.0, green: 0.95, blue: 0.80, alpha: 1).cgColor,
        NSColor(srgbRed: 1.0, green: 0.70, blue: 0.22, alpha: 1).cgColor,
        NSColor(srgbRed: 0.93, green: 0.33, blue: 0.08, alpha: 1).cgColor,
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: fire, locations: [0, 0.5, 1]) {
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: heart.y + size * 0.20),
                               end: CGPoint(x: 0, y: heart.y - size * 0.15),
                               options: [])
    }
    ctx.restoreGState()

    // Brilho interno, para a chama não ficar chapada.
    let core = CGRect(x: rect.midX - size * 0.045, y: heart.y - size * 0.085,
                      width: size * 0.09, height: size * 0.15)
    ctx.setFillColor(NSColor(srgbRed: 1, green: 1, blue: 0.92, alpha: 0.85).cgColor)
    ctx.addEllipse(in: core)
    ctx.fillPath()

    ctx.restoreGState()

    // Aro sutil, como nos outros ícones da família.
    ctx.addPath(shape)
    ctx.setStrokeColor(NSColor(white: 1, alpha: 0.10).cgColor)
    ctx.setLineWidth(max(1, size * 0.006))
    ctx.strokePath()
}

let sizes: [(name: String, px: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Ember.iconset"
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)

for (name, px) in sizes {
    guard let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8,
                              bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { continue }
    drawIcon(size: CGFloat(px), context: ctx)
    guard let image = ctx.makeImage() else { continue }
    let url = URL(fileURLWithPath: "\(out)/\(name).png")
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)
    else { continue }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}
print(out)
