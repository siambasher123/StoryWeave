import SwiftUI

struct StoryCardView: View {
    let meta: StoryMeta
    @ObservedObject var vm: StoryLibraryViewModel

    private var hasSession: Bool { vm.hasSession(for: meta) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Category badge
            Text(meta.category.uppercased())
                .font(.caption2)
                .fontWeight(.bold)
                .tracking(1.2)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(categoryColor(meta.category).opacity(0.15))
                .foregroundColor(categoryColor(meta.category))
                .clipShape(Capsule())

            // Title
            Text(meta.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(2)

            // Description
            Text(meta.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .lineSpacing(3)

            // Footer — Resume or Start Reading
            HStack {
                Image(systemName: hasSession ? "play.fill" : "arrow.right.circle.fill")
                    .foregroundColor(.indigo)
                Text(hasSession ? "Resume" : "Start Reading")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.indigo)
                Spacer()
                if hasSession {
                    Text("In Progress")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.indigo.opacity(0.1))
                        .foregroundColor(.indigo)
                        .clipShape(Capsule())
                }
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 4)
    }

    private func categoryColor(_ category: String) -> Color {
        let colors: [Color] = [.indigo, .purple, .teal, .orange, .pink, .cyan, .mint, .brown]
        let hash = category.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return colors[hash % colors.count]
    }
}
