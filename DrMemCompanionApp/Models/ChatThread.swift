import Foundation
import SwiftData

@Model
class ChatThread {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var title: String = "New Chat"
    var messagesData: Data = Data()

    var messages: [ChatMessage] {
        get {
            (try? JSONDecoder().decode([ChatMessage].self, from: messagesData)) ?? []
        }
        set {
            messagesData = (try? JSONEncoder().encode(newValue)) ?? Data()
            updatedAt = Date()
        }
    }

    init(title: String = "New Chat") {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.title = title
    }
}

nonisolated struct ChatMessage: Codable, Identifiable, Sendable, Hashable {
    var id: UUID
    var role: String
    var content: String
    var timestamp: Date
    var citations: [Citation]

    init(role: String, content: String, citations: [Citation] = []) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.citations = citations
    }
}

nonisolated struct Citation: Codable, Identifiable, Sendable, Hashable {
    var id: UUID
    var memoryId: UUID
    var memoryTitle: String
    var snippet: String

    init(memoryId: UUID, memoryTitle: String, snippet: String) {
        self.id = UUID()
        self.memoryId = memoryId
        self.memoryTitle = memoryTitle
        self.snippet = snippet
    }
}
