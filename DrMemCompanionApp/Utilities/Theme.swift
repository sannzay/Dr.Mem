import SwiftUI

enum DrMemTheme {
    static let ivory = Color(red: 0.98, green: 0.96, blue: 0.93)
    static let warmBg = Color(red: 0.97, green: 0.95, blue: 0.91)
    static let terracotta = Color(red: 0.76, green: 0.42, blue: 0.32)
    static let terracottaLight = Color(red: 0.85, green: 0.55, blue: 0.45)
    static let warmGray = Color(red: 0.55, green: 0.52, blue: 0.50)
    static let darkText = Color(red: 0.12, green: 0.11, blue: 0.10)
    static let cardBorder = Color.white.opacity(0.6)
    static let subtleGlow = Color.white.opacity(0.25)
    static let glassFill = Color.white.opacity(0.55)
    static let glassFillDark = Color.black.opacity(0.08)
    static let shadowColor = Color.black.opacity(0.06)

    static let cardGradient = LinearGradient(
        colors: [Color.white.opacity(0.75), Color.white.opacity(0.35), Color.white.opacity(0.20)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let specularHighlight = RadialGradient(
        colors: [Color.white.opacity(0.35), Color.clear],
        center: .topLeading,
        startRadius: 0,
        endRadius: 180
    )

    static let meshBg = MeshGradient(
        width: 3, height: 3,
        points: [
            [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
            [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
            [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
        ],
        colors: [
            Color(red: 0.98, green: 0.95, blue: 0.90),
            Color(red: 0.96, green: 0.93, blue: 0.88),
            Color(red: 0.95, green: 0.91, blue: 0.87),
            Color(red: 0.97, green: 0.94, blue: 0.89),
            Color(red: 0.99, green: 0.97, blue: 0.94),
            Color(red: 0.96, green: 0.92, blue: 0.88),
            Color(red: 0.95, green: 0.92, blue: 0.88),
            Color(red: 0.97, green: 0.94, blue: 0.90),
            Color(red: 0.98, green: 0.96, blue: 0.92)
        ]
    )
}
