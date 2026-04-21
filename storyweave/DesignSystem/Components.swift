import SwiftUI

// MARK: - Button press animation style

private struct SWButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

// MARK: - SWButton

enum SWButtonStyle { case primary, secondary, danger }

struct SWButton: View {
    let title: String
    let style: SWButtonStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.swHeadline)
                .foregroundStyle(Color.swTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(backgroundShape)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .shadow(color: shadowColor, radius: 12, x: 0, y: 6)
        }
        .buttonStyle(SWButtonPressStyle())
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private var backgroundShape: some View {
        switch style {
        case .primary:
            LinearGradient.swGradientPrimary
        case .secondary:
            LinearGradient.swGradientSurfaceRaised
        case .danger:
            LinearGradient.swGradientDanger
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:   return Color.swAccentLight.opacity(0.35)
        case .secondary: return Color.swAccentMuted.opacity(0.45)
        case .danger:    return Color.clear
        }
    }

    private var borderWidth: CGFloat {
        style == .secondary ? 1.5 : 1.0
    }

    private var shadowColor: Color {
        switch style {
        case .primary:   return Color.swAccentPrimary.opacity(0.40)
        case .secondary: return Color.swAccentMuted.opacity(0.15)
        case .danger:    return Color.swDanger.opacity(0.30)
        }
    }
}

// MARK: - SWTextField

struct SWTextField: View {
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool

    @FocusState private var isFocused: Bool

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundStyle(Color.swTextPrimary)
                    .focused($isFocused)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundStyle(Color.swTextPrimary)
                    .focused($isFocused)
                    .keyboardType(placeholder.lowercased().contains("email") ? .emailAddress : .default)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
        .font(.swBody)
        .tint(Color.swAccentLight)
        .padding(.horizontal, swSpacing * 2)
        .frame(height: 52)
        .background(LinearGradient.swGradientSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isFocused ? Color.swAccentLight.opacity(0.85) : Color.swAccentPrimary.opacity(0.45),
                    lineWidth: isFocused ? 2.0 : 1.5
                )
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: isFocused ? Color.swAccentPrimary.opacity(0.22) : .clear, radius: 8)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - SWCard

struct SWCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(swSpacing * 2)
            .background(LinearGradient.swGradientSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.swAccentLight.opacity(0.28), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.swAccentPrimary.opacity(0.10), radius: 8, x: 0, y: 4)
    }
}

// MARK: - SWPillBadge

struct SWPillBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.swCaption)
            .fontWeight(.semibold)
            .foregroundStyle(Color.swTextPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
    }
}

// MARK: - SWAvatarView

struct SWAvatarView: View {
    let name: String
    var size: CGFloat = 40
    var color: Color = .swAccentPrimary

    var body: some View {
        ZStack {
            // Outer halo ring
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 4)
                .frame(width: size + 4, height: size + 4)

            // Radial fill — lit-sphere effect
            Circle()
                .fill(RadialGradient(
                    colors: [color.opacity(0.35), color.opacity(0.06)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * 0.52))
                .frame(width: size, height: size)

            // Inner ring
            Circle()
                .stroke(color.opacity(0.50), lineWidth: 1.5)
                .frame(width: size, height: size)

            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: size * 0.42, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
        }
    }
}

// MARK: - SWEmptyStateView

struct SWEmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    @State private var pulsing = false

    var body: some View {
        VStack(spacing: swSpacing * 2) {
            ZStack {
                Circle()
                    .fill(Color.swAccentPrimary.swGradientGlow(radius: 60))
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 44))
                    .foregroundStyle(Color.swAccentLight.opacity(0.75))
                    .scaleEffect(pulsing ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulsing)
            }
            .onAppear { pulsing = true }

            Text(title)
                .font(.swHeadline)
                .foregroundStyle(Color.swTextPrimary.opacity(0.80))

            Text(subtitle)
                .font(.swBody)
                .foregroundStyle(Color.swTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(swSpacing * 4)
    }
}

// MARK: - SWSearchBar

struct SWSearchBar: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: swSpacing) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.swTextSecondary)
                .font(.swBody)
            TextField(placeholder, text: $text)
                .foregroundStyle(Color.swTextPrimary)
                .font(.swBody)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.swTextSecondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, swSpacing * 1.5)
        .padding(.vertical, swSpacing)
        .background(Color.swSurface, in: RoundedRectangle(cornerRadius: 12))
    }
}
