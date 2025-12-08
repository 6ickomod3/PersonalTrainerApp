import SwiftUI
import SwiftData

struct ExerciseListView: View {
    let muscleGroup: MuscleGroup
    @Environment(\.modelContext) private var modelContext
    @Query private var allExercises: [Exercise]
    @State private var showingAddExerciseSheet = false
    @State private var isEditingOrder = false
    @Environment(TimerState.self) var timerState
    
    @State private var newlyCreatedExercise: Exercise?
    @State private var isNavigatingToNew = false
    
    @State private var exerciseToRename: Exercise?
    @State private var newName = ""
    
    var exercises: [Exercise] {
        allExercises
            .filter { $0.muscleGroupName == muscleGroup.name }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
    
// Helper computed properties for Dynamic Guides
    var warmups: [MuscleGroupGuide] {
        muscleGroup.guides
            .filter { $0.category == "warmup" }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
    
    var stretches: [MuscleGroupGuide] {
        muscleGroup.guides
            .filter { $0.category == "stretch" } // Note: "stretch" used in seeding for cooldowns
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                warmupSection
                
                mainExercisesSection
                
                cooldownSection
                
                // Spacer for Timer
                Color.clear.frame(height: 100)
            }
            .padding(.top)
        }
        .environment(\.editMode, .constant(isEditingOrder ? .active : .inactive))
        .navigationTitle(muscleGroup.name)
        .navigationDestination(isPresented: $isNavigatingToNew) {
            if let newExercise = newlyCreatedExercise {
                ExerciseDetailView(exercise: newExercise)
                    .environment(timerState)
            }
        }
        .alert("Rename Exercise", isPresented: Binding(
            get: { exerciseToRename != nil },
            set: { if !$0 { exerciseToRename = nil } }
        )) {
            TextField("New Name", text: $newName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if let exercise = exerciseToRename, !newName.trimmingCharacters(in: .whitespaces).isEmpty {
                    exercise.name = newName
                    try? modelContext.save()
                }
            }
        } message: {
            Text("Enter a new name for this exercise.")
        }
        .sheet(isPresented: $showingAddExerciseSheet) {
            AddExerciseSheet(isPresented: $showingAddExerciseSheet, muscleGroupName: muscleGroup.name) { name, min, max, step, percent in
                addExercise(name: name, weightMin: min, weightMax: max, weightStep: step, volumeImprovementPercent: percent)
            }
        }
    }
    
    // Existing helper methods remain...
    private func addExercise(name: String, weightMin: Double, weightMax: Double, weightStep: Double, volumeImprovementPercent: Double) {
        let newExercise = Exercise(name: name, muscleGroupName: muscleGroup.name)
        newExercise.weightMin = weightMin
        newExercise.weightMax = weightMax
        newExercise.weightStep = weightStep
        newExercise.volumeImprovementPercent = volumeImprovementPercent
        newExercise.displayOrder = exercises.count
        
        modelContext.insert(newExercise)
        try? modelContext.save()
        
        newlyCreatedExercise = newExercise
        isEditingOrder = false // Exit edit mode
        isNavigatingToNew = true
    }
    
    // Note: onDelete is handled inline now, moves handled by custom logic or future updates
    
    private func moveExercises(from source: IndexSet, to destination: Int) {
        var updatedExercises = exercises
        updatedExercises.move(fromOffsets: source, toOffset: destination)
        for (index, exercise) in updatedExercises.enumerated() {
            exercise.displayOrder = index
        }
        try? modelContext.save()
    }
    
