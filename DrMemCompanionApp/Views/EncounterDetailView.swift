import SwiftUI
import SwiftData

struct EncounterDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let encounter: Session
    @State private var selectedTab: EncounterTab = .summary
    @State private var editingDraft: Bool = false
    @State private var draftText: String = ""
    @State private var editingAVS: Bool = false
    @State private var avsText: String = ""
    @State private var reviewChecked: Bool = false
    @State private var showDeleteAlert: Bool = false

    nonisolated enum EncounterTab: String, CaseIterable {
        case summary = "Summary"
        case clinician = "Draft"
        case avs = "AVS"
        case transcript = "Transcript"
        case tasks = "Tasks"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tab", selection: $selectedTab) {
                    ForEach(EncounterTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        switch selectedTab {
                        case .summary: summaryTab
                        case .clinician: clinicianTab
                        case .avs: avsTab
                        case .transcript: transcriptTab
                        case .tasks: tasksTab
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .background { WarmBackground() }
            .navigationTitle(encounter.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) { showDeleteAlert = true } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .alert("Delete Encounter?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteEncounterAndLinked()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will also delete linked tasks and memories.")
            }
            .onAppear {
                draftText = encounter.clinicianDocDraft ?? ""
                avsText = encounter.patientAVS ?? ""
                reviewChecked = encounter.reviewedByClinician
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var summaryTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            encounterMeta

            if let summary = encounter.summary {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Summary")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                    Text(summary)
                        .font(.body)
                }
                .padding(14)
                .glassCard(cornerRadius: 12)
            }

            if encounter.consentAttested {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                    Text("Consent attested")
                        .font(.caption)
                    if let ts = encounter.consentTimestamp {
                        Text(ts, style: .date)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(10)
                .glassCard(cornerRadius: 8)
            }
        }
    }

    private var encounterMeta: some View {
        HStack(spacing: 16) {
            if let vt = encounter.visitType {
                Label(vt.rawValue, systemImage: vt.icon)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(DrMemTheme.terracotta)
            }
            if let alias = encounter.patientAlias {
                Label(alias, systemImage: "person")
                    .font(.caption.weight(.medium))
            }
            if let dur = encounter.durationSec {
                Label("\(dur / 60)m", systemImage: "clock")
                    .font(.caption.weight(.medium))
            }
        }
        .foregroundStyle(.secondary)
    }

    private var clinicianTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            if editingDraft {
                TextEditor(text: $draftText)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .background(Color.white.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
                    .frame(minHeight: 300)

                Button("Save") {
                    encounter.clinicianDocDraft = draftText
                    editingDraft = false
                }
                .buttonStyle(.borderedProminent)
                .tint(DrMemTheme.terracotta)
            } else {
                Text(encounter.clinicianDocDraft ?? "No draft generated yet.")
                    .font(.body)
                    .padding(14)
                    .glassCard(cornerRadius: 12)
            }

            HStack(spacing: 10) {
                Button { editingDraft.toggle() } label: {
                    Label(editingDraft ? "Cancel" : "Edit", systemImage: editingDraft ? "xmark" : "pencil")
                }
                .buttonStyle(.bordered)

                Button {
                    UIPasteboard.general.string = encounter.clinicianDocDraft
                    encounter.clinicianDraftExportedAt.append(Date())
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .disabled(!encounter.reviewedByClinician)
            }

            Toggle(isOn: $reviewChecked) {
                Text("Reviewed for accuracy")
                    .font(.subheadline.weight(.medium))
            }
            .tint(DrMemTheme.terracotta)
            .onChange(of: reviewChecked) { _, newValue in
                encounter.reviewedByClinician = newValue
                if newValue { encounter.reviewTimestamp = Date() }
            }
        }
    }

    private var avsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            if editingAVS {
                TextEditor(text: $avsText)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .background(Color.white.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
                    .frame(minHeight: 300)

                Button("Save") {
                    encounter.patientAVS = avsText
                    editingAVS = false
                }
                .buttonStyle(.borderedProminent)
                .tint(DrMemTheme.terracotta)
            } else {
                Text(encounter.patientAVS ?? "No AVS generated yet.")
                    .font(.body)
                    .padding(14)
                    .glassCard(cornerRadius: 12)
            }

            HStack(spacing: 10) {
                Button { editingAVS.toggle() } label: {
                    Label(editingAVS ? "Cancel" : "Edit", systemImage: editingAVS ? "xmark" : "pencil")
                }
                .buttonStyle(.bordered)

                Button {
                    shareAVS()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .disabled(!encounter.reviewedByClinician)
            }
        }
    }

    private var transcriptTab: some View {
        Group {
            if encounter.retentionPolicy == .keepTranscript && !encounter.transcriptText.isEmpty {
                Text(encounter.transcriptText)
                    .font(.body)
                    .padding(14)
                    .glassCard(cornerRadius: 12)
            } else {
                ContentUnavailableView("Transcript Not Retained", systemImage: "doc.text", description: Text("Retention policy is set to Note Only"))
            }
        }
    }

    @Query private var allTasks: [TaskItem]

    private var linkedTasks: [TaskItem] {
        allTasks.filter { $0.linkedEncounterId == encounter.id }
    }

    private var tasksTab: some View {
        VStack(alignment: .leading, spacing: 8) {
            if linkedTasks.isEmpty {
                ContentUnavailableView("No Tasks", systemImage: "checklist", description: Text("No tasks linked to this encounter"))
            } else {
                ForEach(linkedTasks) { task in
                    HStack(spacing: 10) {
                        Image(systemName: task.status == .done ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(task.status == .done ? .green : .secondary)

                        Text(task.title)
                            .font(.subheadline)
                            .strikethrough(task.status == .done)

                        Spacer()

                        Text(task.priority.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(10)
                    .glassCard(cornerRadius: 10)
                }
            }
        }
    }

    private func shareAVS() {
        guard let text = encounter.patientAVS else { return }
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
        encounter.patientAVSExportedAt.append(Date())
    }

    private func deleteEncounterAndLinked() {
        let encId = encounter.id
        if let tasks = try? modelContext.fetch(FetchDescriptor<TaskItem>()) {
            for task in tasks where task.linkedEncounterId == encId {
                modelContext.delete(task)
            }
        }
        if let memories = try? modelContext.fetch(FetchDescriptor<Memory>()) {
            for memory in memories where memory.linkedEncounterId == encId {
                modelContext.delete(memory)
            }
        }
        modelContext.delete(encounter)
    }
}
