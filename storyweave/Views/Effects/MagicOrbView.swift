import SwiftUI

struct MagicOrbView: View {
    @State private var rot1: Double = 0
    @State private var rot2: Double = 0
    @State private var rot3: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.swAccentPrimary.opacity(0.5), lineWidth: 2)
                .frame(width: 60, height: 60)
                .rotation3DEffect(.degrees(rot1), axis: (x: 1, y: 0, z: 0))

            Circle()
                .stroke(Color.swAccentLight.opacity(0.4), lineWidth: 1.5)
                .frame(width: 44, height: 44)
                .rotation3DEffect(.degrees(rot2), axis: (x: 0, y: 1, z: 0))

            Circle()
                .stroke(Color.swAccentHighlight.opacity(0.3), lineWidth: 1)
                .frame(width: 28, height: 28)
                .rotation3DEffect(.degrees(rot3), axis: (x: 1, y: 1, z: 0))

            Circle()
                .fill(Color.swAccentPrimary.opacity(0.2))
                .frame(width: 18, height: 18)
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) { rot1 = 360 }
            withAnimation(.linear(duration: 2.3).repeatForever(autoreverses: false)) { rot2 = 360 }
            withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) { rot3 = 360 }
        }
    }
}
