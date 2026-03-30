import SwiftUI

struct ChoiceButtonView: View {
    let choice: Choice
    @ObservedObject var vm: StoryPlayerViewModel
    @EnvironmentObject var session: AppSession

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                vm.makeChoice(choice, userId: session.userId ?? "")
            }
        } label: {
            HStack {
                Text(choice.text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.indigo)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.indigo.opacity(0.6))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(Color.indigo.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.indigo.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
