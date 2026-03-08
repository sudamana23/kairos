import AVFoundation
import Speech

// MARK: - VoiceRecorder
//
// Handles live microphone recording + on-the-fly speech transcription.
// Designed for the 90-second weekly pulse check-in.
// The transcript property updates continuously as speech is recognised.

@Observable
@MainActor
final class VoiceRecorder {

    enum State { case idle, recording }

    private(set) var state: State = .idle
    private(set) var transcript = ""
    private(set) var audioLevel: Float = 0
    private(set) var permissionError: String?

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer

    init() {
        recognizer = SFSpeechRecognizer(locale: .current) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    }

    // MARK: - Public API

    func toggle() {
        if state == .recording { stop() } else { Task { await start() } }
    }

    func reset() {
        stop()
        transcript = ""
        permissionError = nil
    }

    // MARK: - Start / Stop

    private func start() async {
        permissionError = nil

        // Request speech recognition permission
        let authStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard authStatus == .authorized else {
            permissionError = "Speech recognition access denied. Enable it in System Settings → Privacy & Security → Speech Recognition."
            return
        }

        guard recognizer.isAvailable else {
            permissionError = "Speech recognition is not available right now."
            return
        }

        do {
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = false
            recognitionRequest = request

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                request.append(buffer)
                // Compute RMS for waveform animation
                guard let data = buffer.floatChannelData?[0] else { return }
                let count = Int(buffer.frameLength)
                guard count > 0 else { return }
                let sumSq = (0..<count).reduce(Float(0)) { $0 + data[$1] * data[$1] }
                let rms = sqrtf(sumSq / Float(count))
                DispatchQueue.main.async { self?.audioLevel = min(rms * 25, 1.0) }
            }

            audioEngine.prepare()
            try audioEngine.start()
            state = .recording

            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                if let result {
                    DispatchQueue.main.async { self?.transcript = result.bestTranscription.formattedString }
                }
                if let error { print("VoiceRecorder: \(error)") }
                if result?.isFinal == true { DispatchQueue.main.async { self?.stop() } }
            }
        } catch {
            permissionError = "Could not start recording: \(error.localizedDescription)"
        }
    }

    private func stop() {
        guard state == .recording else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil
        state = .idle
        audioLevel = 0
    }
}
