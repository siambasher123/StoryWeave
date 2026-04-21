import SwiftUI

struct DeathOverlay: View {
    let characterName: String
    @Binding var isShowing: Bool

    @State private var opacity: Double = 0
    @State private var blurRadius: CGFloat = 0
    @State private var saturation: Double = 1

    var body: some View {
        if isShowing {
            ZStack {
                Color.swBackground.opacity(0.88).ignoresSafeArea()
                VStack(spacing: swSpacing * 2) {
                    Text("☠")
                        .font(.system(size: 60))
                    Text("\(characterName) has fallen")
                        .font(.swTitle)
                        .foregroundStyle(Color.swDanger)
                    Text("They will not be forgotten.")
                        .font(.swBody)
                        .foregroundStyle(Color.swTextSecondary)
                }
                .opacity(opacity)
                .blur(radius: blurRadius)
                .saturation(saturation)
            }
            .accessibilityLabel("\(characterName) has fallen")
            .task {
                withAnimation(.easeIn(duration: 1)) { opacity = 1; saturation = 0 }
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.easeOut(duration: 1)) { blurRadius = 10; opacity = 0 }
                try? await Task.sleep(for: .seconds(1))
                isShowing = false
            }
        }
    }
}
