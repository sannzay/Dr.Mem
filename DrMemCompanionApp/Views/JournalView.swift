import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @State private var showCreate: Bool = false
    @State private var searchText: String = ""

    private var filteredEntries: [JournalEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter { $0.contentText.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if filteredEntries.isEmpty {
                    ContentUnavailableView("No Entries", systemImage: "book", description: Text("Tap + to create your first journal entry"))
                        .padding(.top, 60)
                } else {
                    ForEach(filteredEntries) { entry in
                        journalCard(entry)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .searchable(text: $searchText, prompt: "Search journal")
        .scrollDismissesKeyboard(.interactively)
        .background { WarmBackground() }
        .navigationTitle("Journal")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showCreate = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateJournalSheet()
        }
    }

    private func journalCard(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: entry.type == .voice ? "mic.fill" : (entry.type == .image ? "photo" : "text.alignleft"))
                    .foregroundStyle(DrMemTheme.terracotta)
                    .font(.caption)

                Text(entry.createdAt, style: .date)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Button(role: .destructive) {
                    modelContext.delete(entry)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.6))
                }
            }

            Text(entry.contentText)
                .font(.body)
                .foregroundStyle(DrMemTheme.darkText)
                .lineLimit(5)

            if !entry.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(entry.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DrMemTheme.terracotta.opacity(0.1), in: Capsule())
                            .foregroundStyle(DrMemTheme.terracotta)
                    }
                }
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 14)
    }
}

struct CreateJournalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var text: String = ""
    @State private var entryType: JournalEntryType = .text

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Type", selection: $entryType) {
                    ForEach(JournalEntryType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(Color.white.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
                    .frame(minHeight: 200)

                Spacer()
            }
            .padding()
            .background { WarmBackground() }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let entry = JournalEntry(type: entryType, contentText: text)
                        modelContext.insert(entry)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
