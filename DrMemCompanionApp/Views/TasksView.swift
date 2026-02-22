import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]
    @State private var showCreate: Bool = false
    @State private var filterMode: TaskFilterMode = .all
    @State private var searchText: String = ""

    nonisolated enum TaskFilterMode: String, CaseIterable {
        case all = "All"
        case encounters = "Encounters"
        case personal = "Personal"
    }

    private var filteredTasks: [TaskItem] {
        var result = allTasks
        switch filterMode {
        case .encounters: result = result.filter { $0.linkedEncounterId != nil }
        case .personal: result = result.filter { $0.linkedEncounterId == nil }
        case .all: break
        }
        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    private var todayTasks: [TaskItem] {
        filteredTasks.filter { $0.status != .done && ($0.dueAt == nil || Calendar.current.isDateInToday($0.dueAt!)) }
    }

    private var upcomingTasks: [TaskItem] {
        filteredTasks.filter { $0.status != .done && $0.dueAt != nil && !Calendar.current.isDateInToday($0.dueAt!) && $0.dueAt! > Date() }
    }

    private var doneTasks: [TaskItem] {
        filteredTasks.filter { $0.status == .done }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                filterBar

                if filteredTasks.isEmpty {
                    ContentUnavailableView("No Tasks", systemImage: "checklist", description: Text("Tasks will appear after sessions"))
                        .padding(.top, 60)
                } else {
                    taskSection("Today", tasks: todayTasks, icon: "sun.max.fill")
                    taskSection("Upcoming", tasks: upcomingTasks, icon: "calendar")
                    taskSection("Done", tasks: doneTasks, icon: "checkmark.circle.fill")
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .searchable(text: $searchText, prompt: "Search tasks")
        .scrollDismissesKeyboard(.interactively)
        .background { WarmBackground() }
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showCreate = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateTaskSheet()
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(TaskFilterMode.allCases, id: \.self) { mode in
                    GlassPill(title: mode.rawValue, isSelected: filterMode == mode) {
                        filterMode = mode
                    }
                }
            }
        }
        .contentMargins(.horizontal, 0)
        .scrollIndicators(.hidden)
    }

    private func taskSection(_ title: String, tasks: [TaskItem], icon: String) -> some View {
        Group {
            if !tasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundStyle(DrMemTheme.terracotta)
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    ForEach(tasks) { task in
                        taskRow(task)
                    }
                }
            }
        }
    }

    private func taskRow(_ task: TaskItem) -> some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    task.status = task.status == .done ? .todo : .done
                }
            } label: {
                Image(systemName: task.status == .done ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.status == .done ? .green : DrMemTheme.warmGray)
                    .contentTransition(.symbolEffect(.replace))
            }
            .sensoryFeedback(.success, trigger: task.status == .done)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline.weight(.medium))
                    .strikethrough(task.status == .done)
                    .foregroundStyle(task.status == .done ? .secondary : DrMemTheme.darkText)

                if let due = task.dueAt {
                    Text(due, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if task.linkedEncounterId != nil {
                Image(systemName: "stethoscope")
                    .font(.caption2)
                    .foregroundStyle(DrMemTheme.terracotta)
            }

            Button(role: .destructive) {
                modelContext.delete(task)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.5))
            }
        }
        .padding(12)
        .glassCard(cornerRadius: 12)
    }
}

struct CreateTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var priority: TaskPriority = .medium
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task title", text: $title)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }

                    Toggle("Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let task = TaskItem(title: title, priority: priority)
                        task.notes = notes
                        task.dueAt = hasDueDate ? dueDate : nil
                        modelContext.insert(task)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
