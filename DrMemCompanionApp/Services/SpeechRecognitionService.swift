import Foundation
import AVFoundation
import Speech

@Observable
class SpeechRecognitionService {
    var transcribedText: String = ""
    var isTranscribing: Bool = false
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    var errorMessage: String?

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?

    private var committedText: String = ""
    private var currentSegmentText: String = ""
    private var isRestarting: Bool = false
    private var stopRequested: Bool = false
    private var stopContinuation: CheckedContinuation<String, Never>?

    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    func requestAuthorization() async -> Bool {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        authorizationStatus = status
        return status == .authorized
    }

    func startPhoneMicTranscription() async {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition not available"
            return
        }

        guard await requestAuthorization() else {
            errorMessage = "Speech recognition not authorized"
            return
        }

        cleanupPreviousSession()

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            committedText = ""
            currentSegmentText = ""
            transcribedText = ""
            errorMessage = nil
            isTranscribing = true
            stopRequested = false
            isRestarting = false

            let engine = AVAudioEngine()
            self.audioEngine = engine

            startNewRecognitionTask()

            let inputNode = engine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }

            engine.prepare()
            try engine.start()
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            isTranscribing = false
        }
    }

    private func startNewRecognitionTask() {
        guard let speechRecognizer else { return }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if speechRecognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        request.addsPunctuation = true

        self.recognitionRequest = request
        currentSegmentText = ""

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self, self.isTranscribing || self.stopRequested else { return }

                if let result {
                    let newText = result.bestTranscription.formattedString
                    self.currentSegmentText = newText
                    self.updateTranscribedText()

                    if result.isFinal {
                        self.commitCurrentSegment()
                    }
                }

                if let error {
                    let nsError = error as NSError
                    let isTimeout = nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216
                    let isCancelled = nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 209

                    if !isCancelled {
                        self.commitCurrentSegment()
                    }

                    if isTimeout && self.isTranscribing && !self.stopRequested {
                        self.restartRecognitionTask()
                    }
                }
            }
        }
    }

    private func commitCurrentSegment() {
        let textToCommit = currentSegmentText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !textToCommit.isEmpty {
            if committedText.isEmpty {
                committedText = textToCommit
            } else {
                committedText += " " + textToCommit
            }
            currentSegmentText = ""
            updateTranscribedText()
        }

        if let continuation = stopContinuation {
            stopContinuation = nil
            let finalText = committedText
            recognitionRequest = nil
            recognitionTask = nil
            continuation.resume(returning: finalText)
        }
    }

    private func restartRecognitionTask() {
        guard !isRestarting, isTranscribing, !stopRequested else { return }
        isRestarting = true

        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        Task {
            try? await Task.sleep(for: .milliseconds(100))
            guard self.isTranscribing, !self.stopRequested else {
                self.isRestarting = false
                return
            }
            self.startNewRecognitionTask()
            self.isRestarting = false
        }
    }

    private func updateTranscribedText() {
        let partial = currentSegmentText.trimmingCharacters(in: .whitespacesAndNewlines)
        if committedText.isEmpty && partial.isEmpty {
            transcribedText = ""
        } else if committedText.isEmpty {
            transcribedText = partial
        } else if partial.isEmpty {
            transcribedText = committedText
        } else {
            transcribedText = committedText + " " + partial
        }
    }

    func stopAndGetFinalTranscript() async -> String {
        guard isTranscribing else {
            let result = transcribedText
            cleanupPreviousSession()
            return result
        }

        stopRequested = true
        isTranscribing = false

        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        recognitionRequest?.endAudio()

        let transcript: String = await withCheckedContinuation { continuation in
            self.stopContinuation = continuation

            Task {
                try? await Task.sleep(for: .seconds(3))
                guard let pending = self.stopContinuation else { return }
                self.stopContinuation = nil

                self.commitCurrentSegment()

                let finalText = self.committedText
                self.recognitionRequest = nil
                self.recognitionTask?.cancel()
                self.recognitionTask = nil

                pending.resume(returning: finalText)
            }
        }

        let finalResult = transcript.isEmpty ? committedText : transcript

        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        return finalResult
    }

    func stopTranscription() {
        isTranscribing = false
        stopRequested = true
        cleanupPreviousSession()
    }

    private func cleanupPreviousSession() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        isRestarting = false
        stopRequested = false

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
