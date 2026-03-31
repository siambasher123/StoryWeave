import SwiftUI

/// A sheet that lists every scene the player has visited, in order.
/// Receives `isPresented` as a `@Binding` from `StoryPlayerView`.
struct SceneHistoryView: View {
    @Binding var isPresented: Bool
    let scenes: [StoryScene]

    var body: some View {
        NavigationView {
            List {
                if scenes.isEmpty {
                    Text("No scenes visited yet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(scenes.enumerated()), id: \.offset) { index, scene in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text("\(index + 1)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 22, height: 22)
                                    .background(scene.isEnding ? Color.green : Color.indigo)
                                    .clipShape(Circle())
                                if scene.isEnding {
                                    Label("Ending", systemImage: "flag.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            Text(scene.text)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(4)
                                .lineSpacing(3)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Scenes Visited")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
