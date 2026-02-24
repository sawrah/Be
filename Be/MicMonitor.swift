import AVFoundation
import Combine

@MainActor
class MicMonitor: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    
    @Published var soundLevel: Float = 0.0
    @Published var isBlowing: Bool = false
    
    init() {
        // We will request permission when starting monitoring to be safe
    }
    
    func startMonitoring() {
        let audioSession = AVAudioSession.sharedInstance()
        let audioApplication = AVAudioApplication.shared
        print("🎤 Starting microphone monitoring...")
        print("🎤 Current permission: \(audioApplication.recordPermission.rawValue)")
        
        if audioApplication.recordPermission != .granted {
            AVAudioApplication.requestRecordPermission { allowed in
                print("🎤 Permission requested, allowed: \(allowed)")
                if allowed {
                    Task { @MainActor [weak self] in
                        self?.setupRecorder()
                    }
                }
            }
        } else {
            setupRecorder()
        }
    }
    
    private func setupRecorder() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true)
            
            let url = URL(fileURLWithPath: "/dev/null", isDirectory: false)
            let recorderSettings: [String: Any] = [
                AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: url, settings: recorderSettings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    self.audioRecorder?.updateMeters()
                    let level = self.audioRecorder?.averagePower(forChannel: 0) ?? -160.0
                    
                    self.soundLevel = level
                    
                    let wasBlowing = self.isBlowing
                    let isNowBlowing = level > -30.0
                    
                    self.isBlowing = isNowBlowing
                    
                }
            }
        } catch {
            print("🎤 Error setting up recorder: \\(error)")
        }
    }
    
    func stopMonitoring() {
        print("🎤 Stopping monitoring")
        audioRecorder?.stop()
        audioRecorder = nil
        timer?.invalidate()
        timer = nil
        
        // Deactivate audio session
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false)
        
        // Reset state
        soundLevel = 0.0
        isBlowing = false
    }
}
