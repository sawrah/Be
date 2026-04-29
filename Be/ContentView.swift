import SwiftUI
import SwiftData
import DotLottie

// MARK: - Confetti

struct ConfettiView: View {
    struct Piece: Identifiable {
        let id = UUID()
        let color: Color
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let rotation: Double
    }

    @State private var animate = false
    let pieces: [Piece]

    init(count: Int = 60) {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .mint, .cyan]
        var p: [Piece] = []
        for _ in 0..<count {
            p.append(Piece(
                color: colors[Int.random(in: 0..<colors.count)],
                x: CGFloat.random(in: -180...180),
                y: CGFloat.random(in: -500...50),
                size: CGFloat.random(in: 5...10),
                rotation: Double.random(in: 0...720)
            ))
        }
        pieces = p
    }

    var body: some View {
        ZStack {
            ForEach(pieces) { piece in
                RoundedRectangle(cornerRadius: 2)
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size * 1.6)
                    .rotationEffect(.degrees(animate ? piece.rotation : 0))
                    .offset(x: animate ? piece.x : 0, y: animate ? piece.y : 0)
                    .opacity(animate ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2.5)) {
                animate = true
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Exhale Edge Hint

struct ExhaleEdgeHintView: View {
    let exhaleDuration: Double
    let phaseElapsed: Double

    @State private var opacity: Double = 0
    @State private var arrowOffset: CGFloat = 0
    @State private var isFadingOut = false

    private let lavender = Color(red: 180/255, green: 150/255, blue: 255/255)

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(lavender)
                .frame(height: 6)
                .shadow(color: lavender.opacity(0.9), radius: 10, y: 3)
                .shadow(color: lavender.opacity(0.5), radius: 20, y: 6)

            VStack(spacing: 6) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(lavender)
                    .shadow(color: lavender.opacity(0.6), radius: 4)
                    .offset(y: arrowOffset)
                    .padding(.top, 10)

                Text("exhale to the top edge")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(lavender.opacity(0.9))
                    .tracking(0.3)
            }
        }
        .frame(maxWidth: .infinity)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.4)) {
                opacity = 0.85
            }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                arrowOffset = -5
            }
        }
        .onChange(of: phaseElapsed) { elapsed in
            guard !isFadingOut else { return }
            if elapsed >= exhaleDuration - 0.4 {
                isFadingOut = true
                withAnimation(.easeOut(duration: 0.4)) {
                    opacity = 0
                }
            }
        }
    }
}

// MARK: - Breathing Session View

struct BreathingSessionView: View {
    var onAddToGarden: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    @State private var isFlowerPlaced = false
    @State private var isSessionActive = false
    @State private var shouldDropPetals = false
    @State private var shouldGrowPetals = false
    @State private var shouldDropAllPetals = false
    @State private var showSurfaceNotFound = false
    @State private var surfaceNotFoundAttempts = 0
    @State private var showConfetti = false
    @State private var showCancelConfirmation = false

    @StateObject private var micMonitor = MicMonitor()
    @StateObject private var sessionManager = BreathingSessionManager()

    @State private var inhaleCount = 0
    @State private var exhaleCount = 0

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var padScale: CGFloat { isPad ? 1.3 : 1.0 }

    var body: some View {
        ZStack {
            // AR layer
            if Capability.backend == .realityKit {
                ARViewContainer(
                    onPlaced: {
                        withAnimation(.easeOut(duration: 0.5)) {
                            isFlowerPlaced = true
                        }
                    },
                    onSurfaceNotFound: {
                        surfaceNotFoundAttempts += 1
                        showSurfaceNotFound = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { showSurfaceNotFound = false }
                        }
                    },
                    shouldDropPetals: $shouldDropPetals,
                    shouldGrowPetals: $shouldGrowPetals,
                    shouldDropAllPetals: $shouldDropAllPetals
                )
                .edgesIgnoringSafeArea(.all)
            } else {
                SceneKitARContainer(
                    onPlaced: {
                        withAnimation(.easeOut(duration: 0.5)) {
                            isFlowerPlaced = true
                        }
                    },
                    onSurfaceNotFound: {
                        surfaceNotFoundAttempts += 1
                        showSurfaceNotFound = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { showSurfaceNotFound = false }
                        }
                    },
                    shouldDropPetals: $shouldDropPetals,
                    shouldGrowPetals: $shouldGrowPetals,
                    shouldDropAllPetals: $shouldDropAllPetals
                )
                .edgesIgnoringSafeArea(.all)
            }

