import SwiftUI
import SwiftData

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
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    @State private var isFlowerPlaced = false
    @State private var isSessionActive = false
    @State private var shouldDropPetals = false
    @State private var shouldGrowPetals = false
    @State private var shouldDropAllPetals = false
    @State private var showSurfaceNotFound = false
    @State private var showConfetti = false

    @StateObject private var micMonitor = MicMonitor()
    @StateObject private var sessionManager = BreathingSessionManager()

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
                    Text("No surface found — point camera at a flat surface")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassEffect(.regular, in: .rect(cornerRadius: 12))
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
                        .font(.system(.subheadline, design: .serif).weight(.medium))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassEffect(.regular, in: .rect(cornerRadius: 12))
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
            case .inhale:
                micMonitor.stopMonitoring()
                
                // Only force-drop remaining petals and regrow if this is NOT the very first inhale
                // (We don't want the flower to shed everything instantly on session start!)
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
                Text("Place the flower on a surface")
                    .font(.system(.headline, design: .serif).weight(.semibold).italic())
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .glassEffect(.regular, in: .rect(cornerRadius: 12))
                    .transition(.opacity)
            } else {
                Button {
                    startSession()
                } label: {
                    Text("Start Session")
                        .font(.system(.headline, design: .serif).weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                }
                .glassEffect(.regular.interactive(), in: .capsule)
                .tint(Color("BrandGreen"))
                .transition(.opacity)
            }
        }
        .padding(.bottom, 100)
        .animation(.easeInOut(duration: 0.5), value: isFlowerPlaced)
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

            ProgressView(value: sessionManager.phaseProgress)
                .progressViewStyle(.linear)
                .tint(sessionManager.phase == .inhale ? Color.primary : Color.secondary)
                .frame(width: 220)

            Text("\(sessionManager.phaseSecondsLeft)")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .padding(.horizontal, 40)
    }

    private var globalControlView: some View {
        VStack(spacing: 10) {
            Button {
                sessionManager.togglePause()
            } label: {
                Image(systemName: sessionManager.isPaused ? "play.fill" : "pause.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
            }
            .glassEffect(.regular.interactive(), in: .circle)
            .tint(Color("BrandGreen"))

            Text(sessionManager.globalTimerText)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(.secondary)
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
                        .font(.system(.headline, design: .serif).weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                }
                .glassEffect(.regular.interactive(), in: .capsule)
                .tint(Color("BrandGreen"))
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
        // TODO: Implement garden collection feature
        withAnimation(.easeOut(duration: 0.4)) {
            isSessionActive = false
            showConfetti = false
        }
    }
}

#Preview {
    ContentView()
}
