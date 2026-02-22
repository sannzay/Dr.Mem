import Foundation
import SwiftData

@Model
class TranscriptSegment {
    var id: UUID = UUID()
    var session: Session?
    var startMs: Int = 0
    var endMs: Int = 0
    var text: String = ""
    var confidence: Double?
    var speaker: String?

    init(startMs: Int = 0, endMs: Int = 0, text: String = "", confidence: Double? = nil, speaker: String? = nil) {
        self.id = UUID()
        self.startMs = startMs
        self.endMs = endMs
        self.text = text
        self.confidence = confidence
        self.speaker = speaker
    }
}