    // Sub-views to reduce body complexity
    @ViewBuilder
    var warmupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Warm Up", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Spacer()
                // Edit/Manage Button for Warmups
                NavigationLink(destination: ManageGuidesView(muscleGroup: muscleGroup, category: "warmup")) {
                    Text("Manage")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                if warmups.isEmpty {
                    Text("No warm-ups added.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(warmups) { guide in
                        if let item = guide.guideItem {
                            GuideRow(item: item, color: .orange, muscleGroup: muscleGroup.name, section: "warmup")
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    var cooldownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Cool Down", systemImage: "snowflake")
                    .font(.headline)
                    .foregroundStyle(.blue)
                Spacer()
                // Edit/Manage Button for Cooldowns
                NavigationLink(destination: ManageGuidesView(muscleGroup: muscleGroup, category: "stretch")) {
                    Text("Manage")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                if stretches.isEmpty {
                    Text("No cool-downs added.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(stretches) { guide in
                        if let item = guide.guideItem {
                            GuideRow(item: item, color: .blue, muscleGroup: muscleGroup.name, section: "stretch")
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    var mainExercisesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("Exercises", systemImage: "dumbbell.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if isEditingOrder {
                    Button(action: { showingAddExerciseSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                Button(isEditingOrder ? "Done" : "Edit") {
                    withAnimation {
                        isEditingOrder.toggle()
                    }
                }
                .font(.subheadline)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            if exercises.isEmpty {
                Text("No exercises added yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // Custom List-like layout since we are inside a ScrollView
                LazyVStack(spacing: 12) {
                    ForEach(exercises) { exercise in
                        ExerciseRow(
                            exercise: exercise,
                            isEditing: isEditingOrder,
                            onRename: {
                                exerciseToRename = exercise
                                newName = exercise.name
                            },
                            onDelete: {
                                modelContext.delete(exercise)
                                try? modelContext.save()
                            }
                        )
                        .environment(timerState)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// Subcomponents

struct GuideRow: View {
    let item: GuideItem
    let color: Color
    let muscleGroup: String
    let section: String
    @Environment(TimerState.self) var timerState
    
    @State private var isChecked = false
    
    private var storageKey: String {
        "guide_\(muscleGroup)_\(section)_\(item.name)"
    }
    
    var body: some View {

        HStack(spacing: 0) {
            // Main Content - Navigates to Detail
            NavigationLink(destination: GuideDetailView(item: item, color: color).environment(timerState)) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.body.weight(.medium))
                            .foregroundStyle(color)
                        
                        Text(item.duration)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
                .padding()
            }
            .buttonStyle(.plain)
            
            // Toggle Button
            Button(action: toggleState) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isChecked ? .green : .gray.opacity(0.3))
                    .padding(.trailing)
                    .padding(.vertical)
            }
            .buttonStyle(.plain)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear(perform: loadState)
    }
    
    private func loadState() {
        if let lastDate = UserDefaults.standard.object(forKey: storageKey) as? Date {
            isChecked = Calendar.current.isDateInToday(lastDate)
        } else {
            isChecked = false
        }
    }
    
    private func toggleState() {
        let newState = !isChecked
        isChecked = newState
        
        if newState {
            UserDefaults.standard.set(Date(), forKey: storageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: storageKey)
        }
    }
}

struct GuideDetailView: View {
    let item: GuideItem
    let color: Color
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Label(item.name, systemImage: item.icon)
                        .font(.title.bold())
                        .foregroundStyle(color)
                    Spacer()
                }
                .padding(.bottom, 10)
                
                // Duration Tag
                Text("Duration: \(item.duration)")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(color.opacity(0.1))
                    .foregroundStyle(color)
                    .clipShape(Capsule())
                
                Divider()
                
                // Instructions
                Text("Instructions")
                    .font(.headline)
                
                Text(item.instruction)
                    .font(.body)
                    .lineSpacing(4)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Guide")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    let isEditing: Bool
    let onRename: () -> Void
    let onDelete: () -> Void
    @Environment(TimerState.self) var timerState
    
    var body: some View {

        HStack(spacing: 0) {
            if isEditing {
                HStack(spacing: 0) {
                    Button(action: onDelete) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .padding(.leading)
                    .padding(.vertical)
                    
                    Button(action: onRename) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundStyle(.orange)
                    }
                    .padding(.leading, 8)
                    .padding(.vertical)
                }
            }
            
            NavigationLink(destination: ExerciseDetailView(exercise: exercise).environment(timerState)) {
                HStack {
                    Text(exercise.name)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .padding()
            }
            .buttonStyle(.plain)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        ExerciseListView(muscleGroup: MuscleGroup(name: "Chest"))
    }
}

import SwiftUI
import SwiftData

struct ManageGuidesView: View {
    @Environment(\.modelContext) private var modelContext
    let muscleGroup: MuscleGroup
    let category: String // "warmup" or "stretch"
    
    @State private var showingPoolSheet = false
    
    // Fetch guides belonging to this muscle group and category, sorted by order
    // Since we can't easy dynamic predicate on @Query, we'll sort in memory or rely on the relationship array
    // The relationship array `muscleGroup.guides` IS the source of truth.
    
    // We want a list we can move/delete.
    // Accessing `muscleGroup.guides` directly.
    
    var currentGuides: [MuscleGroupGuide] {
        muscleGroup.guides
            .filter { $0.category == category }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
    
    var body: some View {
        List {
            ForEach(currentGuides) { relation in
                if let item = relation.guideItem {
                    HStack {
                        Image(systemName: item.icon)
                            .foregroundStyle(category == "warmup" ? .orange : .blue)
                            .frame(width: 30)
                        Text(item.name)
                        Spacer()
                        Text(item.duration)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
            .onMove(perform: moveGuides)
            .onDelete(perform: deleteGuides)
        }
        .navigationTitle("Manage \(category == "warmup" ? "Warm Ups" : "Cool Downs")")
        .environment(\.editMode, .constant(.active)) // Always in edit mode for ease
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingPoolSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingPoolSheet) {
            GuidePoolSheet(muscleGroup: muscleGroup, category: category, isPresented: $showingPoolSheet)
        }
    }
    
    private func moveGuides(from source: IndexSet, to destination: Int) {
        var guides = currentGuides
        guides.move(fromOffsets: source, toOffset: destination)
        
        // Update display orders
        for (index, guide) in guides.enumerated() {
            guide.displayOrder = index
        }
        
        try? modelContext.save()
    }
    
    private func deleteGuides(at offsets: IndexSet) {
        let guidesToDelete = offsets.map { currentGuides[$0] }
        for guide in guidesToDelete {
            // Remove from relationship
            if let index = muscleGroup.guides.firstIndex(where: { $0.id == guide.id }) {
                muscleGroup.guides.remove(at: index)
            }
            // Delete the join entity
            modelContext.delete(guide)
        }
        try? modelContext.save()
    }
}

struct GuidePoolSheet: View {
    @Environment(\.modelContext) private var modelContext
    let muscleGroup: MuscleGroup
    let category: String
    @Binding var isPresented: Bool
    
    // We want all guides that are correct type ("warmup" or "cooldown")
    // Note: "stretch" category in MuscleGroupGuide maps to "cooldown" type in GuideItem usually.
    // See seeding logic: type: "cooldown", category: "stretch".
    
    var descriptorType: String {
        category == "warmup" ? "warmup" : "cooldown"
    }
    
    @Query(sort: \GuideItem.name) var allGuides: [GuideItem]
    
    // Filtered list
    var availableGuides: [GuideItem] {
        allGuides.filter { $0.type == descriptorType }
    }
    
    @State private var showingCreateForm = false
    @State private var newItemName = ""
    @State private var newItemDuration = ""
    @State private var newItemInstruction = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Create New")) {
                    DisclosureGroup("Create Custom \(descriptorType == "warmup" ? "Warm Up" : "Cool Down")", isExpanded: $showingCreateForm) {
                        VStack(spacing: 12) {
                            TextField("Name", text: $newItemName)
                            TextField("Duration (e.g. 30s)", text: $newItemDuration)
                            TextField("Instruction", text: $newItemInstruction, axis: .vertical)
                            
                            Button("Add & Select") {
                                createAndAdd()
                            }
                            .disabled(newItemName.isEmpty)
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section(header: Text("Select from Pool")) {
                    ForEach(availableGuides) { item in
                        Button(action: {
                            addToMuscleGroup(item)
                        }) {
                            HStack {
                                Image(systemName: item.icon)
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .foregroundStyle(.primary)
                                    Text(item.instruction)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                // Show checkmark if already added?
                                if isAlreadyAdded(item) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .disabled(isAlreadyAdded(item))
                    }
                }
            }
            .navigationTitle("Add to \(muscleGroup.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }
    
    private func isAlreadyAdded(_ item: GuideItem) -> Bool {
        muscleGroup.guides.contains { $0.guideItem?.id == item.id && $0.category == category }
    }
    
    private func addToMuscleGroup(_ item: GuideItem) {
        // Find max order
        let currentMax = muscleGroup.guides
            .filter { $0.category == category }
            .map { $0.displayOrder }
            .max() ?? -1
        
        let newRelation = MuscleGroupGuide(displayOrder: currentMax + 1, category: category, guideItem: item)
        muscleGroup.guides.append(newRelation)
        // modelContext.insert(newRelation) // relationship append implies insert, but usually safer to insert
        try? modelContext.save()
        isPresented = false
    }
    
    private func createAndAdd() {
        let newItem = GuideItem(
            name: newItemName,
            type: descriptorType,
            duration: newItemDuration.isEmpty ? "1 min" : newItemDuration,
            instruction: newItemInstruction.isEmpty ? "Follow instructions." : newItemInstruction,
            icon: descriptorType == "warmup" ? "flame" : "snowflake",
            isCustom: true
        )
        modelContext.insert(newItem)
        addToMuscleGroup(newItem)
    }
}
