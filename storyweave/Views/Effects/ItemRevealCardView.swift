import SwiftUI

struct ItemRevealCardView: View {
    let item: InventoryItem
    let onDismiss: () -> Void

    @State private var rotation: Double = 0
    private var isFlipped: Bool { rotation >= 90 }

    var body: some View {
        ZStack {
            if !isFlipped {
                frontFace.opacity(isFlipped ? 0 : 1)
            } else {
                backFace
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
        .onTapGesture {
            if isFlipped {
                onDismiss()
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { rotation = 180 }
            }
        }
    }

    private var itemEmoji: String {
        switch item.itemType {
        case .consumable: return "⚗️"
        case .passive:    return "✨"
        case .keyItem:    return "🗝"
        }
    }

    private var frontFace: some View {
        VStack(spacing: swSpacing) {
            Text(itemEmoji)
                .font(.system(size: 52))
            Text(item.name)
                .font(.swHeadline)
                .foregroundStyle(Color.swTextPrimary)
            Text("Item Found!")
                .font(.swCaption)
                .foregroundStyle(Color.swAccentLight)
            Text("Tap to reveal")
                .font(.swCaption)
                .foregroundStyle(Color.swTextSecondary)
        }
        .frame(width: 200, height: 240)
        .background(Color.swSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.swAccentPrimary.opacity(0.6), lineWidth: 2)
        )
        .shadow(color: Color.swAccentPrimary.opacity(0.3), radius: 16)
    }

    private var backFace: some View {
        VStack(alignment: .leading, spacing: swSpacing) {
            HStack {
                Text(itemEmoji).font(.title2)
                Text(item.name).font(.swHeadline).foregroundStyle(Color.swTextPrimary)
            }
            Divider().background(Color.swSurfaceRaised)
            Text(item.loreDescription)
                .font(.swBody)
                .foregroundStyle(Color.swTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Text("Tap to close")
                .font(.swCaption)
                .foregroundStyle(Color.swTextSecondary)
        }
        .padding(swSpacing * 2)
        .frame(width: 200, height: 240)
        .background(Color.swSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.swAccentHighlight.opacity(0.5), lineWidth: 2)
        )
    }
}
