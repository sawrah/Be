import SwiftUI

enum AnimationPhase {
    case resting
    case inhale
    case exhaled
}

struct OrbBackgroundView: View {
    let phase: AnimationPhase

    // Each orb gets its own float toggle so they never sync
    @State private var floatGreen  = false
    @State private var floatPurple = false
    @State private var floatCoral  = false

    private var phaseOffset: CGFloat {
        switch phase {
        case .resting: return 0
        case .inhale:  return 30
        case .exhaled: return -280
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                
                
                // AccentColor (coral) — top-left, bleeds off top & left edges
                Circle()
                    .fill(Color("Accent"))
                    .frame(width: w * 0.9, height: w * 0.9)
                    .blur(radius: 50)
                    .offset(
                        x: floatCoral ? -w * 0.22 : -w * 0.32,
                        y: floatCoral ? -h * 0.38 : -h * 0.28
                    )
                    .animation(.easeInOut(duration: 6.5).repeatForever(autoreverses: true), value: floatCoral)
                    .offset(
                        x: phase == .exhaled ? -w * 0.35 : 0,  // ← pushes left on exhale
                        y: phase == .inhale ? 30 : phase == .exhaled ? 300 : 0  // ↓ drops down on exhale
                    )
                
                // BrandPurple — large, center, bleeds edges
                Circle()
                    .fill(Color("BrandPurple"))
                    .frame(width: w * 1.1, height: w * 1.1)
                    .blur(radius: 55)
                    .offset(
                        x: floatPurple ? w * 0.35 : w * 0.25,  // ← pushed more right at rest
                        y: floatPurple ? -h * 0.18 : -h * 0.08  // ← higher up at rest
                    )
                    .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: floatPurple)
                    .offset(
                        x: phase == .exhaled ? -w * 0.4 : 0,   // ← swings left on exhale
                        y: phase == .inhale ? 30 : phase == .exhaled ? -230 : 0  // ↑ goes up on exhale
                    )
                
                // BrandGreen — very large, bottom-center, dominates lower half
                Circle()
                    .fill(Color("BrandGreen"))
                    .frame(width: w * 1.3, height: w * 1.53)
                    .blur(radius: 45)
                    .offset(
                        x: floatGreen ? -w * 0.12 : w * 0.0,
                        y: floatGreen ? h * 0.28 : h * 0.18
                    )
                    .animation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true), value: floatGreen)
                    .offset(
                        x: phase == .exhaled ? w * 0.5 : 0,   // → pushes right on exhale
                        y: phase == .inhale ? 30 : phase == .exhaled ? -280 : 0  // ↑ still goes up
                    )

                
            }
            .frame(width: w, height: h)
            .onAppear {
                // Stagger the starts so they don't accidentally sync
                floatGreen = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7)  { floatPurple = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4)  { floatCoral  = true }
            }
        }
    }
}

#Preview {
    SplashView()
        .environmentObject(AuthManager())
}
