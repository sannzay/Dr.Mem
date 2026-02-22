import Foundation
import SwiftData

nonisolated struct ExtractedMemory: Codable, Sendable {
    let type: String
    let title: String
    let body: String
    let tags: [String]
}

nonisolated struct ExtractedTask: Codable, Sendable {
    let title: String
    let priority: String
    let notes: String
}

nonisolated struct ExtractionResult: Codable, Sendable {
    let memories: [ExtractedMemory]
    let tasks: [ExtractedTask]
}

nonisolated struct EncounterDocs: Codable, Sendable {
    let clinicianDraft: String
    let patientAVS: String
}

@Observable
class AIPipelineService {
    let openRouter: OpenRouterService

    init(openRouter: OpenRouterService) {
        self.openRouter = openRouter
    }

    func summarize(text: String) async throws -> String {
        let messages = [
            OpenRouterMessage(role: "system", content: "You are a medical education assistant. Provide a concise summary of the following transcript. Focus on key clinical points, decisions, and action items."),
            OpenRouterMessage(role: "user", content: text)
        ]
        return try await openRouter.sendMessage(messages: messages)
    }

    func extractMemoriesAndTasks(text: String, mode: CaptureMode) async throws -> ExtractionResult {
        let modeContext: String
        switch mode {
        case .education:
            modeContext = "Focus on learning pearls, feedback, clinical decisions, and references."
        case .brainDump:
            modeContext = "Focus on plans, tasks, decisions, and references."
        case .patientEncounter:
            modeContext = "Focus on clinical decisions, plans, follow-up tasks, and learning points."
        }

        let messages = [
            OpenRouterMessage(role: "system", content: """
            Extract structured memories and tasks from this transcript. \(modeContext)
            
            Respond with ONLY valid JSON in this format:
            {"memories":[{"type":"learningPearl|feedback|decision|plan|taskCandidate|reference","title":"...","body":"...","tags":["..."]}],"tasks":[{"title":"...","priority":"low|medium|high|urgent","notes":"..."}]}
            """),
            OpenRouterMessage(role: "user", content: text)
        ]

        let response = try await openRouter.sendMessage(messages: messages)
        return try parseExtractionJSON(response)
    }

    func generateEncounterDocs(transcript: String, visitType: String?) async throws -> EncounterDocs {
        let visitContext = visitType.map { "Visit type: \($0)." } ?? ""

        let messages = [
            OpenRouterMessage(role: "system", content: """
            You are a clinical documentation assistant. Generate two documents from this patient encounter transcript. \(visitContext)
            
            Respond with ONLY valid JSON:
            {"clinicianDraft":"<SOAP/H&P format with: Chief Complaint, HPI, Assessment, Plan, Action Items>","patientAVS":"<Plain language After Visit Summary with: What We Discussed, Medication Changes (if any), Follow-ups, Red Flags to Watch For>"}
            """),
            OpenRouterMessage(role: "user", content: transcript)
        ]

        let response = try await openRouter.sendMessage(messages: messages)
        return try parseEncounterDocsJSON(response)
    }

    func chatWithMemories(query: String, memories: [Memory], chatHistory: [OpenRouterMessage]) async throws -> (String, [Citation]) {
        var contextParts: [String] = []
        var potentialCitations: [(UUID, String, String)] = []

        for memory in memories {
            contextParts.append("[\(memory.id.uuidString)] \(memory.title): \(memory.body)")
            potentialCitations.append((memory.id, memory.title, String(memory.body.prefix(100))))
        }

        let context = contextParts.joined(separator: "\n\n")

        var messages = [
            OpenRouterMessage(role: "system", content: """
            You are Dr. Mem, a knowledgeable medical companion. Answer based on the user's stored memories when relevant. Reference memory IDs in brackets like [id] when citing.
            
            Available memories:
            \(context)
            """)
        ]
        messages.append(contentsOf: chatHistory)
        messages.append(OpenRouterMessage(role: "user", content: query))

        let response = try await openRouter.sendMessage(messages: messages)

        var citations: [Citation] = []
        for (id, title, snippet) in potentialCitations {
            if response.contains(id.uuidString) || response.localizedCaseInsensitiveContains(title) {
                citations.append(Citation(memoryId: id, memoryTitle: title, snippet: snippet))
            }
        }

        let cleanedResponse = response.replacingOccurrences(of: "\\[\\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}\\]", with: "", options: .regularExpression)
        return (cleanedResponse, citations)
    }

    private func parseExtractionJSON(_ text: String) throws -> ExtractionResult {
        let jsonString = extractJSON(from: text)
        guard let data = jsonString.data(using: .utf8) else { throw OpenRouterError.decodingFailed }
        return try JSONDecoder().decode(ExtractionResult.self, from: data)
    }

    private func parseEncounterDocsJSON(_ text: String) throws -> EncounterDocs {
        let jsonString = extractJSON(from: text)
        guard let data = jsonString.data(using: .utf8) else { throw OpenRouterError.decodingFailed }
        return try JSONDecoder().decode(EncounterDocs.self, from: data)
    }

    private func extractJSON(from text: String) -> String {
        var cleaned = text
        if let fenceStart = cleaned.range(of: "```json"), let fenceEnd = cleaned.range(of: "```", range: fenceStart.upperBound..<cleaned.endIndex) {
            cleaned = String(cleaned[fenceStart.upperBound..<fenceEnd.lowerBound])
        } else if let fenceStart = cleaned.range(of: "```"), let fenceEnd = cleaned.range(of: "```", range: fenceStart.upperBound..<cleaned.endIndex) {
            cleaned = String(cleaned[fenceStart.upperBound..<fenceEnd.lowerBound])
        }
        if let start = cleaned.firstIndex(of: "{"), let end = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[start...end])
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
