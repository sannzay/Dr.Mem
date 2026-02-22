import Foundation
import SwiftData

@Observable
class RAGService {
    func retrieveRelevantMemories(query: String, allMemories: [Memory], encounterId: UUID? = nil, limit: Int = 8) -> [Memory] {
        let queryWords = query.lowercased().split(separator: " ").map(String.init)

        var scored: [(Memory, Double)] = allMemories.compactMap { memory in
            var score = 0.0

            for word in queryWords {
                if memory.title.localizedCaseInsensitiveContains(word) { score += 3.0 }
                if memory.body.localizedCaseInsensitiveContains(word) { score += 1.5 }
                if memory.tags.contains(where: { $0.localizedCaseInsensitiveContains(word) }) { score += 2.0 }
            }

            if memory.pinned { score += 2.0 }

            let daysSinceCreation = Date().timeIntervalSince(memory.createdAt) / 86400
            let recencyBoost = max(0, 1.0 - (daysSinceCreation / 30.0))
            score += recencyBoost

            if let encounterId, memory.linkedEncounterId == encounterId {
                score += 5.0
            }

            guard score > 0 else { return nil }
            return (memory, score)
        }

        scored.sort { $0.1 > $1.1 }
        return Array(scored.prefix(limit).map(\.0))
    }
}
