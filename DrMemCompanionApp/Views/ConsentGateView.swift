import SwiftUI

struct ConsentGateView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var consentChecked: Bool = false
    @State private var patientAlias: String = ""
    @State private var selectedVisitType: VisitType = .outpatient
    let onConsent: (String?, VisitType?) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Patient Encounter Mode", systemImage: "stethoscope")
                            .font(.system(.title3, design: .serif, weight: .semibold))
                            .foregroundStyle(DrMemTheme.terracotta)

                        Text("Consent is required before recording begins.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Consent Script")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)

                        Text("\"To help me focus and draft accurate notes, may I record this visit? I will delete the audio after the note is created. You can ask me to stop anytime.\"")
                            .font(.body)
                            .italic()
                            .padding(14)
                            .background(Color.white.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Visit Details")
                            .font(.subheadline.weight(.semibold))

                        TextField("Patient alias (initials only)", text: $patientAlias)
                            .textFieldStyle(.roundedBorder)

                        Picker("Visit Type", selection: $selectedVisitType) {
                            ForEach(VisitType.allCases, id: \.self) { type in
                                Label(type.rawValue, systemImage: type.icon).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Toggle(isOn: $consentChecked) {
                        Text("I obtained patient consent for this recording")
                            .font(.subheadline.weight(.medium))
                    }
                    .tint(DrMemTheme.terracotta)

                    Button {
                        let alias = patientAlias.isEmpty ? nil : patientAlias
                        onConsent(alias, selectedVisitType)
                    } label: {
                        Text("Begin Recording")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(consentChecked ? DrMemTheme.terracotta : Color.gray.opacity(0.4), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!consentChecked)
                    .sensoryFeedback(.success, trigger: consentChecked)
                }
                .padding()
            }
            .background { WarmBackground() }
            .navigationTitle("Consent Required")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
