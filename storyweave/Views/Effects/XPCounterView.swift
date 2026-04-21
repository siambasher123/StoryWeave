import SwiftUI

struct XPCounterView: View {
    let from: Int
    let to: Int

    @State private var displayValue: Int = 0

    var body: some View {
        Text("\(displayValue) XP")
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundStyle(Color.swSuccess)
            .onAppear { startCount() }
    }

    private func startCount() {
        displayValue = from
        guard to > from else { return }
        let steps = min(to - from, 120)
        let stepSize = max(1, (to - from) / steps)
        let interval = 1.2 / Double(steps)
        Task {
            var current = from
            while current < to {
                current = min(current + stepSize, to)
                displayValue = current
                try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))
            }
        }
    }
}
