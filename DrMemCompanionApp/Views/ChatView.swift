import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: ChatViewModel
    let openRouter: OpenRouterService

    var body: some View {
        VStack(spacing: 0) {
            if let thread = viewModel.currentThread, !thread.messages.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(thread.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }

                            if viewModel.isStreaming {
                                HStack {
                                    ProgressView()
                                        .tint(DrMemTheme.terracotta)
                                    Text("Thinking...")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: thread.messages.count) { _, _ in
                        if let last = thread.messages.last {
                            withAnimation(.spring(response: 0.3)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            } else {
                emptyState
            }

            GlassInputBar(
                text: $viewModel.inputText,
                placeholder: "Ask Dr. Mem anything...",
                onSend: {
                    Task { await viewModel.sendMessage(modelContext: modelContext) }
                },
                onMic: nil,
                onPlus: nil
            )
            .padding(.horizontal)
            .padding(.bottom, 4)
        }

    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "stethoscope")
                .font(.system(size: 48))
                .foregroundStyle(DrMemTheme.terracotta.opacity(0.5))
                .symbolEffect(.pulse, options: .repeating)

            Text("How can I help you today?")
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(DrMemTheme.darkText)

            Text("Ask me anything — I'll search your memories for context.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if !openRouter.isConfigured {
                HStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .foregroundStyle(.orange)
                    Text("Add your OpenRouter API key in Settings to get started.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .glassCard(cornerRadius: 12)
                .padding(.horizontal, 32)
            }

            Spacer()
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == "user" }

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
            HStack {
                if isUser { Spacer(minLength: 60) }

                Text(message.content)
                    .font(.body)
                    .foregroundStyle(isUser ? .white : DrMemTheme.darkText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isUser ? DrMemTheme.terracotta : Color.white.opacity(0.7))
                            .shadow(color: DrMemTheme.shadowColor, radius: 3, y: 2)
                    }

                if !isUser { Spacer(minLength: 60) }
            }

            if !message.citations.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(message.citations) { citation in
                            Text(citation.memoryTitle)
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(DrMemTheme.terracotta.opacity(0.12), in: Capsule())
                                .foregroundStyle(DrMemTheme.terracotta)
                        }
                    }
                }
                .contentMargins(.horizontal, 16)
                .scrollIndicators(.hidden)
            }
        }
        .padding(.horizontal)
    }
}
