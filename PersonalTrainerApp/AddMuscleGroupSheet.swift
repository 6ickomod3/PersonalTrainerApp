import SwiftUI

struct AddMuscleGroupSheet: View {
    @Binding var isPresented: Bool
    var onAdd: (String) -> Void
    
    @State private var groupName = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Muscle Group Name", text: $groupName)
            }
            .navigationTitle("Add Muscle Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        if !groupName.trimmingCharacters(in: .whitespaces).isEmpty {
                            onAdd(groupName.capitalized)
                            isPresented = false
                        }
                    }
                    .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
