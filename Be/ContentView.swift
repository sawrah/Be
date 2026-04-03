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

// MARK: - Content View

struct ContentView: View {
    var onAddToGarden: (() -> Void)?

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

    @StateObject private var micMonitor = MicMonitor()
    @StateObject private var sessionManager = BreathingSessionManager()

    @State private var inhaleCount = 0
    @State private var exhaleCount = 0

    var body: some View {
        ZStack {
            // AR layer
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
                        ? "Move your phone slowly to scan the room" 
                        : "Point out a flat surface like a table or floor")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 80)
                    Spacer()
                }
                .transition(.opacity)
            }

            // Blow hint toast
            if sessionManager.showBlowHint {
                VStack {
                    Spacer()
                    Text("Try to blow the petals!")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 160)
                }
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.3), value: sessionManager.showBlowHint)
            }

            // Confetti overlay
            if showConfetti {
                ConfettiView()
            }
        }
        .sensoryFeedback(.increase, trigger: inhaleCount)
        .sensoryFeedback(.decrease, trigger: exhaleCount)
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
                    PlacementAnimation(fileName: "animationTap")
                        .scaleEffect(1.2)
                        .shadow(color: .white.opacity(0.2), radius: 8)
                        .offset(y: 5)

                    Text("Place the flower on a flat surface")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 15)
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
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
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 18)
                        .glassEffect(.regular.tint(Color("BrandGreen")).interactive(), in: .capsule)
                }
                .environment(\.colorScheme, .dark)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.bottom, 50)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isFlowerPlaced)
    }

    // MARK: - Active Session

    private var activeSessionOverlay: some View {
        VStack {
            phaseMonitorView
                .padding(.top, 60)

            Spacer()

            globalControlView
                .padding(.bottom, 50)
        }
    }

    private var phaseMonitorView: some View {
        VStack(spacing: 12) {
            Text(sessionManager.phase == .inhale ? "Inhale" : "Exhale")
                .font(.system(.largeTitle, design: .serif).weight(.semibold))
                .foregroundStyle(.primary)

            BreathingWaveView(
                sessionElapsed: sessionManager.sessionElapsed,
                totalDuration: sessionManager.totalSessionDuration,
                inhaleDuration: sessionManager.inhaleDuration,
                exhaleDuration: sessionManager.exhaleDuration,
                phase: sessionManager.phase
            )
        }
        .padding(.vertical, 20)
    }

    private var globalControlView: some View {
        VStack(spacing: 10) {
            Button {
                sessionManager.togglePause()
            } label: {
                Image(systemName: sessionManager.isPaused ? "play.fill" : "pause.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .glassEffect(.regular.tint(Color("BrandGreen")).interactive(), in: .circle)
            }
            .environment(\.colorScheme, .dark)

            Text(sessionManager.globalTimerText)
                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Finished

    private var sessionFinishedOverlay: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Text("You did it!")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(.primary)

                Button {
                    addToGarden()
                } label: {
                    Text("Add to Garden")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 18)
                        .glassEffect(.regular.tint(Color("BrandGreen")).interactive(), in: .capsule)
                }
                .environment(\.colorScheme, .dark)
            }
            .padding(.bottom, 100)
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
    var body: some View {
        DotLottieAnimation(
            fileName: fileName,
            config: AnimationConfig(autoplay: true, loop: true)
        ).view()
        .frame(width: 80, height: 80)
    }
}

#Preview {
    ContentView()
}
