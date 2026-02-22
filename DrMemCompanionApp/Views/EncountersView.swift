import SwiftUI
import SwiftData

struct EncountersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Session.createdAt, order: .reverse) private var allSessions: [Session]

    private var encounters: [Session] {
        allSessions.filter { $0.sessionType == .encounter }
    }
    @State private var searchText: String = ""
    @State private var selectedEncounter: Session?

    private var filteredEncounters: [Session] {
        guard !searchText.isEmpty else { return encounters }
        return encounters.filter {
            ($0.patientAlias ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.summary ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedEncounters: [(String, [Session])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let grouped = Dictionary(grouping: filteredEncounters) { formatter.string(from: $0.createdAt) }
        return grouped.sorted { $0.value.first!.createdAt > $1.value.first!.createdAt }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if filteredEncounters.isEmpty {
                    ContentUnavailableView("No Encounters", systemImage: "stethoscope", description: Text("Patient encounters will appear here"))
                        .padding(.top, 60)
                } else {
                    ForEach(groupedEncounters, id: \.0) { date, sessions in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(date)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                                .padding(.leading, 4)

                            ForEach(sessions) { session in
                                Button { selectedEncounter = session } label: {
                                    encounterRow(session)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .searchable(text: $searchText, prompt: "Search encounters")
        .scrollDismissesKeyboard(.interactively)
        .background { WarmBackground() }
        .navigationTitle("Encounters")
        .sheet(item: $selectedEncounter) { encounter in
            EncounterDetailView(encounter: encounter)
        }
    }

    private func encounterRow(_ session: Session) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(DrMemTheme.terracotta.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: session.visitType?.icon ?? "stethoscope")
                        .font(.system(size: 18))
                        .foregroundStyle(DrMemTheme.terracotta)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(session.displayTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DrMemTheme.darkText)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let duration = session.durationSec {
                        Text("\(duration / 60)m")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Text(session.status.rawValue.capitalized)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(session.status == .ready ? .green : .orange)
                }
            }

            Spacer()

            Text(session.createdAt, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .glassCard(cornerRadius: 14)
    }
}