            // UI overlays
            if !isSessionActive {
                preSessionOverlay
            } else if sessionManager.phase != .finished {
                activeSessionOverlay
            } else {
                sessionFinishedOverlay
            }

            // Surface not found toast
            if showSurfaceNotFound {
                VStack {
                    Text(surfaceNotFoundAttempts == 1 
                        ? "Move your device slowly to scan the room" 
                        : "Point out a flat surface like a table or floor")
                        .font(.system(size: 17 * padScale, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24 * padScale)
                        .padding(.top, 80 * padScale)
                    Spacer()
                }
                .transition(.opacity)
            }

            // Blow hint toast
            if sessionManager.showBlowHint {
                VStack {
                    Spacer()
                    Text("Try to blow the petals!")
                        .font(.system(size: 17 * padScale, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24 * padScale)
                        .padding(.bottom, 160 * padScale)
                }
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 6), value: sessionManager.showBlowHint)
            }

            // Confetti overlay
            if showConfetti {
                ConfettiView()
            }

            // Exhale edge hint — behind close button
            if isSessionActive && sessionManager.phase == .exhale {
                VStack {
                    ExhaleEdgeHintView(
                        exhaleDuration: sessionManager.exhaleDuration,
                        phaseElapsed: sessionManager.phaseElapsed
                    )
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
            }

            // Back / cancel button — top-left, always visible
            if sessionManager.phase != .finished {
                VStack {
                    HStack {
                        Button {
                            if isSessionActive {
                                sessionManager.togglePause()
                                showCancelConfirmation = true
                            } else {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17 * padScale, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44 * padScale, height: 44 * padScale)
                                .glassEffect(.regular.interactive(), in: .circle)
                        }
                        .environment(\.colorScheme, .dark)
                        .padding(.leading, 20 * padScale)
                        .padding(.top, 56 * padScale)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .confirmationDialog(
            "End session?",
            isPresented: $showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Session", role: .destructive) {
                micMonitor.stopMonitoring()
                sessionManager.cancelSession()
                withAnimation(.easeOut(duration: 0.3)) {
                    isSessionActive = false
                    showConfetti = false
                }
                dismiss()
            }
            Button("Keep Going") {
                sessionManager.togglePause() // resume
            }
            Button("Cancel", role: .cancel) {
                sessionManager.togglePause() // resume
            }
        } message: {
            Text("Your progress won't be saved.")
        }
        .sensoryFeedback(.impact(weight: .heavy, intensity: 1.0), trigger: inhaleCount)
        .sensoryFeedback(.impact(weight: .heavy, intensity: 1.0), trigger: exhaleCount)
        .onChange(of: micMonitor.isBlowing) { newValue in
            guard isSessionActive,
                  sessionManager.phase == .exhale,
                  !sessionManager.isPaused else { return }

            if newValue {
                sessionManager.recordBlow()
            }
            shouldDropPetals = newValue
        }
        .onChange(of: sessionManager.phase) { newPhase in
            switch newPhase {
            case .exhale:
                micMonitor.startMonitoring()
                exhaleCount += 1
            case .inhale:
                micMonitor.stopMonitoring()
                inhaleCount += 1
                
                // Only force-drop remaining petals and regrow if this is NOT the very first inhale
                if sessionManager.globalSecondsRemaining < sessionManager.totalSessionSeconds {
                    shouldDropAllPetals = true
                    shouldGrowPetals = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { 
                        shouldDropAllPetals = false 
                        shouldGrowPetals = false
                    }
                }
            case .finished:
                micMonitor.stopMonitoring()
                showConfetti = true
            default:
                break
            }
        }
        .onChange(of: sessionManager.isPaused) { paused in
            if paused {
                micMonitor.stopMonitoring()
            } else if sessionManager.phase == .exhale {
                micMonitor.startMonitoring()
            }
        }
    }

    // MARK: - Pre-Session

    private var preSessionOverlay: some View {
        VStack {
            Spacer()

            if !isFlowerPlaced {
                VStack(spacing: 0) {
                    PlacementAnimation(fileName: "animationTap", size: 80 * padScale)
                        .scaleEffect(1.2)
                        .shadow(color: .white.opacity(0.2), radius: 8)
                        .offset(y: 5 * padScale)

                    Text("Place the flower on a flat surface")
                        .font(.system(size: 17 * padScale, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 24 * padScale)
                .padding(.vertical, 15 * padScale)
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .clipShape(RoundedRectangle(cornerRadius: 16 * padScale))
                .overlay(
                    RoundedRectangle(cornerRadius: 16 * padScale)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 15, y: 10)
                .transition(.opacity)
            } else {
                Button {
                    startSession()
                } label: {
                    Text("Start Session")
                        .font(.system(size: 17 * padScale, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40 * padScale)
                        .padding(.vertical, 18 * padScale)
                        .glassEffect(.regular.tint(Color("BrandGreen")).interactive(), in: .capsule)
                }
                .environment(\.colorScheme, .dark)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.bottom, 50 * padScale)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isFlowerPlaced)
    }

    // MARK: - Active Session

    private var activeSessionOverlay: some View {
        VStack {
            phaseMonitorView
                .padding(.top, 60 * padScale)

            Spacer()

            globalControlView
                .padding(.bottom, 50 * padScale)
        }
    }

    private var phaseMonitorView: some View {
        VStack(spacing: 12) {
            PhaseLabelView(
                phase: sessionManager.phase,
                inhaleDuration: sessionManager.inhaleDuration,
                exhaleDuration: sessionManager.exhaleDuration
            )
            .id(sessionManager.phase) // ← forces full re-create on phase change, re-triggering onAppear
            
            BreathingWaveView(
                sessionElapsed: sessionManager.sessionElapsed,
                totalDuration: sessionManager.totalSessionDuration,
                inhaleDuration: sessionManager.inhaleDuration,
                exhaleDuration: sessionManager.exhaleDuration,
                phase: sessionManager.phase
            )
        }
        .padding(.vertical, 20 * padScale)
    }

    private var globalControlView: some View {
        VStack(spacing: 10 * padScale) {
            Button {
                sessionManager.togglePause()
            } label: {
                Image(systemName: sessionManager.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 28 * padScale))
                    .foregroundStyle(.white)
                    .frame(width: 64 * padScale, height: 64 * padScale)
                    .glassEffect(.regular.tint(Color("BrandGreen")).interactive(), in: .circle)
            }
            .environment(\.colorScheme, .dark)

            Text(sessionManager.globalTimerText)
                .font(.system(size: 15 * padScale, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Finished

    private var sessionFinishedOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .transition(.opacity)
            
            // Animation Centered
            SinglePlayAnimation(
                fileName: "breathing-successful", 
                size: 300 * padScale,
                segments: (0, 89)
            )
            .shadow(color: Color("BrandGreen").opacity(0.3), radius: 20)
            .offset(y: -50 * padScale) // Shift slightly up to balance with bottom text
            
            VStack {
                Spacer()
                
                // Grouped Text and Button at the bottom
                VStack(spacing: 12 * padScale) {
                    Text("You did it!")
                        .font(.system(size: 36 * padScale, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                    
                    Text("Now you can plant this flower in your digital garden")
                        .font(.system(size: 17 * padScale, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40 * padScale)
                        .lineSpacing(4 * padScale)
                }
                .padding(.bottom, 25 * padScale)
                
                Button {
                    addToGarden()
                } label: {
                    Text("Add to Garden")
                        .font(.system(size: 17 * padScale, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 44 * padScale)
                        .padding(.vertical, 18 * padScale)
                        .glassEffect(.regular.tint(Color("BrandGreen")).interactive(), in: .capsule)
                }
                .environment(\.colorScheme, .dark)
                .padding(.bottom, 60 * padScale)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Actions

    private func startSession() {
        withAnimation(.easeIn(duration: 0.4)) {
            isSessionActive = true
        }
        sessionManager.startSession()
    }

    private func addToGarden() {
        withAnimation(.easeOut(duration: 0.4)) {
            isSessionActive = false
            showConfetti = false
        }
        onAddToGarden?()
    }
}

struct PlacementAnimation: View {
    let fileName: String
    var size: CGFloat = 80
    var segments: (Float, Float)? = nil
    
    var body: some View {
        DotLottieAnimation(
            fileName: fileName,
            config: AnimationConfig(
                autoplay: true, 
                loop: true,
                segments: segments
            )
        ).view()
        .frame(width: size, height: size)
    }
}

struct SinglePlayAnimation: View {
    let fileName: String
    var size: CGFloat = 80
    var segments: (Float, Float)? = nil
    
    var body: some View {
        DotLottieAnimation(
            fileName: fileName,
            config: AnimationConfig(
                autoplay: true, 
                loop: false,
                segments: segments
            )
        ).view()
        .frame(width: size, height: size)
    }
}

#Preview {
    BreathingSessionView()
}
