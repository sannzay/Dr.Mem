import SwiftUI
import SwiftData

struct ListeningView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var sessionVM: SessionViewModel
    let bleService: OmiBLEService
    @State private var showModePicker: Bool = false
    @State private var showConsentGate: Bool = false
    @State private var pendingMode: CaptureMode?
    @State private var scanTrigger: Bool = false
    @State private var pendingSource: SessionSource = .phoneMic
    @State private var micTrigger: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                omiConnectionCard
                recordingSection

                if sessionVM.isRecording {
                    activeRecordingView
                } else if sessionVM.isProcessing {
                    processingView
                }

                if let error = sessionVM.errorMessage, !sessionVM.isRecording && !sessionVM.isProcessing {
                    errorBanner(error)
                }

                if let speechError = sessionVM.speechService.errorMessage, !sessionVM.isRecording && !sessionVM.isProcessing {
                    if sessionVM.errorMessage != speechError {
                        errorBanner(speechError)
                    }
                }
            }
            .padding()
        }
        .background { WarmBackground() }
        .navigationTitle("Listening")
        .sheet(isPresented: $showModePicker) {
            ModePickerSheet { mode in
                showModePicker = false
                if mode == .patientEncounter {
                    pendingMode = mode
                    showConsentGate = true
                } else {
                    sessionVM.startRecording(
                        mode: mode,
                        source: pendingSource,
                        modelContext: modelContext,
                        bleService: pendingSource == .omiDevice ? bleService : nil
                    )
                }
            }
        }
        .sheet(isPresented: $showConsentGate) {
            ConsentGateView { alias, visitType in
                showConsentGate = false
                sessionVM.startRecording(
                    mode: .patientEncounter,
                    source: pendingSource,
                    modelContext: modelContext,
                    bleService: pendingSource == .omiDevice ? bleService : nil
                )
                if let session = sessionVM.currentSession {
                    session.patientAlias = alias
                    session.visitType = visitType
                    session.consentAttested = true
                    session.consentTimestamp = Date()
                }
            }
        }
    }

    private var omiConnectionCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(bleService.isConnected ? Color.green.opacity(0.15) : DrMemTheme.terracotta.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: bleService.isConnected ? "checkmark.circle.fill" : "antenna.radiowaves.left.and.right")
                        .font(.title3)
                        .foregroundStyle(bleService.isConnected ? .green : DrMemTheme.terracotta)
                        .symbolEffect(.pulse, isActive: bleService.isScanning)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(bleService.isConnected ? (bleService.discoveredDeviceName ?? "Omi Connected") : "Omi Device")
                        .font(.headline)
                        .foregroundStyle(DrMemTheme.darkText)

                    Text(bleService.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if bleService.isConnected {
                    Button {
                        bleService.disconnect()
                    } label: {
                        Text("Disconnect")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1), in: Capsule())
                    }
                    .sensoryFeedback(.warning, trigger: bleService.isConnected)
                } else {
                    Button {
                        scanTrigger.toggle()
                        bleService.startScan()
                    } label: {
                        Text(bleService.isScanning ? "Scanning..." : "Scan")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(DrMemTheme.terracotta, in: Capsule())
                    }
                    .disabled(bleService.isScanning)
                    .sensoryFeedback(.impact(flexibility: .soft), trigger: scanTrigger)
                }
            }

            if bleService.isScanning {
                ProgressView()
                    .tint(DrMemTheme.terracotta)
                    .scaleEffect(0.8)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(16)
        .glassCard()
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: bleService.isConnected)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: bleService.isScanning)
    }

    private var recordingSection: some View {
        VStack(spacing: 12) {
            if !sessionVM.isRecording && !sessionVM.isProcessing {
                HStack(spacing: 16) {
                    Button {
                        pendingSource = bleService.isConnected ? .omiDevice : .phoneMic
                        showModePicker = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "record.circle")
                                .font(.title2)
                            Text("Start Session")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(DrMemTheme.terracotta)
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    RadialGradient(
                                        colors: [Color.white.opacity(0.2), Color.clear],
                                        center: .topLeading,
                                        startRadius: 0,
                                        endRadius: 120
                                    )
                                )
                        }
                        .shadow(color: DrMemTheme.terracotta.opacity(0.3), radius: 8, y: 4)
                    }
                    .sensoryFeedback(.impact(flexibility: .soft), trigger: showModePicker)

                    Button {
                        micTrigger.toggle()
                        pendingSource = .phoneMic
                        showModePicker = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(DrMemTheme.terracotta)
                                .frame(width: 56, height: 56)
                                .shadow(color: DrMemTheme.terracotta.opacity(0.3), radius: 6, y: 3)

                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.white.opacity(0.25), Color.clear],
                                        center: .topLeading,
                                        startRadius: 0,
                                        endRadius: 30
                                    )
                                )
                                .frame(width: 56, height: 56)

                            Image(systemName: "mic.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                    }
                    .sensoryFeedback(.impact(flexibility: .rigid), trigger: micTrigger)
                }

                if bleService.isConnected {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.caption2)
                        Text("Both buttons use your iPhone microphone for live transcription. Omi connection is maintained for session tracking.")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var activeRecordingView: some View {
        VStack(spacing: 16) {
            HStack {
                Circle()
                    .fill(.red)
                    .frame(width: 10, height: 10)
                    .shadow(color: .red.opacity(0.6), radius: 4)

                Text("Recording")
                    .font(.headline)
                    .foregroundStyle(.red)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: sessionVM.currentSession?.source == .omiDevice ? "antenna.radiowaves.left.and.right" : "mic.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(sessionVM.currentSession?.source == .omiDevice ? "Omi + Mic" : "Phone Mic")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(sessionVM.formattedDuration)
                    .font(.system(.title3, design: .monospaced, weight: .semibold))
                    .foregroundStyle(DrMemTheme.darkText)
            }

            Text(sessionVM.selectedMode.rawValue)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "waveform")
                        .font(.caption)
                        .foregroundStyle(DrMemTheme.terracotta)
                        .symbolEffect(.variableColor.iterative, isActive: sessionVM.isRecording)
                    Text("Live Transcript")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    Spacer()

                    if !sessionVM.liveTranscript.isEmpty {
                        Text("\(sessionVM.liveTranscript.split(separator: " ").count) words")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        Text(sessionVM.liveTranscript.isEmpty ? "Listening for speech..." : sessionVM.liveTranscript)
                            .font(.body)
                            .foregroundStyle(sessionVM.liveTranscript.isEmpty ? .tertiary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("transcript")
                    }
                    .frame(maxHeight: 200)
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .onChange(of: sessionVM.liveTranscript) { _, _ in
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo("transcript", anchor: .bottom)
                        }
                    }
                }
            }

            if let error = sessionVM.speechService.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Button {
                Task { await sessionVM.stopRecording(modelContext: modelContext) }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "stop.circle.fill")
                    Text("Stop Recording")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.red, in: RoundedRectangle(cornerRadius: 14))
            }
            .sensoryFeedback(.impact(weight: .heavy), trigger: sessionVM.isRecording)
        }
        .padding(16)
        .glassCard()
        .transition(.scale.combined(with: .opacity))
    }

    private var processingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(DrMemTheme.terracotta)
            Text("Processing transcript...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !sessionVM.liveTranscript.isEmpty {
                Text("\(sessionVM.liveTranscript.split(separator: " ").count) words captured")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(24)
        .glassCard()
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .glassCard(cornerRadius: 10)
    }

}
