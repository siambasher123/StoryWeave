import SwiftUI

struct StoryPlayerView: View {
    let meta: StoryMeta
    @StateObject var vm = StoryPlayerViewModel()
    @EnvironmentObject var session: AppSession

    @State private var showSceneHistory = false

    var body: some View {
        VStack(spacing: 0) {

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.indigo, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                        .animation(.easeInOut(duration: 0.4), value: progress)
                }
            }
            .frame(height: 4)

            if vm.isLoading {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView().scaleEffect(1.2)
                    Text("Loading story...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()

            } else if let error = vm.errorMessage {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Spacer()

            } else if vm.isCompleted {
                Spacer()
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.indigo.opacity(0.1))
                            .frame(width: 100, height: 100)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.indigo)
                    }
                    Text("Story Complete")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("You've reached an ending.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Progress summary
                    HStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text("\(vm.visitedCount)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.indigo)
                            Text("Scenes visited")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Divider().frame(height: 36)
                        VStack(spacing: 4) {
                            Text("\(vm.totalScenes)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.indigo)
                            Text("Total scenes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Button {
                        vm.restart(meta: meta, userId: session.userId ?? "")
                    } label: {
                        Label("Read Again", systemImage: "arrow.counterclockwise")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(Color.indigo)
                            .clipShape(Capsule())
                    }
                }
                .padding(24)
                Spacer()

            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // Scene counter
                        HStack {
                            Text(
                                "Visited \(vm.visitedCount) scene\(vm.visitedCount == 1 ? "" : "s")"
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(progress * 100))% explored")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Scene text card
                        Text(vm.currentScene?.text ?? "")
                            .font(.body)
                            .lineSpacing(6)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 16)

                        // Choices header
                        if let choices = vm.currentScene?.choices, !choices.isEmpty {
                            Text("What do you do?")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.8)
                                .padding(.horizontal, 20)
                                .padding(.top, 4)

                            // Choice buttons
                            VStack(spacing: 10) {
                                ForEach(choices) { choice in
                                    ChoiceButtonView(choice: choice, vm: vm)
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 32)
                    }
                }
            }
        }
        .navigationTitle(meta.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.indigo, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showSceneHistory = true
                } label: {
                    Image(systemName: "list.bullet.clipboard")
                }
                // Only enabled once the player has visited at least one scene
                .disabled(vm.visitedScenes.isEmpty)
            }
        }
        // SceneHistoryView receives isPresented as a @Binding
        .sheet(isPresented: $showSceneHistory) {
            SceneHistoryView(
                isPresented: $showSceneHistory,
                scenes: vm.visitedScenes
            )
        }
        .onAppear {
            vm.load(meta: meta, userId: session.userId ?? "")
        }
    }

    private var progress: Double {
        if vm.isCompleted { return 1.0 }
        guard vm.totalScenes > 0 else { return 0 }
        return min(Double(vm.visitedCount) / Double(vm.totalScenes), 1.0)
    }
}
