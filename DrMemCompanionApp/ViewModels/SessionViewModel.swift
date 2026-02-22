import Foundation
import SwiftData
import AVFoundation

@Observable
class SessionViewModel {
    var isRecording: Bool = false
    var recordingDuration: Int = 0
    var currentSession: Session?
    var liveTranscript: String = ""
    var isProcessing: Bool = false
    var selectedMode: CaptureMode = .education
    var errorMessage: String?

    private var timer: Timer?
    private let pipeline: AIPipelineService
    let speechService: SpeechRecognitionService
    private var transcriptObserverTask: Task<Void, Never>?

    init(pipeline: AIPipelineService, speechService: SpeechRecognitionService) {
        self.pipeline = pipeline
        self.speechService = speechService
    }

    func startRecording(mode: CaptureMode, source: SessionSource, modelContext: ModelContext, bleService: OmiBLEService? = nil) {
        selectedMode = mode
        let sessionType: SessionType = mode == .patientEncounter ? .encounter : .general
        let session = Session(sessionType: sessionType, mode: mode, source: source)
        modelContext.insert(session)
        currentSession = session

        isRecording = true
        recordingDuration = 0
        liveTranscript = ""
        errorMessage = nil

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordingDuration += 1
            }
        }

        startTranscription()
    }

    private func startTranscription() {
        transcriptObserverTask?.cancel()

        transcriptObserverTask = Task { [weak self] in
            guard let self else { return }

            await speechService.startPhoneMicTranscription()

            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { break }
                let newText = speechService.transcribedText
                if !newText.isEmpty, newText != liveTranscript {
                    liveTranscript = newText
                }
            }
        }
    }

    func stopRecording(modelContext: ModelContext) async {
        isRecording = false
        timer?.invalidate()
        timer = nil

        let snapshotBeforeStop = speechService.transcribedText

        transcriptObserverTask?.cancel()
        transcriptObserverTask = nil

        isProcessing = true

        let finalTranscript = await speechService.stopAndGetFinalTranscript()

        let bestTranscript = finalTranscript.isEmpty ? snapshotBeforeStop : finalTranscript
        liveTranscript = bestTranscript

        guard let session = currentSession else {
            isProcessing = false
            return
        }
        session.durationSec = recordingDuration
        session.transcriptText = bestTranscript

        if session.transcriptText.isEmpty {
            session.status = .ready
            errorMessage = "No speech was detected. Please try again."
            isProcessing = false
            return
        }

        session.status = .processing

        do {
            let summary = try await pipeline.summarize(text: session.transcriptText)
            session.summary = summary

            if session.isEncounter {
                let docs = try await pipeline.generateEncounterDocs(
                    transcript: session.transcriptText,
                    visitType: session.visitType?.rawValue
                )
                session.clinicianDocDraft = docs.clinicianDraft
                session.patientAVS = docs.patientAVS
            }

            let extraction = try await pipeline.extractMemoriesAndTasks(
                text: session.transcriptText,
                mode: session.mode
            )

            for em in extraction.memories {
                let memory = Memory(
                    mode: session.mode,
                    type: MemoryType(rawValue: em.type) ?? .learningPearl,
                    title: em.title,
                    body: em.body
                )
                memory.tags = em.tags
                memory.sourceType = .session
                memory.sourceId = session.id
                if session.isEncounter {
                    memory.linkedEncounterId = session.id
                }
                modelContext.insert(memory)
            }

            for et in extraction.tasks {
                let task = TaskItem(
                    title: et.title,
                    priority: TaskPriority(rawValue: et.priority) ?? .medium
                )
                task.notes = et.notes
                task.sourceType = .session
                task.sourceId = session.id
                if session.isEncounter {
                    task.linkedEncounterId = session.id
                }
                modelContext.insert(task)
            }

            session.status = .ready
        } catch {
            errorMessage = error.localizedDescription
            session.status = .ready
        }

        isProcessing = false
    }

    var formattedDuration: String {
        let minutes = recordingDuration / 60
        let seconds = recordingDuration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
