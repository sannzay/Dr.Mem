import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDrawerItem: DrawerItem = .chats
    @State private var isDrawerOpen: Bool = false
    @State private var showChatHome: Bool = true

    let openRouter: OpenRouterService
    let rag: RAGService
    let pipeline: AIPipelineService
    let biometricService: BiometricService
    let bleService: OmiBLEService
    let speechService: SpeechRecognitionService

    @State private var chatVM: ChatViewModel?
    @State private var sessionVM: SessionViewModel?

    var body: some View {
        ZStack {
            NavigationStack {
                mainContent
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    isDrawerOpen = true
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(DrMemTheme.darkText)
                            }
                        }
                    }
            }

            if isDrawerOpen {
                DrawerView(
                    selectedItem: $selectedDrawerItem,
                    isOpen: $isDrawerOpen,
                    onNewChat: {
                        chatVM?.startNewChat()
                        selectedDrawerItem = .chats
                        showChatHome = true
                    }
                )
                .transition(.move(edge: .leading))
                .zIndex(1)
            }
        }
        .onAppear {
            if chatVM == nil {
                chatVM = ChatViewModel(openRouter: openRouter, rag: rag, pipeline: pipeline)
            }
            if sessionVM == nil {
                sessionVM = SessionViewModel(pipeline: pipeline, speechService: speechService)
            }
        }
        .dismissKeyboardOnTap()
    }

    @ViewBuilder
    private var mainContent: some View {
        switch selectedDrawerItem {
        case .chats:
            if showChatHome, let chatVM {
                ChatView(viewModel: chatVM, openRouter: openRouter)
                    .navigationTitle("Dr. Mem")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                showChatHome = false
                            } label: {
                                Image(systemName: "list.bullet")
                            }
                        }
                    }
            } else if let chatVM {
                ChatsListView(viewModel: chatVM, onSelectThread: {
                    showChatHome = true
                })
            }

        case .memories:
            MemoriesView()

        case .listening:
            if let sessionVM {
                ListeningView(sessionVM: sessionVM, bleService: bleService)
            }

        case .journal:
            JournalView()

        case .tasks:
            TasksView()

        case .encounters:
            EncountersView()

        case .settings:
            SettingsView(openRouter: openRouter, biometricService: biometricService)
        }
    }
}
