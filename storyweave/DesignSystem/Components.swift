import SwiftUI

enum SWButtonStyle { case primary, secondary, danger }

struct SWButton: View {
    let title: String
    let style: SWButtonStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.swHeadline)
                .foregroundStyle(labelColor)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(borderColor, lineWidth: 1)
                )
        }
        .accessibilityLabel(title)
    }

    private var labelColor: Color {
        switch style {
        case .primary:   return .white           // white on vibrant purple
        case .secondary: return Color.swTextPrimary
        case .danger:    return .white
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:   return Color.swAccentPrimary
        case .secondary: return Color.swSurfaceRaised
        case .danger:    return Color.swDanger
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:   return Color.swAccentLight.opacity(0.4)
        case .secondary: return Color.swAccentMuted.opacity(0.35)
        case .danger:    return Color.clear
        }
    }
}

struct SWTextField: View {
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundStyle(Color.swTextPrimary)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundStyle(Color.swTextPrimary)
                    .keyboardType(placeholder.lowercased().contains("email") ? .emailAddress : .default)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
        .font(.swBody)
        .tint(Color.swAccentLight)
        .padding(.horizontal, swSpacing * 2)
        .frame(height: 52)
        .background(Color.swSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.swAccentPrimary.opacity(0.45), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct SWCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(swSpacing * 2)
            .background(Color.swSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.swAccentPrimary.opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SWPillBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.swCaption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
    }
}
