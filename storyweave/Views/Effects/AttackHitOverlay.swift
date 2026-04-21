import SwiftUI

struct AttackHitOverlay: View {
    let outcome: CombatOutcome
    @Binding var isShowing: Bool

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        if isShowing {
            ZStack {
                outcomeColor.opacity(0.2).ignoresSafeArea()
                Text(outcomeLabel)
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(outcomeColor)
                    .offset(y: offset)
                    .opacity(opacity)
            }
            .accessibilityLabel("Combat outcome: \(outcomeLabel)")
            .task {
                switch outcome {
                case .criticalFail:    HapticEngine.play(.error)
                case .fail:            HapticEngine.play(.impact(.light))
                case .partialSuccess:  HapticEngine.play(.impact(.medium))
                case .success:         HapticEngine.play(.impact(.heavy))
                case .criticalSuccess: HapticEngine.play(.success)
                }
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { offset = -20 }
                withAnimation(.easeOut(duration: 0.8).delay(0.3)) { opacity = 0 }
                try? await Task.sleep(for: .seconds(1))
                isShowing = false
                offset = 0
                opacity = 1
            }
        }
    }

    private var outcomeLabel: String {
        switch outcome {
        case .criticalFail:    return "CRITICAL FAIL!"
        case .fail:            return "Miss"
        case .partialSuccess:  return "Glancing Hit"
        case .success:         return "Hit!"
        case .criticalSuccess: return "CRITICAL HIT!"
        }
    }

    private var outcomeColor: Color {
        switch outcome {
        case .criticalFail:    return .swDanger
        case .fail:            return .swTextSecondary
        case .partialSuccess:  return .swWarning
        case .success:         return .swSuccess
        case .criticalSuccess: return .swAccentLight
        }
    }
}
