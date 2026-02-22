import Foundation
import SwiftData

@Model
class Session {
    var id: UUID = UUID()
    var sessionType: SessionType = SessionType.general
    var mode: CaptureMode = CaptureMode.education
    var createdAt: Date = Date()
    var source: SessionSource = SessionSource.phoneMic
    var transcriptText: String = ""
    var summary: String?
    var clinicianDocDraft: String?
    var patientAVS: String?
    var status: SessionStatus = SessionStatus.recording
    var durationSec: Int?
    var qualityScore: Double?

    var visitType: VisitType?
    var patientAlias: String?
    var consentAttested: Bool = false
    var consentTimestamp: Date?
    var reviewedByClinician: Bool = false
    var reviewTimestamp: Date?
    var retentionPolicy: RetentionPolicy = RetentionPolicy.noteOnly
    var audioDeletedAt: Date?

    var clinicianDraftExportedAt: [Date] = []
    var patientAVSExportedAt: [Date] = []

    @Relationship(deleteRule: .cascade) var segments: [TranscriptSegment] = []

    var isEncounter: Bool {
        sessionType == .encounter
    }

    var displayTitle: String {
        if isEncounter {
            let alias = patientAlias ?? "Patient"
            let type = visitType?.rawValue ?? "Visit"
            return "\(type) - \(alias)"
        }
        return "\(mode.rawValue) Session"
    }

    init(sessionType: SessionType = .general, mode: CaptureMode = .education, source: SessionSource = .phoneMic) {
        self.id = UUID()
        self.sessionType = sessionType
        self.mode = mode
        self.createdAt = Date()
        self.source = source
        self.status = .recording
    }
}
