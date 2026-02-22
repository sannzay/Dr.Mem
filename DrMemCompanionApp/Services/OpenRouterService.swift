import Foundation

nonisolated struct OpenRouterMessage: Codable, Sendable {
    let role: String
    let content: String
}

nonisolated struct OpenRouterRequest: Codable, Sendable {
    let model: String
    let messages: [OpenRouterMessage]
    let temperature: Double
    let stream: Bool

    init(model: String, messages: [OpenRouterMessage], temperature: Double = 0.7, stream: Bool = false) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.stream = stream
    }
}

nonisolated struct OpenRouterResponse: Codable, Sendable {
    let choices: [Choice]

    struct Choice: Codable, Sendable {
        let message: MessageContent
    }

    struct MessageContent: Codable, Sendable {
        let content: String
    }
}

nonisolated struct StreamChunk: Codable, Sendable {
    let choices: [StreamChoice]?

    struct StreamChoice: Codable, Sendable {
        let delta: Delta?
    }

    struct Delta: Codable, Sendable {
        let content: String?
    }
}

@Observable
class OpenRouterService {
    var selectedModel: String = "anthropic/claude-sonnet-4"
    var temperature: Double = 0.7
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"

    private var apiKey: String? {
        KeychainService.openRouterKey
    }

    var isConfigured: Bool {
        apiKey != nil && !(apiKey?.isEmpty ?? true)
    }

    func sendMessage(messages: [OpenRouterMessage]) async throws -> String {
        guard let apiKey, !apiKey.isEmpty else {
            throw OpenRouterError.noAPIKey
        }

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = OpenRouterRequest(
            model: selectedModel,
            messages: messages,
            temperature: temperature,
            stream: false
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OpenRouterError.requestFailed
        }

        let result = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        return result.choices.first?.message.content ?? ""
    }

    func streamMessage(messages: [OpenRouterMessage], onChunk: @escaping (String) -> Void) async throws {
        guard let apiKey, !apiKey.isEmpty else {
            throw OpenRouterError.noAPIKey
        }

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = OpenRouterRequest(
            model: selectedModel,
            messages: messages,
            temperature: temperature,
            stream: true
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OpenRouterError.requestFailed
        }

        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let jsonString = String(line.dropFirst(6))
            guard jsonString != "[DONE]" else { break }
            guard let jsonData = jsonString.data(using: .utf8) else { continue }

            if let chunk = try? JSONDecoder().decode(StreamChunk.self, from: jsonData),
               let content = chunk.choices?.first?.delta?.content {
                onChunk(content)
            }
        }
    }
}

nonisolated enum OpenRouterError: Error, LocalizedError, Sendable {
    case noAPIKey
    case requestFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .noAPIKey: "No API key configured. Add your OpenRouter key in Settings."
        case .requestFailed: "Request failed. Check your API key and internet connection."
        case .decodingFailed: "Failed to parse the response."
        }
    }
}
