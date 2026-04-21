import SwiftUI
import DotLottie

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var currentSlide: Int = 0
    @State private var transitionCircleVisible: Bool = false
    @State private var transitionCircleScale: CGFloat = 0.001
    @State private var slide2Visible: Bool = false
    @State private var slide2Opacity: Double = 0
    @State private var slide3Visible: Bool = false
    @State private var showIntroText: Bool = true
    @State private var introTextOpacity: Double = 1

    var body: some View {
        ZStack {
            if currentSlide == 0 {
                slide1
            }

            if transitionCircleVisible {
                Circle()
                    .fill(Color(hex: "#552E80"))
                    .frame(width: 300, height: 300)
                    .scaleEffect(transitionCircleScale)
                    .allowsHitTesting(false)
            }

            if slide2Visible {
                slide2
                    .opacity(slide2Opacity)
            }

            if slide3Visible {
                slide3
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Slide 1

    private var slide1: some View {
        ZStack {
            Color("Surface").ignoresSafeArea()

            DotLottieAnimation(
                fileName: "breathing",
                config: AnimationConfig(autoplay: true, loop: false)
            ).view()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()

            VStack {
                if showIntroText {
                    Text("Before we talk, take one breath with us.")
                        .font(.body)
                        .foregroundColor(Color("TextPrimary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 44)
                        .padding(.top, 200)
                        .opacity(introTextOpacity)
                }

                Spacer()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    introTextOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showIntroText = false
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                startTransitionToSlide2()
            }
        }
    }

    // MARK: - Slide 2

    private var slide2: some View {
        ZStack {
            Color(hex: "#552E80").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                DotLottieAnimation(
                    fileName: "Be",
                    config: AnimationConfig(autoplay: true, loop: true)
                ).view()
                .frame(width: 300, height: 300)

                Spacer()

                Text("A breathing app built around real interaction, so your mind has somewhere to land.")
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 32)

                HStack(spacing: 8) {
                    Circle().fill(.white).frame(width: 6, height: 6)
                    Circle().fill(.white.opacity(0.3)).frame(width: 6, height: 6)
                }
                .padding(.bottom, 20)

                Button {
                    transitionToSlide3()
                } label: {
                    Text("Continue")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 160, height: 48)
                }
                .glassEffect(.regular.tint(Color("BrandGreen")).interactive(), in: .capsule)
                .padding(.bottom, 60)

            }
        }
    }

    // MARK: - Slide 3

    private var slide3: some View {
        ZStack {
            Color(hex: "#000F00").ignoresSafeArea()

            VStack(spacing: 0) {
                Text("Blow. Watch. Feel.")
                    .font(.system(.title3, design: .serif).bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 180)
                    .padding(.horizontal, 40)



                Image("onboarding3")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 270)

                Spacer()

                Text("Be. uses your camera to place a real flower in your space, exhale toward it, watch it respond, then plant it in your garden.")
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 32)

                HStack(spacing: 8) {
                    Circle().fill(.white.opacity(0.3)).frame(width: 6, height: 6)
                    Circle().fill(.white).frame(width: 6, height: 6)
                }
                .padding(.bottom, 20)

                Button {
                    authManager.showOnboarding = false
                    authManager.continueWithoutAuth()
                } label: {
                    Text("Begin")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 160, height: 48)
                }
                .glassEffect(.regular.tint(Color("BrandGreen")).interactive(), in: .capsule)
                .padding(.bottom, 60)
            }
        }
    }

    // MARK: - Transitions

    private func startTransitionToSlide2() {
        transitionCircleVisible = true
        withAnimation(.easeInOut(duration: 0.9)) {
            transitionCircleScale = 35
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            slide2Visible = true
            withAnimation(.easeInOut(duration: 0.4)) {
                slide2Opacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentSlide = 1
                transitionCircleVisible = false
                transitionCircleScale = 0.001
            }
        }
    }

    private func transitionToSlide3() {
        withAnimation(.easeInOut(duration: 0.6)) {
            slide3Visible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                slide2Visible = false
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthManager())
}
