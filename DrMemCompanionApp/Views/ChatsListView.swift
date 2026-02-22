import SwiftUI
import SwiftData

struct ChatsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatThread.updatedAt, order: .reverse) private var threads: [ChatThread]
    @Bindable var viewModel: ChatViewModel
    @State private var searchText: String = ""
    let onSelectThread: () -> Void

    private var filteredThreads: [ChatThread] {
        guard !searchText.isEmpty else { return threads }
        return threads.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if filteredThreads.isEmpty {
                    ContentUnavailableView("No Chats Yet", systemImage: "bubble.left.and.bubble.right", description: Text("Start a conversation with Dr. Mem"))
                        .padding(.top, 60)
                } else {
                    ForEach(filteredThreads) { thread in
                        Button {
                            viewModel.currentThread = thread
                            onSelectThread()
                        } label: {
                            chatRow(thread)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .searchable(text: $searchText, prompt: "Search chats")
        .scrollDismissesKeyboard(.interactively)
        .background { WarmBackground() }
        .navigationTitle("Chats")
    }

    private func chatRow(_ thread: ChatThread) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(DrMemTheme.terracotta.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(DrMemTheme.terracotta)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(thread.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DrMemTheme.darkText)
                    .lineLimit(1)

                Text(thread.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .glassCard(cornerRadius: 12)
    }
}
