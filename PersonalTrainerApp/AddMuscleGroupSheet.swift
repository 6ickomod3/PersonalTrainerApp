import SwiftUI
import SwiftData

struct AddMuscleGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var groups: [MuscleGroup]
    @Query private var exercises: [Exercise]
    let group: MuscleGroup?
    @State private var name: String
    @State private var errorMessage: String?

    init(group: MuscleGroup? = nil) {
        self.group = group
        _name = State(initialValue: group?.name ?? "")
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var validationMessage: String? {
        if trimmedName.isEmpty { return "Enter a group name." }
        if groups.contains(where: { $0.id != group?.id && $0.name.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare(trimmedName) == .orderedSame }) {
            return "A group with this name already exists."
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Group name") {
                    TextField("For example, Core", text: $name)
                        .accessibilityIdentifier("GroupNameField")
                    if !name.isEmpty, let message = validationMessage {
                        Text(message).font(.footnote).foregroundStyle(.red)
                    }
                }
                if let errorMessage { Section { Text(errorMessage).foregroundStyle(.red) } }
            }
            .navigationTitle(group == nil ? "Add group" : "Rename group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(validationMessage != nil)
                        .accessibilityIdentifier("SaveGroupButton")
                }
            }
        }
    }

    private func save() {
        guard validationMessage == nil else { return }
        var copiedPreferences: [(String, Date)] = []
        var insertedGroup: MuscleGroup?
        if let group {
            let oldName = group.name
            guard groups.filter({ $0.name == oldName }).count == 1 else {
                errorMessage = "This saved name belongs to multiple groups. Renaming was stopped to protect their exercise history."
                return
            }
            for exercise in exercises where exercise.muscleGroupName == oldName {
                exercise.muscleGroupName = trimmedName
            }
            // Preserve the old keys too, until the retired guide feature is redesigned.
            for link in group.guides {
                guard let item = link.guideItem else { continue }
                let oldKey = "guide_\(oldName)_\(link.category)_\(item.name)"
                if let value = UserDefaults.standard.object(forKey: oldKey) as? Date {
                    copiedPreferences.append(("guide_\(trimmedName)_\(link.category)_\(item.name)", value))
                }
            }
            group.name = trimmedName
        } else {
            let newGroup = MuscleGroup(name: trimmedName)
            newGroup.displayOrder = (groups.map(\.displayOrder).max() ?? -1) + 1
            modelContext.insert(newGroup)
            insertedGroup = newGroup
        }
        do {
            try modelContext.save()
            for (key, value) in copiedPreferences { UserDefaults.standard.set(value, forKey: key) }
            dismiss()
        } catch {
            if let insertedGroup { modelContext.delete(insertedGroup) }
            modelContext.rollback()
            if insertedGroup != nil {
                var descriptor = FetchDescriptor<MuscleGroup>()
                descriptor.includePendingChanges = false
                _ = try? modelContext.fetch(descriptor)
            }
            modelContext.processPendingChanges()
            errorMessage = "Couldn't save this group. Please try again."
        }
    }
}
