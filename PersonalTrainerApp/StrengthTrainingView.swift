import SwiftUI
import SwiftData

struct StrengthTrainingView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \MuscleGroup.displayOrder) private var muscleGroups: [MuscleGroup]
    @Query private var exercises: [Exercise]
    @Query private var settings: [AppSettings]
    @Binding var path: NavigationPath
    @State private var showingAdd = false
    @State private var showingManage = false

    private var lastExercise: Exercise? {
        exercises.filter { $0.lastLogDate != nil }.max { $0.lastLogDate! < $1.lastLogDate! }
    }

    private var todaySets: [WorkoutSet] {
        exercises.flatMap(\.sets).filter { Calendar.current.isDateInToday($0.date) }
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), alignment: .top), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                let name = settings.first?.userName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                Text(name.isEmpty ? "Your training, one set at a time." : "Ready to train, \(name)?")
                    .font(.title3.weight(.semibold))
                Text(todaySets.isEmpty ? "No sets yet today. Choose an exercise to begin." : "\(todaySets.count) sets logged today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("TodaySummary")
            }

            if let exercise = lastExercise {
                Button {
                    if let group = muscleGroups.first(where: { $0.name == exercise.muscleGroupName }) {
                        path.append(group)
                    }
                    path.append(exercise)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Continue training").font(.caption).foregroundStyle(.secondary)
                            Text(exercise.name).font(.headline).foregroundStyle(.primary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.secondary)
                    }
                    .padding()
                    .themeCard()
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("ContinueTrainingButton")
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Muscle groups").font(.headline)
                    Spacer()
                    Button("Manage") { showingManage = true }
                        .frame(minHeight: 44)
                    Button("Add group", systemImage: "plus") { showingAdd = true }
                        .labelStyle(.iconOnly)
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityIdentifier("AddGroupButton")
                }
                if muscleGroups.isEmpty {
                    EmptyStateView(systemImage: "dumbbell", title: "Create your first group", subtitle: "Organize exercises around how you train.", actionLabel: "Add group", action: { showingAdd = true })
                } else {
                    LazyVGrid(columns: columns, spacing: Theme.itemSpacing) {
                        ForEach(muscleGroups) { group in
                            NavigationLink(value: group) {
                                MuscleGroupCard(group: group, exercises: exercises.filter { $0.muscleGroupName == group.name })
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("Group-\(group.name)")
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingAdd) { AddMuscleGroupSheet() }
        .sheet(isPresented: $showingManage) { ManageMuscleGroupsView() }
    }
}

struct MuscleGroupCard: View {
    let group: MuscleGroup
    let exercises: [Exercise]

    private var lastTrained: String {
        guard let date = exercises.compactMap(\.lastLogDate).max() else { return "Ready when you are" }
        if Calendar.current.isDateInToday(date) { return "Trained today" }
        if Calendar.current.isDateInYesterday(date) { return "Trained yesterday" }
        return "Last: \(date.formatted(.dateTime.month(.abbreviated).day()))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(group.name).font(.headline).foregroundStyle(.primary)
                Spacer(minLength: 4)
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            Text("\(exercises.count) exercise\(exercises.count == 1 ? "" : "s")")
                .font(.subheadline).foregroundStyle(Theme.accent)
            Text(lastTrained).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
        .padding(Theme.cardPadding)
        .themeCard()
        .accessibilityElement(children: .combine)
    }
}

struct ManageMuscleGroupsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MuscleGroup.displayOrder) private var groups: [MuscleGroup]
    @Query private var exercises: [Exercise]
    @State private var editingGroup: MuscleGroup?
    @State private var deletingGroup: MuscleGroup?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(groups) { group in
                        HStack {
                            Text(group.name)
                            Spacer()
                            Button("Rename") { editingGroup = group }
                                .buttonStyle(.borderless)
                        }
                    }
                    .onDelete { offsets in
                        if let index = offsets.first { deletingGroup = groups[index] }
                    }
                    .onMove { source, destination in
                        var ordered = groups
                        ordered.move(fromOffsets: source, toOffset: destination)
                        for (index, group) in ordered.enumerated() { group.displayOrder = index }
                        save()
                    }
                } footer: {
                    Text("Rename a group, or tap Edit to reorder or delete. Deleting a group also deletes its exercises and workout history.")
                }
            }
            .navigationTitle("Manage groups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .sheet(item: $editingGroup) { AddMuscleGroupSheet(group: $0) }
            .alert("Delete group?", isPresented: Binding(get: { deletingGroup != nil }, set: { if !$0 { deletingGroup = nil } })) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) { deleteGroup() }
            } message: {
                Text("Deleting \(deletingGroup?.name ?? "this group") permanently removes its exercises, sets, and saved guide assignments.")
            }
            .alert("Couldn't save changes", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { }
            } message: { Text(errorMessage ?? "Please try again.") }
        }
    }

    private func deleteGroup() {
        guard let group = deletingGroup else { return }
        guard groups.filter({ $0.name == group.name }).count == 1 else {
            errorMessage = "More than one saved group has this name. Deletion was stopped to protect their shared exercise history."
            deletingGroup = nil
            return
        }
        for exercise in exercises where exercise.muscleGroupName == group.name { modelContext.delete(exercise) }
        modelContext.delete(group)
        deletingGroup = nil
        save()
    }

    private func save() {
        do { try modelContext.save() }
        catch {
            modelContext.rollback()
            modelContext.processPendingChanges()
            errorMessage = "Your changes couldn't be saved. Please try again."
        }
    }
}
