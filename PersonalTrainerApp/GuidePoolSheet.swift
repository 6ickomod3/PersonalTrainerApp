import SwiftUI
import SwiftData

/// Sheet for selecting or creating guide items (warm-up / cool-down) from a pool
struct GuidePoolSheet: View {
    @Environment(\.modelContext) private var modelContext
    let muscleGroup: MuscleGroup
    let category: GuideCategory
    @Binding var isPresented: Bool
    
    var descriptorType: GuideType {
        category == .warmup ? .warmup : .cooldown
    }
    
    @Query(sort: \GuideItem.name) var allGuides: [GuideItem]
    
    var availableGuides: [GuideItem] {
        allGuides.filter { $0.type == descriptorType.rawValue }
    }
    
    @State private var showingCreateForm = false
    @State private var newItemName = ""
    @State private var newItemDuration = ""
    @State private var newItemInstruction = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Create New")) {
                    DisclosureGroup("Create Custom \(descriptorType == .warmup ? "Warm Up" : "Cool Down")", isExpanded: $showingCreateForm) {
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
                                        .foregroundStyle(Theme.success)
                                } else {
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(Theme.primaryAction)
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
        muscleGroup.guides.contains { $0.guideItem?.id == item.id && $0.category == category.rawValue }
    }
    
    private func addToMuscleGroup(_ item: GuideItem) {
        let currentMax = muscleGroup.guides
            .filter { $0.category == category.rawValue }
            .map { $0.displayOrder }
            .max() ?? -1
        
        let newRelation = MuscleGroupGuide(displayOrder: currentMax + 1, category: category, guideItem: item)
        muscleGroup.guides.append(newRelation)
        modelContext.safeSave()
        isPresented = false
    }
    
    private func createAndAdd() {
        let newItem = GuideItem(
            name: newItemName,
            type: descriptorType,
            duration: newItemDuration.isEmpty ? "1 min" : newItemDuration,
            instruction: newItemInstruction.isEmpty ? "Follow instructions." : newItemInstruction,
            icon: descriptorType == .warmup ? "flame" : "snowflake",
            isCustom: true
        )
        modelContext.insert(newItem)
        addToMuscleGroup(newItem)
    }
}
