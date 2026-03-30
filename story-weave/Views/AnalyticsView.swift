import SwiftUI

struct AnalyticsView: View {
    @StateObject var vm = ProfileViewModel()
    @EnvironmentObject var session: AppSession

    var body: some View {
        List {
            Section {
                Text("Analytics")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundColor(.primary)
                    .padding(.top, 4)
                    .padding(.bottom, 2)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
            }

            if vm.isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding(.vertical, 24)
                }

            } else if vm.sessions.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No data yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Start reading a story to see your analytics here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .listRowBackground(Color.clear)
                }

            } else {
                Section("Overview") {
                    StatRow(
                        icon: "book.fill", color: .indigo,
                        label: "Stories Started", value: "\(vm.storiesStarted)")
                    StatRow(
                        icon: "checkmark.seal.fill", color: .green,
                        label: "Stories Completed", value: "\(vm.storiesCompleted)")
                    StatRow(
                        icon: "chart.bar.fill", color: .orange,
                        label: "Completion Rate", value: completionRate)
                }

                Section("Story Breakdowns") {
                    ForEach(vm.sessions, id: \.storyId) { storySession in
                        AnalyticsRowView(
                            storySession: storySession,
                            title: vm.titleForSession(storySession)
                        )
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { i in
                            let s = vm.sessions[i]
                            vm.deleteSession(userId: session.userId ?? "", storyId: s.storyId)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            vm.loadSessions(userId: session.userId ?? "")
        }
    }

    private var completionRate: String {
        guard vm.storiesStarted > 0 else { return "0%" }
        let rate = Int((Double(vm.storiesCompleted) / Double(vm.storiesStarted)) * 100)
        return "\(rate)%"
    }
}

// MARK: - Per-story breakdown row

struct AnalyticsRowView: View {
    let storySession: StorySession
    let title: String

    private var progress: Double {
        if storySession.isCompleted { return 1.0 }
        guard let total = storySession.totalScenes, total > 0 else { return 0 }
        return min(Double(storySession.visitedSceneIds.count) / Double(total), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                if storySession.isCompleted {
                    Label("Completed", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("In Progress")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }

            ProgressView(value: progress)
                .tint(storySession.isCompleted ? .green : .indigo)

            HStack {
                Text(
                    "\(storySession.visitedSceneIds.count) scene\(storySession.visitedSceneIds.count == 1 ? "" : "s") visited"
                )
                .font(.caption)
                .foregroundColor(.secondary)

                Spacer()

                if let total = storySession.totalScenes {
                    Text("of \(total) total · ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("\(Int(progress * 100))% explored")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}
