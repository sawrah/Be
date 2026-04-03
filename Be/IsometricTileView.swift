import SwiftUI

struct IsometricTileView: View {
    let theme: TileTheme
    let origin: CGPoint

    var body: some View {
        let s = tileScale
        let ox = origin.x
        let oy = origin.y

        // Draw layers back to front: bottomLeft, bottomRight, topLeft, topRight, divider, top
        ZStack {
            if theme.style == .zigzag {
                zigzagTile(s: s, ox: ox, oy: oy)
            } else {
                waveTile(s: s, ox: ox, oy: oy)
            }
        }
    }

    // MARK: - Zigzag

    @ViewBuilder
    private func zigzagTile(s: CGFloat, ox: CGFloat, oy: CGFloat) -> some View {
        // bottomLeft
        Path { p in
            p.move(to: pt(27.15, 68.5, s, ox, oy))
            p.addLine(to: pt(21.75, 72.8, s, ox, oy))
            p.addLine(to: pt(16.3, 63.05, s, ox, oy))
            p.addLine(to: pt(10.9, 67.35, s, ox, oy))
            p.addLine(to: pt(5.5, 57.65, s, ox, oy))
            p.addLine(to: pt(0, 61.95, s, ox, oy))
            p.addLine(to: pt(0, 72.75, s, ox, oy))
            p.addLine(to: pt(32.55, 89, s, ox, oy))
            p.addLine(to: pt(32.55, 78.2, s, ox, oy))
            p.closeSubpath()
        }
        .fill(theme.bottomLeft)

        // bottomRight
        Path { p in
            p.move(to: pt(32.55, 89, s, ox, oy))
            p.addLine(to: pt(65, 72.75, s, ox, oy))
            p.addLine(to: pt(65, 61.95, s, ox, oy))
            p.addLine(to: pt(59.6, 57.65, s, ox, oy))
            p.addLine(to: pt(54.2, 67.35, s, ox, oy))
            p.addLine(to: pt(48.8, 63.05, s, ox, oy))
            p.addLine(to: pt(43.35, 72.8, s, ox, oy))
            p.addLine(to: pt(37.95, 68.5, s, ox, oy))
            p.addLine(to: pt(32.55, 78.2, s, ox, oy))
            p.closeSubpath()
        }
        .fill(theme.bottomRight)

        // topLeft
        Path { p in
            p.move(to: pt(0, 50.75, s, ox, oy))
            p.addLine(to: pt(0, 61.95, s, ox, oy))
            p.addLine(to: pt(5.5, 57.65, s, ox, oy))
            p.addLine(to: pt(10.9, 67.35, s, ox, oy))
            p.addLine(to: pt(16.3, 63.05, s, ox, oy))
            p.addLine(to: pt(21.75, 72.8, s, ox, oy))
            p.addLine(to: pt(27.15, 68.5, s, ox, oy))
            p.addLine(to: pt(32.55, 78.2, s, ox, oy))
            p.addLine(to: pt(32.55, 67, s, ox, oy))
            p.closeSubpath()
        }
        .fill(theme.topLeft)

        // topRight
        Path { p in
            p.move(to: pt(32.55, 78.2, s, ox, oy))
            p.addLine(to: pt(37.95, 68.5, s, ox, oy))
            p.addLine(to: pt(43.35, 72.8, s, ox, oy))
            p.addLine(to: pt(48.8, 63.05, s, ox, oy))
            p.addLine(to: pt(54.2, 67.35, s, ox, oy))
            p.addLine(to: pt(59.6, 57.65, s, ox, oy))
            p.addLine(to: pt(65, 61.95, s, ox, oy))
            p.addLine(to: pt(65, 50.75, s, ox, oy))
            p.addLine(to: pt(32.55, 67, s, ox, oy))
            p.closeSubpath()
        }
        .fill(theme.topRight)

        // divider
        Path { p in
            p.move(to: pt(65, 50.75, s, ox, oy))
            p.addLine(to: pt(32.55, 67, s, ox, oy))
            p.addLine(to: pt(0, 50.75, s, ox, oy))
            p.addLine(to: pt(0, 48.75, s, ox, oy))
            p.addLine(to: pt(32.55, 65, s, ox, oy))
            p.addLine(to: pt(65, 48.75, s, ox, oy))
            p.closeSubpath()
        }
        .fill(theme.divider)

        // top
        Path { p in
            p.move(to: pt(0, 48.75, s, ox, oy))
            p.addLine(to: pt(0, 16.25, s, ox, oy))
            p.addLine(to: pt(32.55, 0, s, ox, oy))
            p.addLine(to: pt(65, 16.25, s, ox, oy))
            p.addLine(to: pt(65, 48.75, s, ox, oy))
            p.addLine(to: pt(32.55, 65, s, ox, oy))
            p.closeSubpath()
        }
        .fill(theme.top)
    }

