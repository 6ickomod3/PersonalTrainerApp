import SwiftUI

/// Detail view for a guide item showing full instructions
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
