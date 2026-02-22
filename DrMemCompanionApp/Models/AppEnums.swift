import Foundation
import SwiftData

nonisolated enum SessionType: String, Codable, CaseIterable, Sendable {
    case general
    case encounter
}

nonisolated enum CaptureMode: String, Codable, CaseIterable, Sendable {
    case education = "Education"
    case brainDump = "Brain Dump"
    case patientEncounter = "Patient Encounter"

    var icon: String {
        switch self {
        case .education: "graduationcap.fill"
        case .brainDump: "brain.head.profile.fill"
        case .patientEncounter: "stethoscope"
        }
    }
}

nonisolated enum SessionSource: String, Codable, CaseIterable, Sendable {
    case omiDevice = "Omi Device"
    case journal = "Journal"
    case phoneMic = "Phone Mic"
}

nonisolated enum SessionStatus: String, Codable, CaseIterable, Sendable {
    case recording
    case processing
    case ready
    case deleted
}

nonisolated enum VisitType: String, Codable, CaseIterable, Sendable {
    case outpatient = "Outpatient"
    case inpatient = "Inpatient"
    case er = "ER"
    case telehealth = "Telehealth"

    var icon: String {
        switch self {
        case .outpatient: "building.2.fill"
        case .inpatient: "bed.double.fill"
        case .er: "cross.case.fill"
        case .telehealth: "video.fill"
        }
    }
}

nonisolated enum RetentionPolicy: String, Codable, CaseIterable, Sendable {
    case noteOnly = "Note Only"
    case keepTranscript = "Keep Transcript"
}

nonisolated enum MemoryType: String, Codable, CaseIterable, Sendable {
    case learningPearl = "Learning Pearl"
    case feedback = "Feedback"
    case decision = "Decision"
    case plan = "Plan"
    case taskCandidate = "Task"
    case reference = "Reference"

    var icon: String {
        switch self {
        case .learningPearl: "lightbulb.fill"
        case .feedback: "bubble.left.fill"
        case .decision: "arrow.triangle.branch"
        case .plan: "list.bullet.clipboard.fill"
        case .taskCandidate: "checkmark.circle.fill"
        case .reference: "bookmark.fill"
        }
    }
}

nonisolated enum SourceType: String, Codable, CaseIterable, Sendable {
    case session
    case journal
}

nonisolated enum TaskPriority: String, Codable, CaseIterable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
}

nonisolated enum TaskStatus: String, Codable, CaseIterable, Sendable {
    case todo = "To Do"
    case doing = "Doing"
    case done = "Done"
}

nonisolated enum JournalEntryType: String, Codable, CaseIterable, Sendable {
    case text = "Text"
    case voice = "Voice"
    case image = "Image"
}

nonisolated enum DrawerItem: String, CaseIterable, Identifiable {
    case chats = "Chats"
    case memories = "Memories"
    case listening = "Listening"
    case journal = "Journal"
    case tasks = "Tasks"
    case encounters = "Encounters"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .chats: "bubble.left.and.bubble.right.fill"
        case .memories: "brain.fill"
        case .listening: "waveform.circle.fill"
        case .journal: "book.fill"
        case .tasks: "checklist"
        case .encounters: "stethoscope"
        case .settings: "gearshape.fill"
        }
    }
}
