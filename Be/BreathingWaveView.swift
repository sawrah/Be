import SwiftUI

struct BreathingWaveView: View {
    let sessionElapsed: Double
    let totalDuration: Double
    let inhaleDuration: Double
    let exhaleDuration: Double
    let phase: BreathingPhase

    private let amplitude: CGFloat = 56.0
    private let pointsPerSecond: CGFloat = 30.0
    private let dotRadius: CGFloat = 8.0
    private let strokeWidth: CGFloat = 8.0
    private let timeStep: Double = 0.05

    var body: some View {
        Canvas { context, size in
            let centerY = size.height / 2
            let viewCenterX = size.width / 2
            let offsetX = viewCenterX - CGFloat(sessionElapsed) * pointsPerSecond

            // 1. Draw the FULL Background Wave (The "Track")
            let fullPath = buildWavePath(from: 0, to: totalDuration, offsetX: offsetX, centerY: centerY)
            context.stroke(
                fullPath,
                with: .color(.white.opacity(0.45)),
                style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
            )

            // 2. Calculate the start time of the current phase
            let cycleDuration = inhaleDuration + exhaleDuration
            let cycleTime = sessionElapsed.truncatingRemainder(dividingBy: cycleDuration)
            let phaseStartTime = sessionElapsed - (cycleTime < inhaleDuration ? cycleTime : (cycleTime - inhaleDuration))
            
            

            // 3. Build and Draw the ACTIVE Path (No clipping needed!)
            let activePath = buildWavePath(
                from: max(0, phaseStartTime),
                to: sessionElapsed,
                offsetX: offsetX,
                centerY: centerY
            )
            
            let currentPhaseColor = phase == .exhale ? Color("BrandGreen") : Color("BrandPurple")

            // --- START OF POINT 4 (Shadow/Glow) ---
            var activeContext = context
            // This adds a soft glow using the current phase color
            activeContext.addFilter(.shadow(color: currentPhaseColor.opacity(0.6), radius: 6))

            activeContext.stroke(
                activePath,
                with: .color(currentPhaseColor),
                style: StrokeStyle(
                    lineWidth: strokeWidth,
                    lineCap: .round,
                    lineJoin: .round
                )
            )

            // --- Future portion (right of center): white at low opacity ---
            let futureClipRect = CGRect(
                x: viewCenterX, y: 0,
                width: size.width - viewCenterX, height: size.height
            )
            var futureContext = context
            futureContext.clip(to: Path(futureClipRect))
            futureContext.stroke(
                fullPath,
                with: .color(.white.opacity(0.45)),
                lineWidth: strokeWidth
            )

            // --- Glow ring around dot ---
            let dotY = centerY - waveY(at: sessionElapsed)
            let glowRect = CGRect(
                x: viewCenterX - dotRadius - 3,
                y: dotY - dotRadius - 3,
                width: (dotRadius + 3) * 2,
                height: (dotRadius + 3) * 2
            )
            context.stroke(
                Path(ellipseIn: glowRect),
                with: .color(Color("BrandGreen").opacity(0.35)),
                lineWidth: 2.5
            )

            // --- Dot at current position ---
            let shadowColor = phase == .exhale ? Color("BrandGreen") : Color("BrandPurple")

            // 2. Create a specific context for the dot to apply the shadow
            var dotContext = context
            dotContext.addFilter(.shadow(color: shadowColor, radius: 12, x: 0, y: 0))

            // 3. Define the Dot Rect
            let dotRect = CGRect(
                x: viewCenterX - dotRadius,
                y: dotY - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            )

            // 4. Fill with Surface Color (This stays constant)
            // Note: Ensure Color("Surface") is defined in your Assets
            dotContext.fill(
                Path(ellipseIn: dotRect),
                with: .color(Color("Surface"))
            )
        }
        .frame(height: amplitude * 2 + dotRadius * 2 + 16)
        .padding(.horizontal, 16)
        .clipped()
    }

    // MARK: - Wave Path

    private func buildWavePath(
        from startTime: Double,
        to endTime: Double,
        offsetX: CGFloat,
        centerY: CGFloat
    ) -> Path {
        var path = Path()
        var firstPoint = true
        
        // Use a small stride to ensure the curve is smooth
        for t in stride(from: startTime, through: endTime, by: timeStep) {
            let x = offsetX + CGFloat(t) * pointsPerSecond
            let y = centerY - waveY(at: t)

            if firstPoint {
                path.move(to: CGPoint(x: x, y: y))
                firstPoint = false
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }

    // MARK: - Wave Math

    private func waveY(at t: Double) -> CGFloat {
        guard t >= 0, t <= totalDuration else { return 0 }

        let cycleDuration = inhaleDuration + exhaleDuration
        let cycleTime = t.truncatingRemainder(dividingBy: cycleDuration)

        if cycleTime < inhaleDuration {
            // --- INHALE (Bottom to Top) ---
            let fraction = cycleTime / inhaleDuration
            // Map 0...1 to -π/2...π/2 (The upward slope of a sine wave)
            let angle = -(.pi / 2) + (fraction * .pi)
            return CGFloat(sin(angle)) * amplitude
        } else {
            // --- EXHALE (Top to Bottom) ---
            let fraction = (cycleTime - inhaleDuration) / exhaleDuration
            // Map 0...1 to π/2...3π/2 (The downward slope of a sine wave)
            let angle = (.pi / 2) + (fraction * .pi)
            return CGFloat(sin(angle)) * amplitude
        }
    }
}
