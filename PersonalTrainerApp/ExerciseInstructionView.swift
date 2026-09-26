import SwiftUI
import SwiftData

struct ExerciseInstructionView: View {
    let exercise: Exercise
    @State private var isEditing = false

    var body: some View {
        List {
            if let url = exercise.videoUrl, let videoID = extractYouTubeID(from: url) {
                Section("Video") {
                    YouTubeView(videoID: videoID)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.innerRadius))
                }
            }
            Section("Instructions") {
                if exercise.instructions.isEmpty {
                    Text("Add your setup and technique notes for this exercise.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1).")
                                .foregroundStyle(.secondary)
                            Text(instruction)
                        }
                    }
                }
            }
        }
        .navigationTitle("Instructions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Button("Edit") { isEditing = true } }
        .sheet(isPresented: $isEditing) { ExerciseInstructionEditor(exercise: exercise) }
    }

    func extractYouTubeID(from url: String) -> String? {
        youtubeVideoID(from: url)
    }
}

private func youtubeVideoID(from value: String) -> String? {
    guard let components = URLComponents(string: value),
          ["https", "http"].contains(components.scheme?.lowercased() ?? ""),
          let host = components.host?.lowercased() else { return nil }
    let candidate: String?
    if host == "youtu.be" || host == "www.youtu.be" {
        candidate = components.path.split(separator: "/").first.map(String.init)
    } else if ["youtube.com", "www.youtube.com", "m.youtube.com"].contains(host) {
        if let id = components.queryItems?.first(where: { $0.name == "v" })?.value {
            candidate = id
        } else {
            let path = components.path.split(separator: "/")
            candidate = path.count == 2 && ["embed", "shorts", "live"].contains(String(path[0])) ? String(path[1]) : nil
        }
    } else {
        candidate = nil
    }
    guard let candidate, candidate.range(of: #"^[a-zA-Z0-9_-]{11}$"#, options: .regularExpression) != nil else { return nil }
    return candidate
}

private struct ExerciseInstructionEditor: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var videoURL: String
    @State private var instructions: [String]
    @State private var errorMessage: String?

    init(exercise: Exercise) {
        self.exercise = exercise
        _videoURL = State(initialValue: exercise.videoUrl ?? "")
        _instructions = State(initialValue: exercise.instructions)
    }

    private var trimmedURL: String { videoURL.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var invalidURL: Bool {
        !trimmedURL.isEmpty && youtubeVideoID(from: trimmedURL) == nil && trimmedURL != exercise.videoUrl
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Video (optional)") {
                    TextField("YouTube URL", text: $videoURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if invalidURL { Text("Enter a valid YouTube video link or leave this empty.").font(.caption).foregroundStyle(.red) }
                }
                Section("Instructions") {
                    ForEach(instructions.indices, id: \.self) { index in
                        TextField("Instruction \(index + 1)", text: $instructions[index], axis: .vertical)
                    }
                    .onDelete { instructions.remove(atOffsets: $0) }
                    Button("Add Instruction", systemImage: "plus") { instructions.append("") }
                }
                if let errorMessage { Section { Text(errorMessage).foregroundStyle(.red) } }
            }
            .navigationTitle("Edit Instructions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(invalidURL)
                }
            }
        }
    }

    private func save() {
        exercise.videoUrl = trimmedURL.isEmpty ? nil : trimmedURL
        exercise.instructions = instructions.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        exercise.lastModifiedDate = Date()
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            modelContext.processPendingChanges()
            errorMessage = "Your instructions could not be saved. Please try again."
        }
    }
}
