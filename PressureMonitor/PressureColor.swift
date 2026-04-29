import SwiftUI
import AppKit

// MARK: - Pressure → Color mapping
//
//  < 29.70 inHg  →  red          (very low / storm)
//   29.70–29.92  →  blue → white (low)
//   29.92–30.12  →  white        (neutral)
//   30.12–30.40  →  white → orange (high)
//  > 30.40 inHg  →  orange

func pressureColor(_ inhg: Double) -> Color {
    Color(nsColor: nsColor(for: inhg))
}

private func nsColor(for inhg: Double) -> NSColor {
    switch inhg {
    case ..<29.70:
        return .systemRed

    case 29.70..<29.92:
        let t = (inhg - 29.70) / (29.92 - 29.70)
        return blend(.systemBlue, .white, t: t)

    case 29.92..<30.12:
        return .white

    case 30.12..<30.40:
        let t = (inhg - 30.12) / (30.40 - 30.12)
        return blend(.white, .systemOrange, t: t)

    default: // >= 30.40
        return .systemOrange
    }
}

private func blend(_ a: NSColor, _ b: NSColor, t: Double) -> NSColor {
    guard let a = a.usingColorSpace(.sRGB),
          let b = b.usingColorSpace(.sRGB)
    else { return a }
    return NSColor(
        red:   lerp(a.redComponent,   b.redComponent,   t: t),
        green: lerp(a.greenComponent, b.greenComponent, t: t),
        blue:  lerp(a.blueComponent,  b.blueComponent,  t: t),
        alpha: 1
    )
}

private func lerp(_ a: CGFloat, _ b: CGFloat, t: Double) -> CGFloat {
    a + (b - a) * CGFloat(t)
}

// MARK: - Gradient covering the full scale (for chart backgrounds etc.)

extension Gradient {
    static var pressureScale: Gradient {
        Gradient(stops: [
            .init(color: pressureColor(29.40), location: 0.0),
            .init(color: pressureColor(29.70), location: 0.2),
            .init(color: pressureColor(29.92), location: 0.4),
            .init(color: pressureColor(30.12), location: 0.6),
            .init(color: pressureColor(30.40), location: 0.8),
            .init(color: pressureColor(30.60), location: 1.0),
        ])
    }
}
