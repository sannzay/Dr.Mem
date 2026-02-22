import Foundation
import SwiftData

@Model
class TaskItem {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var title: String = ""
    var notes: String = ""
    var dueAt: Date?
    var priority: TaskPriority = TaskPriority.medium
    var status: TaskStatus = TaskStatus.todo
    var sourceType: SourceType = SourceType.session
    var sourceId: UUID?
    var linkedEncounterId: UUID?
    var linkedMemoryId: UUID?

    init(title: String = "", priority: TaskPriority = .medium) {
        self.id = UUID()
        self.createdAt = Date()
        self.title = title
        self.priority = priority
    }
}
