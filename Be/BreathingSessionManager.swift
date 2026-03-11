import Foundation
import Combine

enum BreathingPhase {
    case idle
    case inhale   // 4 seconds
    case exhale   // 8 seconds
    case finished
}

@MainActor
class BreathingSessionManager: ObservableObject {
    @Published var phase: BreathingPhase = .idle
    @Published var globalSecondsRemaining: Int = 60
    @Published var phaseElapsed: Double = 0.0
    @Published var isPaused: Bool = false
    @Published var showBlowHint: Bool = false

    var userBlewDuringExhale = false

    let inhaleDuration: Double = 4.0
    let exhaleDuration: Double = 8.0
    let totalSessionSeconds: Int = 60

    var phaseDuration: Double {
        switch phase {
        case .inhale: return inhaleDuration
        case .exhale: return exhaleDuration
        default: return 1.0
        }
    }

    var phaseProgress: Double {
        guard phaseDuration > 0 else { return 0 }
        return min(phaseElapsed / phaseDuration, 1.0)
    }

    var phaseSecondsLeft: Int {
        max(0, Int(ceil(phaseDuration - phaseElapsed)))
    }

    var globalTimerText: String {
        let elapsed = totalSessionSeconds - globalSecondsRemaining
        return String(format: "%02d:%02d / %02d:%02d",
                      elapsed / 60, elapsed % 60,
                      totalSessionSeconds / 60, totalSessionSeconds % 60)
    }

    private var globalTimer: Timer?
    private var phaseTimer: Timer?

    func startSession() {
        globalSecondsRemaining = totalSessionSeconds
        isPaused = false
        showBlowHint = false
        userBlewDuringExhale = false
        beginPhase(.inhale)
        startGlobalTimer()
    }

    func togglePause() {
        isPaused.toggle()
    }

    func recordBlow() {
        userBlewDuringExhale = true
    }

    func stopSession() {
        globalTimer?.invalidate()
        globalTimer = nil
        phaseTimer?.invalidate()
        phaseTimer = nil
        phase = .finished
    }

    // MARK: - Private

    private func startGlobalTimer() {
        globalTimer?.invalidate()
        globalTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, !self.isPaused else { return }
                self.globalSecondsRemaining -= 1
                if self.globalSecondsRemaining <= 0 {
                    self.stopSession()
                }
            }
        }
    }

    private func beginPhase(_ newPhase: BreathingPhase) {
        // When leaving exhale, check if user blew
        if phase == .exhale && !userBlewDuringExhale {
            showBlowHint = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.showBlowHint = false
            }
        }

        phase = newPhase
        phaseElapsed = 0.0

        if newPhase == .exhale {
            userBlewDuringExhale = false
        }

        phaseTimer?.invalidate()
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, !self.isPaused else { return }
                self.phaseElapsed += 0.1
                if self.phaseElapsed >= self.phaseDuration {
                    self.advancePhase()
                }
            }
        }
    }

    private func advancePhase() {
        phaseTimer?.invalidate()
        switch phase {
        case .inhale:
            beginPhase(.exhale)
        case .exhale:
            beginPhase(.inhale)
        default:
            break
        }
    }
}
