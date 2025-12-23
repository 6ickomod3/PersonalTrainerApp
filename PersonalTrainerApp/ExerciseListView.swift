import SwiftUI
import SwiftData

struct ExerciseListView: View {
    let muscleGroup: MuscleGroup
    @Environment(\.modelContext) private var modelContext
    @Query private var allExercises: [Exercise]
    
    // Sheets
    @State private var showingAddExerciseSheet = false
    @State private var showingPoolSheet = false
    @State private var poolCategory = "warmup" // "warmup" or "stretch"(cooldown)
    
    @Environment(TimerState.self) var timerState
    
    @State private var newlyCreatedExercise: Exercise?
    @State private var isNavigatingToNew = false
    
    @State private var exerciseToRename: Exercise?
    @State private var newName = ""
    
    // Confirmations
    @State private var exerciseToDelete: Exercise?
    @State private var guideToDelete: MuscleGroupGuide?
    
    // Feature: Limit visible exercises
    @State private var isExpanded = false
    let previewLimit = 5
    
    // Edit Mode
    
    var exercises: [Exercise] {
        allExercises
            .filter { $0.muscleGroupName == muscleGroup.name }
            .sorted { e1, e2 in
                // Dynamic Sort: Latest logged first
                if let d1 = e1.lastLogDate, let d2 = e2.lastLogDate {
                    return d1 > d2
                }
                if e1.lastLogDate != nil { return true }
                if e2.lastLogDate != nil { return false }
                
                return e1.displayOrder < e2.displayOrder
            }
    }
    
    var visibleExercises: [Exercise] {
        if isExpanded {
            return exercises
        } else {
            return Array(exercises.prefix(previewLimit))
        }
    }
    
