import SwiftUI
import AppKit

/// Catppuccin-inspired semantic palette.
/// - Dark mode uses Catppuccin Mocha.
/// - Light mode uses Catppuccin Latte.
/// Applied subtly: window background + accent tint + status colors.
/// Native SwiftUI section materials (Form.grouped) are kept for Mac feel.
enum Theme {
    // Accent / interactive
    static let accent  = dynamic(dark: 0xcba6f7, light: 0x8839ef)  // Mauve

    // Status
    static let active  = dynamic(dark: 0xa6e3a1, light: 0x40a02b)  // Green
    static let paused  = dynamic(dark: 0xfab387, light: 0xfe640b)  // Peach
    static let danger  = dynamic(dark: 0xf38ba8, light: 0xd20f39)  // Red
    static let info    = dynamic(dark: 0x89b4fa, light: 0x1e66f5)  // Blue

    // Surfaces
    static let windowBackground = dynamic(dark: 0x1e1e2e, light: 0xeff1f5)  // Base
    static let elevated         = dynamic(dark: 0x313244, light: 0xccd0da)  // Surface0

    // MARK: - Dynamic color helper

    private static func dynamic(dark: UInt32, light: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = (appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua)
            return NSColor(hex: isDark ? dark : light)
        })
    }
}

private extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xff) / 255.0
        let g = CGFloat((hex >> 8) & 0xff) / 255.0
        let b = CGFloat(hex & 0xff) / 255.0
        self.init(srgbRed: r, green: g, blue: b, alpha: alpha)
    }
}
