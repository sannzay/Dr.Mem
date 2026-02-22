import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var apiKey: String = ""
    @State private var showKey: Bool = false
    @State private var deleteAudioAfterTranscription: Bool = true
    @State private var requireReviewBeforeExport: Bool = true
    @State private var showDeleteAllAlert: Bool = false
    @State private var keySaved: Bool = false

    @Bindable var openRouter: OpenRouterService
    let biometricService: BiometricService

    var body: some View {
        Form {
            Section("OpenRouter API") {
                HStack(spacing: 8) {
                    Group {
                        if showKey {
                            TextField("API Key", text: $apiKey)
                                .textContentType(.password)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("API Key", text: $apiKey)
                        }
                    }

                    Button {
                        showKey.toggle()
                    } label: {
                        Image(systemName: showKey ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(DrMemTheme.warmGray)
                            .frame(width: 30, height: 30)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                }

                Button {
                    let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    KeychainService.save(key: KeychainService.apiKeyAccount, value: trimmed)
                    keySaved = true
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        keySaved = false
                    }
                } label: {
                    HStack {
                        Image(systemName: keySaved ? "checkmark.circle.fill" : "key.fill")
                            .foregroundStyle(keySaved ? .green : DrMemTheme.terracotta)
                        Text(keySaved ? "Key Saved" : "Save Key")
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(.borderless)
                .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .sensoryFeedback(.success, trigger: keySaved)

                Picker("Model", selection: $openRouter.selectedModel) {
                    Text("Claude Sonnet 4").tag("anthropic/claude-sonnet-4")
                    Text("Claude Haiku 3.5").tag("anthropic/claude-3.5-haiku")
                    Text("GPT-4o").tag("openai/gpt-4o")
                    Text("GPT-4o Mini").tag("openai/gpt-4o-mini")
                }
                .pickerStyle(.menu)

                HStack {
                    Text("Temperature")
                    Spacer()
                    Text(String(format: "%.1f", openRouter.temperature))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $openRouter.temperature, in: 0...1, step: 0.1)
                    .tint(DrMemTheme.terracotta)
            }

            Section("Security") {
                Toggle("App Lock (Face ID)", isOn: Binding(
                    get: { biometricService.isLockEnabled },
                    set: { biometricService.toggleLock($0) }
                ))
                .tint(DrMemTheme.terracotta)
                .sensoryFeedback(.selection, trigger: biometricService.isLockEnabled)
            }

            Section("Privacy") {
                Toggle("Delete audio after transcription", isOn: $deleteAudioAfterTranscription)
                    .tint(DrMemTheme.terracotta)
                Toggle("Require review before export", isOn: $requireReviewBeforeExport)
                    .tint(DrMemTheme.terracotta)

                HStack(spacing: 8) {
                    Image(systemName: "shield.checkered")
                        .foregroundStyle(DrMemTheme.terracotta)
                    Text("Patient encounters default to Note Only retention")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Data") {
                Button {
                    exportAllData()
                } label: {
                    Label("Export All Data (JSON)", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderless)

                Button(role: .destructive) {
                    showDeleteAllAlert = true
                } label: {
                    Label("Delete All Data", systemImage: "trash")
                }
                .buttonStyle(.borderless)
            }
        }
        .navigationTitle("Settings")
        .background { WarmBackground() }
        .scrollContentBackground(.hidden)
        .alert("Delete All Data?", isPresented: $showDeleteAllAlert) {
            Button("Delete Everything", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
        .onAppear {
            apiKey = KeychainService.openRouterKey ?? ""
        }
    }

    private func exportAllData() {
        var export: [String: Any] = [:]
        if let sessions = try? modelContext.fetch(FetchDescriptor<Session>()) {
            export["sessionsCount"] = sessions.count
        }
        if let memories = try? modelContext.fetch(FetchDescriptor<Memory>()) {
            export["memoriesCount"] = memories.count
        }
        let jsonString = "Dr. Mem Export - \(Date())\nSessions: \(export["sessionsCount"] ?? 0), Memories: \(export["memoriesCount"] ?? 0)"
        let av = UIActivityViewController(activityItems: [jsonString], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
    }

    private func deleteAllData() {
        try? modelContext.delete(model: Session.self)
        try? modelContext.delete(model: Memory.self)
        try? modelContext.delete(model: TaskItem.self)
        try? modelContext.delete(model: JournalEntry.self)
        try? modelContext.delete(model: ChatThread.self)
        try? modelContext.delete(model: TranscriptSegment.self)
        try? modelContext.save()
    }
}