    var warmups: [MuscleGroupGuide] {
        muscleGroup.guides
            .filter { $0.category == "warmup" }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
    
    var stretches: [MuscleGroupGuide] {
        muscleGroup.guides
            .filter { $0.category == "stretch" }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    var body: some View {
        List {
            warmupSection
            exercisesSection
            coolDownSection
            
            // Spacer for Timer
            Color.clear.frame(height: 80).listRowBackground(Color.clear)
        }
        .listStyle(.insetGrouped)
        .navigationTitle(muscleGroup.name)
        .toolbar {
             // Toolbar items if any
        }
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
                    exercise.name = newName.capitalized
                    try? modelContext.save()
                }
            }
        } message: {
            Text("Enter a new name for this exercise.")
        }
        // Delete Confirmation: Exercise
        .alert("Delete Exercise?", isPresented: Binding(
            get: { exerciseToDelete != nil },
            set: { if !$0 { exerciseToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let exercise = exerciseToDelete {
                    confirmDeleteExercise(exercise)
                }
            }
        } message: {
             if let exercise = exerciseToDelete {
                 Text("Are you sure you want to delete '\(exercise.name)'? This works cannot be undone.")
             }
        }
        // Delete Confirmation: Guide
        .alert("Delete Item?", isPresented: Binding(
            get: { guideToDelete != nil },
            set: { if !$0 { guideToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let guide = guideToDelete {
                    confirmDeleteGuide(guide)
                }
            }
        } message: {
             if let guide = guideToDelete, let item = guide.guideItem {
                 Text("Are you sure you want to remove '\(item.name)'?")
             }
        }
        .sheet(isPresented: $showingAddExerciseSheet) {
            AddExerciseSheet(isPresented: $showingAddExerciseSheet, muscleGroupName: muscleGroup.name) { name, min, max, step, percent in
                addExercise(name: name, weightMin: min, weightMax: max, weightStep: step, volumeImprovementPercent: percent)
            }
        }
        .sheet(isPresented: $showingPoolSheet) {
            GuidePoolSheet(muscleGroup: muscleGroup, category: poolCategory, isPresented: $showingPoolSheet)
        }
    }
    
    // MARK: - View Subdivisions
    
    @ViewBuilder
    private var warmupSection: some View {
        Section {
            if warmups.isEmpty {
                Text("No warm-ups added.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(warmups) { guide in
                    if let item = guide.guideItem {
                        GuideRow(item: item, color: .orange, muscleGroup: muscleGroup.name, section: "warmup")
                            .contextMenu {
                                Button(role: .destructive) {
                                    guideToDelete = guide
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .onMove(perform: moveWarmups)
                .onDelete(perform: promptDeleteWarmups)
            }
        } header: {
            HStack {
                Label("Warm Up", systemImage: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.headline)
                    .textCase(nil)
                Spacer()
                Button(action: {
                    poolCategory = "warmup"
                    showingPoolSheet = true
                }) {
                    Image(systemName: "plus")
                        .foregroundStyle(.orange)
                }
            }
        }
        .listRowSeparator(.hidden)
    }
    
    @ViewBuilder
    private var exercisesSection: some View {
        Section {
            if exercises.isEmpty {
                Text("No exercises added yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(visibleExercises) { exercise in
                    ExerciseRow(
                        exercise: exercise,
                        onRename: {
                            exerciseToRename = exercise
                            newName = exercise.name
                        },
                        onDelete: {
                            exerciseToDelete = exercise
                        }
                    )
                    .contextMenu {
                        Button {
                            exerciseToRename = exercise
                            newName = exercise.name
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            exerciseToDelete = exercise
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .environment(timerState)
                }
                .onDelete(perform: promptDeleteExercises)
                
                if exercises.count > previewLimit {
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Text(isExpanded ? "Show Less" : "Show All (\(exercises.count - previewLimit) more)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            HStack {
                Label("Exercises", systemImage: "dumbbell.fill")
                    .foregroundStyle(.red)
                    .font(.headline)
                    .textCase(nil)
                Spacer()
                Button(action: { showingAddExerciseSheet = true }) {
                    Image(systemName: "plus")
                        .foregroundStyle(.red)
                }
            }
        }
        .listRowSeparator(.hidden)
    }
    
    @ViewBuilder
    private var coolDownSection: some View {
        Section {
            if stretches.isEmpty {
                Text("No cool-downs added.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(stretches) { guide in
                    if let item = guide.guideItem {
                        GuideRow(item: item, color: .blue, muscleGroup: muscleGroup.name, section: "stretch")
                            .contextMenu {
                                Button(role: .destructive) {
                                    guideToDelete = guide
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .onMove(perform: moveStretches)
                .onDelete(perform: promptDeleteStretches)
            }
        } header: {
            HStack {
                Label("Cool Down", systemImage: "snowflake")
                    .foregroundStyle(.blue)
                    .font(.headline)
                    .textCase(nil)
                Spacer()
                Button(action: {
                    poolCategory = "stretch" // seeded as mapped to cooldown
                    showingPoolSheet = true
                }) {
                    Image(systemName: "plus")
                        .foregroundStyle(.blue)
                }
            }
        }
        .listRowSeparator(.hidden)
    }
    
    // CRUD Logic
    
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
        isNavigatingToNew = true
    }
    
    // Prompt helpers for Swipe Actions
    
    private func promptDeleteExercises(at offsets: IndexSet) {
        // Just take the first one for simplicity in this interaction
        if let firstIndex = offsets.first {
             exerciseToDelete = visibleExercises[firstIndex]
        }
    }
    
    private func confirmDeleteExercise(_ exercise: Exercise) {
        modelContext.delete(exercise)
        try? modelContext.save()
        exerciseToDelete = nil
    }

    // Guide Management Helper
    
    // Helper to get raw array for moving
    func getGuides(category: String) -> [MuscleGroupGuide] {
        muscleGroup.guides
            .filter { $0.category == category }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
    
    private func moveWarmups(from source: IndexSet, to destination: Int) {
        moveGuide(category: "warmup", from: source, to: destination)
    }
    
    private func promptDeleteWarmups(at offsets: IndexSet) {
        let guides = getGuides(category: "warmup")
        if let index = offsets.first {
            guideToDelete = guides[index]
        }
    }
    
    private func moveStretches(from source: IndexSet, to destination: Int) {
        moveGuide(category: "stretch", from: source, to: destination)
    }
    
    private func promptDeleteStretches(at offsets: IndexSet) {
        let guides = getGuides(category: "stretch")
        if let index = offsets.first {
            guideToDelete = guides[index]
        }
    }
    
    private func confirmDeleteGuide(_ guide: MuscleGroupGuide) {
        if let index = muscleGroup.guides.firstIndex(of: guide) {
            muscleGroup.guides.remove(at: index)
        }
        modelContext.delete(guide)
        try? modelContext.save()
        guideToDelete = nil
    }
    
    private func moveGuide(category: String, from source: IndexSet, to destination: Int) {
        var guides = getGuides(category: category)
        guides.move(fromOffsets: source, toOffset: destination)
        
        for (index, guide) in guides.enumerated() {
            guide.displayOrder = index
        }
        try? modelContext.save()
    }
    
    // Deprecated direct delete helpers (replaced by confirmDeleteGuide)
    /*
    private func deleteGuide(category: String, at offsets: IndexSet) {
        let guides = getGuides(category: category)
        let toDelete = offsets.map { guides[$0] }
        
        for guide in toDelete {
            if let index = muscleGroup.guides.firstIndex(of: guide) {
                muscleGroup.guides.remove(at: index)
            }
            modelContext.delete(guide)
        }
        try? modelContext.save()
    }
    */
}

// Reuse Subcomponents (GuideRow, ExerciseRow) - but simplified for List usage
// GridRow handles navigation link internally, works fine in List mostly, but might have double selection effect
// Native List uses NavigationLink implicitly if present.

// Refined GuideRow for List
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
        HStack {
            // Check Circle
            Button(action: toggleState) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isChecked ? .green : .gray.opacity(0.3))
            }
            .buttonStyle(.plain)
            
            // Content
            NavigationLink(destination: GuideDetailView(item: item, color: color).environment(timerState)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(color)
                    
                    Text(item.duration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
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

// Refined ExerciseRow for List
struct ExerciseRow: View {
    let exercise: Exercise
    let onRename: () -> Void
    let onDelete: () -> Void
    @Environment(TimerState.self) var timerState
    
    var body: some View {
        NavigationLink(destination: ExerciseDetailView(exercise: exercise).environment(timerState)) {
            HStack {
                // Leading Status Icon (Read-only)
                // Matches GuideRow indentation
                Image(systemName: isLoggedToday ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isLoggedToday ? .green : .gray.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.red)
                    
                    // Subtitle: Suggested Volume to match height
                    Group {
                         if let suggested = exercise.suggestedVolume {
                             Text("Target Volume: \(Int(suggested)) lbs")
                         } else {
                             Text("Start logging to see targets")
                         }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    private var isLoggedToday: Bool {
        guard let lastDate = exercise.lastLogDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }
}

// Keep GuideDetailView, ManageGuidesView (can be deprecated or kept as fallback), GuidePoolSheet
// GuidePoolSheet needs to be available here since we call it directly now.

struct GuidePoolSheet: View {
    @Environment(\.modelContext) private var modelContext
    let muscleGroup: MuscleGroup
    let category: String
    @Binding var isPresented: Bool
    
    var descriptorType: String {
        category == "warmup" ? "warmup" : "cooldown"
    }
    
    @Query(sort: \GuideItem.name) var allGuides: [GuideItem]
    
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
        let currentMax = muscleGroup.guides
            .filter { $0.category == category }
            .map { $0.displayOrder }
            .max() ?? -1
        
        let newRelation = MuscleGroupGuide(displayOrder: currentMax + 1, category: category, guideItem: item)
        muscleGroup.guides.append(newRelation)
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
