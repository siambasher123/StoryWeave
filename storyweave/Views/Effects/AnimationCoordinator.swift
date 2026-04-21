import Foundation

@MainActor
final class AnimationCoordinator {
    static let shared = AnimationCoordinator()
    private let maxConcurrent = 2
    private(set) var activeCount = 0

    private init() {}

    func requestSlot() -> Bool {
        guard activeCount < maxConcurrent else { return false }
        activeCount += 1
        return true
    }

    func releaseSlot() {
        activeCount = max(0, activeCount - 1)
    }
}
