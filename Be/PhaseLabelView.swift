import SwiftUI

struct PhaseLabelView: View {
    let phase: BreathingPhase
    let inhaleDuration: Double
    let exhaleDuration: Double

    @State private var progress: CGFloat = 0

    private var duration: Double {
        phase == .inhale ? inhaleDuration : exhaleDuration
    }

    var body: some View {
        ZStack {
            // dim base
            Text(phase == .inhale ? "Inhale" : "Exhale")
                .font(.system(size:48, design: .serif).weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))

            // bright masked overlay
            Text(phase == .inhale ? "Inhale" : "Exhale")
                .font(.system(size:48, design: .serif).weight(.semibold))
                .foregroundStyle(.white)
                .mask(
                    Group {
                        if phase == .inhale {
                            InhaleRevealShape(progress: progress)
                        } else {
                            ExhaleRevealShape(progress: progress)
                        }
                    }
                )
        }
        .onAppear { triggerAnimation() }
    }

    private func triggerAnimation() {
        progress = 0
        withAnimation(.easeInOut(duration: duration)) {
            progress = 1
        }
    }
}
