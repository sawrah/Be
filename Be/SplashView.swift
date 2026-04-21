import SwiftUI
// TODO: import AuthenticationServices — uncomment when ready for real Sign in with Apple

struct SplashView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var phase: AnimationPhase = .resting
    @State private var showSignIn = false

    private var logoWidth: CGFloat { phase == .exhaled ? 85 : 120 }
    private var logoOffsetY: CGFloat {
        switch phase {
        case .resting: return 0
        case .inhale:  return 12
        case .exhaled: return -240
        }
    }

    var body: some View {
        ZStack {
            Color("Surface").ignoresSafeArea()

            OrbBackgroundView(phase: phase).ignoresSafeArea()

            // Logo — centered in resting state, animates to top on exhale
            VStack {
                Spacer()
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: logoWidth)
                
                Text("Simple breathing exercises.\n A space to come back to yourself.")
                    .font(.callout)
                    .italic()
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .opacity(showSignIn ? 1 : 0)
                
                Spacer()
                
                
                
            }
            .offset(y: logoOffsetY)

            // Sign-in content — slides up from bottom after exhale
            VStack(spacing: 0) {
                Spacer()
                
                Image("line-art meditating")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350)
                    .opacity(showSignIn ? 1 : 0)

                Spacer().frame(height: 100)

                if showSignIn {
                    VStack(spacing: 14) {
                        // TODO: Replace with SignInWithAppleButton when developer account is set up
                        Button {
                            authManager.showOnboarding = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "applelogo")
                                Text("Sign in with Apple")
                                    .font(.body.weight(.semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 45)
                            .background(Color.black)
                            .cornerRadius(27)
                        }

                        Text("By signing in, you agree to our Terms of Service and Privacy Policy.")
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 280)
                    }
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer().frame(height: 60)
            }
        }
        .onAppear { startBreathingAnimation() }
    }

    private func startBreathingAnimation() {
        // 1. Rest for 1.2s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            // 2. Inhale — logo drifts slightly down
            withAnimation(.easeIn(duration: 0.4)) { phase = .inhale }

            // 3. Exhale — logo rises to top, orbs shift up
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.9)) { phase = .exhaled }

                // 4. Reveal illustration + sign-in button
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeOut(duration: 0.5)) { showSignIn = true }
                }
            }
        }
    }
}

#Preview {
    SplashView()
        .environmentObject(AuthManager())
}
