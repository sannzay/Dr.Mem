import Foundation
import SwiftData

@Observable
class ChatViewModel {
    var currentThread: ChatThread?
    var inputText: String = ""
    var isStreaming: Bool = false
    var streamingContent: String = ""
    var errorMessage: String?

    private let openRouter: OpenRouterService
    private let rag: RAGService
    private let pipeline: AIPipelineService

    init(openRouter: OpenRouterService, rag: RAGService, pipeline: AIPipelineService) {
        self.openRouter = openRouter
        self.rag = rag
        self.pipeline = pipeline
    }

    func sendMessage(modelContext: ModelContext) async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        if currentThread == nil {
            let thread = ChatThread(title: String(text.prefix(40)))
            modelContext.insert(thread)
            currentThread = thread
        }

        guard let thread = currentThread else { return }

        var msgs = thread.messages
        msgs.append(ChatMessage(role: "user", content: text))
        thread.messages = msgs
        inputText = ""

        isStreaming = true
        streamingContent = ""
        errorMessage = nil

        do {
            let descriptor = FetchDescriptor<Memory>()
            let allMemories = try modelContext.fetch(descriptor)
            let relevantMemories = rag.retrieveRelevantMemories(query: text, allMemories: allMemories)

            let history = msgs.map { OpenRouterMessage(role: $0.role, content: $0.content) }
            let (response, citations) = try await pipeline.chatWithMemories(
                query: text,
                memories: relevantMemories,
                chatHistory: Array(history.dropLast())
            )

            let assistantMsg = ChatMessage(role: "assistant", content: response, citations: citations)
            var updated = thread.messages
            updated.append(assistantMsg)
            thread.messages = updated

        } catch {
            errorMessage = error.localizedDescription
            let errorMsg = ChatMessage(role: "assistant", content: "I couldn't process that request. \(error.localizedDescription)")
            var updated = thread.messages
            updated.append(errorMsg)
            thread.messages = updated
        }

        isStreaming = false
    }

    func startNewChat() {
        currentThread = nil
        inputText = ""
        streamingContent = ""
        errorMessage = nil
    }
}