    // MARK: - Wave

    @ViewBuilder
    private func waveTile(s: CGFloat, ox: CGFloat, oy: CGFloat) -> some View {
        // bottomLeft
        Path { p in
            p.move(to: pt(32.55, 75.8999, s, ox, oy))
            p.addCurve(
                to: pt(5.25, 66.6499, s, ox, oy),
                control1: pt(24.7, 69.3499, s, ox, oy),
                control2: pt(12.25, 69.7501, s, ox, oy)
            )
            p.addLine(to: pt(0, 61.6499, s, ox, oy))
            p.addLine(to: pt(0, 72.7499, s, ox, oy))
            p.addLine(to: pt(32.55, 88.9999, s, ox, oy))
            p.closeSubpath()
        }
        .fill(theme.bottomLeft)

        // bottomRight
        Path { p in
            p.move(to: pt(32.55, 88.9997, s, ox, oy))
            p.addLine(to: pt(65, 72.7497, s, ox, oy))
            p.addLine(to: pt(65, 61.7497, s, ox, oy))
            p.addCurve(
                to: pt(32.55, 75.9042, s, ox, oy),
                control1: pt(55.1, 61.7, s, ox, oy),
                control2: pt(40.0958, 75.9042, s, ox, oy)
            )
            p.closeSubpath()
        }
        .fill(theme.bottomRight)

        // topLeft
        Path { p in
            p.move(to: pt(32.55, 66.95, s, ox, oy))
            p.addLine(to: pt(0, 50.75, s, ox, oy))
            p.addLine(to: pt(0, 61.65, s, ox, oy))
            p.addCurve(
                to: pt(16.25, 68.75, s, ox, oy),
                control1: pt(5.25, 66.65, s, ox, oy),
                control2: pt(12.9167, 70.0833, s, ox, oy)
            )
            p.addCurve(
                to: pt(32.55, 75.9, s, ox, oy),
                control1: pt(23.0667, 68.6167, s, ox, oy),
                control2: pt(30.0167, 72.7333, s, ox, oy)
            )
            p.closeSubpath()
        }
        .fill(theme.topLeft)

        // topRight
        Path { p in
            p.move(to: pt(48.8, 68.8, s, ox, oy))
            p.addCurve(
                to: pt(65, 61.75, s, ox, oy),
                control1: pt(54.8, 62.1, s, ox, oy),
                control2: pt(60.0667, 59.8833, s, ox, oy)
            )
            p.addLine(to: pt(65, 50.75, s, ox, oy))
            p.addLine(to: pt(32.55, 66.95, s, ox, oy))
            p.addLine(to: pt(32.55, 75.95, s, ox, oy))
            p.addCurve(
                to: pt(48.8, 68.8, s, ox, oy),
                control1: pt(37.8, 76.3, s, ox, oy),
                control2: pt(45.4667, 73.0333, s, ox, oy)
            )
            p.closeSubpath()
        }
        .fill(theme.topRight)

        // divider
        Path { p in
            p.move(to: pt(65, 50.75, s, ox, oy))
            p.addLine(to: pt(32.15, 66.8, s, ox, oy))
            p.addLine(to: pt(0, 50.75, s, ox, oy))
            p.addLine(to: pt(0, 48.75, s, ox, oy))
            p.addLine(to: pt(32.55, 65, s, ox, oy))
            p.addLine(to: pt(65, 48.75, s, ox, oy))
            p.closeSubpath()
        }
        .fill(theme.divider)

        // top
        Path { p in
            p.move(to: pt(0, 48.75, s, ox, oy))
            p.addLine(to: pt(0, 16.25, s, ox, oy))
            p.addLine(to: pt(32.55, 0, s, ox, oy))
            p.addLine(to: pt(65, 16.25, s, ox, oy))
            p.addLine(to: pt(65, 48.75, s, ox, oy))
            p.addLine(to: pt(32.55, 65, s, ox, oy))
            p.closeSubpath()
        }
        .fill(theme.top)
    }

    // MARK: - Helper

    private func pt(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ ox: CGFloat, _ oy: CGFloat) -> CGPoint {
        CGPoint(x: ox + x * s, y: oy + y * s)
    }
}
