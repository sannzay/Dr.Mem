import SwiftUI
import SwiftData

struct MemoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Memory.createdAt, order: .reverse) private var memories: [Memory]
    @State private var searchText: String = ""
    @State private var selectedType: MemoryType?
    @State private var selectedMode: CaptureMode?
    @State private var selectedMemory: Memory?

    private var filteredMemories: [Memory] {
        var result = memories
        if let type = selectedType { result = result.filter { $0.type == type } }
        if let mode = selectedMode { result = result.filter { $0.mode == mode } }
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.body.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                filterBar

                if filteredMemories.isEmpty {
                    ContentUnavailableView("No Memories", systemImage: "brain", description: Text("Memories will appear here after sessions"))
                        .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredMemories) { memory in
                            Button { selectedMemory = memory } label: {
                                memoryCard(memory)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .searchable(text: $searchText, prompt: "Search memories")
        .scrollDismissesKeyboard(.interactively)
        .background { WarmBackground() }
        .navigationTitle("Memories")
        .sheet(item: $selectedMemory) { memory in
            MemoryDetailSheet(memory: memory)
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                GlassPill(title: "All", isSelected: selectedType == nil && selectedMode == nil) {
                    selectedType = nil
                    selectedMode = nil
                }

                ForEach(MemoryType.allCases, id: \.self) { type in
                    GlassPill(title: type.rawValue, isSelected: selectedType == type) {
                        selectedType = selectedType == type ? nil : type
                    }
                }
            }
        }
        .contentMargins(.horizontal, 0)
        .scrollIndicators(.hidden)
    }

    private func memoryCard(_ memory: Memory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: memory.type.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(DrMemTheme.terracotta)

                Text(memory.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DrMemTheme.darkText)
                    .lineLimit(1)

                Spacer()

                if memory.pinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(DrMemTheme.terracotta)
                }
            }

            Text(memory.body)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            if !memory.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(memory.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DrMemTheme.terracotta.opacity(0.1), in: Capsule())
                            .foregroundStyle(DrMemTheme.terracotta)
                    }
                }
            }

            HStack {
                Text(memory.mode.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                Text(memory.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 14)
    }
}

struct MemoryDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let memory: Memory
    @State private var isEditing: Bool = false
    @State private var editBody: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: memory.type.icon)
                            .foregroundStyle(DrMemTheme.terracotta)
                        Text(memory.type.rawValue)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(DrMemTheme.terracotta)

                        Spacer()

                        Text(memory.mode.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(memory.title)
                        .font(.system(.title3, design: .serif, weight: .semibold))

                    if isEditing {
                        TextEditor(text: $editBody)
                            .frame(minHeight: 120)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(Color.white.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                    } else {
                        Text(memory.body)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    if !memory.tags.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 6)], alignment: .leading, spacing: 6) {
                            ForEach(memory.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(DrMemTheme.terracotta.opacity(0.1), in: Capsule())
                                    .foregroundStyle(DrMemTheme.terracotta)
                            }
                        }
                    }

                    if !memory.sourceSnippet.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Source")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)

                            Text(memory.sourceSnippet)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(10)
                                .background(Color.white.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    if memory.linkedEncounterId != nil {
                        Label("Linked to Encounter", systemImage: "link")
                            .font(.caption)
                            .foregroundStyle(DrMemTheme.terracotta)
                    }

                    HStack(spacing: 12) {
                        Button {
                            memory.pinned.toggle()
                        } label: {
                            Label(memory.pinned ? "Unpin" : "Pin", systemImage: memory.pinned ? "pin.slash" : "pin")
                        }
                        .buttonStyle(.bordered)

                        Button(role: .destructive) {
                            modelContext.delete(memory)
                            dismiss()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .background { WarmBackground() }
            .navigationTitle("Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if isEditing {
                        Button("Save") {
                            memory.body = editBody
                            isEditing = false
                        }
                    } else {
                        Button("Edit") {
                            editBody = memory.body
                            isEditing = true
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
