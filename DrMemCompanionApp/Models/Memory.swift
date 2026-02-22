import Foundation
import SwiftData

@Model
class Memory {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var mode: CaptureMode = CaptureMode.education
    var type: MemoryType = MemoryType.learningPearl
    var title: String = ""
    var body: String = ""
    var tags: [String] = []
    var pinned: Bool = false
    var sourceType: SourceType = SourceType.session
    var sourceId: UUID?
    var sourceSnippet: String = ""
    var linkedEncounterId: UUID?

    init(mode: CaptureMode = .education, type: MemoryType = .learningPearl, title: String = "", body: String = "") {
        self.id = UUID()
        self.createdAt = Date()
        self.mode = mode
        self.type = type
        self.title = title
        self.body = body
    }
}
