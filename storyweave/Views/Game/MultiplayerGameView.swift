import SwiftUI

struct MultiplayerGameView: View {
    @ObservedObject var mpVM: MultiplayerViewModel

    var body: some View {
        ZStack {
            if let scene = mpVM.localGameVM.currentScene {
                SceneView(viewModel: mpVM.localGameVM, scene: scene)
                    .disabled(!mpVM.isMyTurn)
            }

            turnBanner

            if !mpVM.isMyTurn {
                waitingOverlay
            }
        }
    }

    private var turnBanner: some View {
        VStack {
            HStack {
                Circle()
                    .fill(mpVM.isMyTurn ? Color.swSuccess : Color.swAccentMuted)
                    .frame(width: 8, height: 8)
                Text(mpVM.isMyTurn ? "Your Turn" : waitingText)
                    .font(.swCaption)
                    .foregroundStyle(mpVM.isMyTurn ? Color.swSuccess : Color.swTextSecondary)
                Spacer()
            }
            .padding(.horizontal, swSpacing * 2)
            .padding(.top, swSpacing)
            .background(Color.swBackground.opacity(0.9))
            Spacer()
        }
    }

    private var waitingText: String {
        if let uid = mpVM.session?.currentTurnUID,
           let player = mpVM.session?.players.first(where: { $0.id == uid }) {
            return "Waiting for \(player.displayName)..."
        }
        return "Waiting..."
    }

    private var waitingOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ProgressView()
                    .tint(Color.swAccentPrimary)
                    .padding(swSpacing * 2)
                    .background(Color.swSurface.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(swSpacing * 3)
            }
        }
    }
}
