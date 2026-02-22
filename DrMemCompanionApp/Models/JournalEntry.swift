import Foundation
import SwiftData

@Model
class JournalEntry {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var type: JournalEntryType = JournalEntryType.text
    var contentText: String = ""
    var tags: [String] = []

    init(type: JournalEntryType = .text, contentText: String = "") {
        self.id = UUID()
        self.createdAt = Date()
        self.type = type
        self.contentText = contentText
    }
}
