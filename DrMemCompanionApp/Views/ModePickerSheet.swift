import SwiftUI

struct ModePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (CaptureMode) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Select Mode")
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .padding(.top, 8)

                ForEach(CaptureMode.allCases, id: \.self) { mode in
                    Button {
                        onSelect(mode)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: mode.icon)
                                .font(.title2)
                                .foregroundStyle(DrMemTheme.terracotta)
                                .frame(width: 44, height: 44)
                                .background(DrMemTheme.terracotta.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.rawValue)
                                    .font(.headline)
                                    .foregroundStyle(DrMemTheme.darkText)

                                Text(modeDescription(mode))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(14)
                        .glassCard(cornerRadius: 14)
                    }
                }

                Spacer()
            }
            .padding()
            .background { WarmBackground() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func modeDescription(_ mode: CaptureMode) -> String {
        switch mode {
        case .education: "Teaching rounds, supervision, clinical pearls"
        case .brainDump: "Quick notes, ideas, personal productivity"
        case .patientEncounter: "SOAP/H&P drafts + patient summary"
        }
    }
}
