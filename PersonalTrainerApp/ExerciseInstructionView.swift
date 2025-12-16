import SwiftUI

struct ExerciseInstructionView: View {
    @Bindable var exercise: Exercise
    @State private var videoURLText: String = ""
    @State private var isEditingURL = false
    
    // Focus State for instructions
    @FocusState private var focusedInstructionIndex: Int?
    
    var videoID: String? {
        guard let url = exercise.videoUrl, !url.isEmpty else { return nil }
        return extractYouTubeID(from: url)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Video Section
                if let videoID = videoID {
                    YouTubeView(videoID: videoID)
                        .frame(height: 220)
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(height: 220)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "video.slash")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                                Text("No video available")
                                    .foregroundStyle(.secondary)
                            }
                        )
                }
                
                // URL Input (only visible when editing or if empty)
                if isEditingURL || exercise.videoUrl == nil || exercise.videoUrl?.isEmpty == true {
                    HStack {
                        TextField("YouTube URL", text: $videoURLText)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        
                        Button("Save") {
                            let trimmed = videoURLText.trimmingCharacters(in: .whitespacesAndNewlines)
                            exercise.videoUrl = trimmed
                            isEditingURL = false
                        }
                        .disabled(videoURLText.isEmpty)
                    }
                }
                
                if !isEditingURL && exercise.videoUrl != nil && exercise.videoUrl?.isEmpty == false {
                    Button("Edit Video URL") {
                        videoURLText = exercise.videoUrl ?? ""
                        isEditingURL = true
                    }
                    .font(.caption)
                }
                
                // Title
                Text(exercise.name)
                    .font(.title)
                    .bold()
                
                // Instructions List
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Instructions")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            // Add new empty instruction and focus it
                            exercise.instructions.append("")
                            focusedInstructionIndex = exercise.instructions.count - 1
                        }) {
                            Label("Add", systemImage: "plus.circle")
                                .font(.subheadline)
                        }
                    }
                    
                    if exercise.instructions.isEmpty {
                        Text("No instructions added yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1).")
                                    .font(.body.bold())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20, alignment: .trailing)
                                
                                TextField("Enter instruction...", text: Binding(
                                    get: {
                                        guard index < exercise.instructions.count else { return "" }
                                        return exercise.instructions[index]
                                    },
                                    set: { newValue in
                                        if index < exercise.instructions.count {
                                            exercise.instructions[index] = newValue
                                        }
                                    }
                                ), axis: .vertical)
                                .font(.body)
                                .focused($focusedInstructionIndex, equals: index)
                                .submitLabel(.done)
                                
                                Button(action: {
                                    if index < exercise.instructions.count {
                                        exercise.instructions.remove(at: index)
                                        // Reset focus if needed
                                        focusedInstructionIndex = nil
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red.opacity(0.6))
                                        .font(.caption)
                                }
                                .buttonStyle(.borderless)
                                .padding(.top, 4)
                            }
                            .padding(.vertical, 4)
                            .id(index) // Important for scrolling if we added that logic
                            
                            Divider()
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Instructions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if focusedInstructionIndex != nil {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            focusedInstructionIndex = nil
                        }
                    }
                }
            }
        }
        .onAppear {
            if let url = exercise.videoUrl {
                videoURLText = url
            }
        }
    }
    
    func extractYouTubeID(from url: String) -> String? {
        // Simple regex or string manipulation for extracting ID
        // Supports: youtube.com/watch?v=ID, youtu.be/ID, youtube.com/embed/ID, youtube.com/shorts/ID
        let pattern = #"(?<=v=|v\/|vi=|vi\/|youtu.be\/|embed\/|shorts\/)([a-zA-Z0-9_-]{11})"#
        
        if let range = url.range(of: pattern, options: .regularExpression) {
            return String(url[range])
        }
        return nil
    }
}

#Preview {
    NavigationStack {
        ExerciseInstructionView(exercise: Exercise.sampleExercises[0])
    }
}
