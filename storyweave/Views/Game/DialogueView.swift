import SwiftUI

struct DialogueView: View {
    @ObservedObject var viewModel: GameViewModel
    let scene: GameScene

    @State private var displayedText: String = ""
    @State private var isTyping = false
    @State private var typingTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(spacing: swSpacing * 3) {
                speakerSection
                speechBubble
                choiceButtons
                PartyStatusBar(party: viewModel.party)
            }
            .padding(swSpacing * 2)
        }
        .onChange(of: viewModel.narration) { _, newValue in
            startTypewriter(text: newValue)
        }
        .onAppear {
            if !viewModel.narration.isEmpty {
                startTypewriter(text: viewModel.narration)
            }
        }
        .onDisappear { typingTask?.cancel() }
    }

    // MARK: — Speaker portrait

    private var speakerSection: some View {
        HStack(spacing: swSpacing * 2) {
            portraitCircle
            VStack(alignment: .leading, spacing: 2) {
                Text(scene.npcName ?? "Stranger")
                    .font(.swHeadline)
                    .foregroundStyle(Color.swAccentLight)
                Text("Speaking")
                    .font(.swCaption)
                    .foregroundStyle(Color.swTextSecondary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(scene.npcName ?? "Stranger") is speaking")
    }

    private var portraitCircle: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.swAccentDeep, Color.swAccentMuted],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .overlay(
                    Circle().stroke(Color.swAccentPrimary, lineWidth: 2)
                )
            Text(String((scene.npcName ?? "?").prefix(1)).uppercased())
                .font(.swTitle)
                .foregroundStyle(Color.swAccentLight)
        }
    }

    // MARK: — Speech bubble

    private var speechBubble: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tail
            HStack {
                Triangle()
                    .fill(Color.swSurface)
                    .frame(width: 20, height: 12)
                    .padding(.leading, 30)
                Spacer()
            }
            // Bubble body
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.swSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.swAccentDeep, lineWidth: 1)
                    )
                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.isLoadingNarration ? "..." : (displayedText.isEmpty ? scene.narrationSeed : displayedText))
                        .font(.swBody)
                        .foregroundStyle(Color.swTextPrimary)
                        .padding(swSpacing * 2)
                        .fixedSize(horizontal: false, vertical: true)

                    if viewModel.isLoadingNarration {
                        ProgressView()
                            .tint(Color.swAccentPrimary)
                            .padding(.horizontal, swSpacing * 2)
                            .padding(.bottom, swSpacing)
                    }
                }
            }
        }
        .accessibilityLabel(displayedText.isEmpty ? scene.narrationSeed : displayedText)
    }

    // MARK: — Choices

    private var choiceButtons: some View {
        VStack(spacing: swSpacing) {
            ForEach(scene.choices) { choice in
                SWButton(title: choice.label, style: .primary) {
                    Task { await viewModel.makeChoice(choice) }
                }
                .accessibilityLabel(choice.label)
            }
        }
    }

    // MARK: — Typewriter

    private func startTypewriter(text: String) {
        typingTask?.cancel()
        displayedText = ""
        guard !text.isEmpty else { return }
        isTyping = true
        typingTask = Task {
            for char in text {
                guard !Task.isCancelled else { break }
                displayedText.append(char)
                try? await Task.sleep(for: .milliseconds(18))
            }
            isTyping = false
        }
    }
}

// Upward-pointing triangle for the speech bubble tail
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
