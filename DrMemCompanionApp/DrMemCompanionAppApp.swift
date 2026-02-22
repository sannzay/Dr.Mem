import SwiftUI
import SwiftData

@main
struct DrMemCompanionAppApp: App {
    @State private var openRouter = OpenRouterService()
    @State private var rag = RAGService()
    @State private var biometricService = BiometricService()
    @State private var bleService = OmiBLEService()
    @State private var speechService = SpeechRecognitionService()

    private var pipeline: AIPipelineService {
        AIPipelineService(openRouter: openRouter)
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Session.self,
            TranscriptSegment.self,
            JournalEntry.self,
            Memory.self,
            TaskItem.self,
            ChatThread.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if biometricService.isLockEnabled && !biometricService.isUnlocked {
                    LockScreenView(biometricService: biometricService)
                } else {
                    ContentView(
                        openRouter: openRouter,
                        rag: rag,
                        pipeline: pipeline,
                        biometricService: biometricService,
                        bleService: bleService,
                        speechService: speechService
                    )
                }
            }
            .onAppear {
                let context = sharedModelContainer.mainContext
                MockDataService.populateIfNeeded(modelContext: context)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
