import SwiftUI

struct SessionInviteRow: View {
    let message: ChatMessage
    let onJoin: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: swSpacing) {
            HStack(spacing: swSpacing) {
                Image(systemName: "dice.fill")
                    .font(.title2)
                    .foregroundStyle(Color.swAccentPrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(message.senderName)
                        .font(.swCaption).foregroundStyle(Color.swTextSecondary)
                    Text(message.body)
                        .font(.swBody).foregroundStyle(Color.swTextPrimary)
                }
            }

            SWButton(title: "Join Session", style: .primary) {
                if let sessionID = message.inviteSessionID {
                    onJoin(sessionID)
                }
            }
            .frame(maxWidth: 180)
        }
        .padding(swSpacing * 2)
        .background(Color.swAccentDeep.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.swAccentPrimary.opacity(0.4), lineWidth: 1)
        )
    }
}
