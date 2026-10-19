import Foundation

public struct FocusTimer {
    public enum Phase: Sendable { case work, rest }
    public private(set) var phase: Phase = .work
    public private(set) var deadline: Date?
    private var pausedSeconds: TimeInterval?
    private var workSeconds: TimeInterval = 1500
    private var breakSeconds: TimeInterval = 300

    public init() {}
    public var isRunning: Bool { deadline != nil }
    public var isPaused: Bool { pausedSeconds != nil }
    public var isActive: Bool { isRunning || isPaused }

    public mutating func start(workMinutes: Int, breakMinutes: Int, now: Date) {
        workSeconds = Double(min(999, max(1, workMinutes))) * 60
        breakSeconds = Double(min(999, max(1, breakMinutes))) * 60
        phase = .work
        pausedSeconds = nil
        deadline = now.addingTimeInterval(workSeconds)
    }

    public mutating func stop() {
        deadline = nil
        pausedSeconds = nil
        phase = .work
    }

    public mutating func pause(now: Date) {
        guard isRunning else { return }
        advance(now: now)
        pausedSeconds = max(0, deadline!.timeIntervalSince(now))
        deadline = nil
    }

    public mutating func resume(now: Date) {
        guard let pausedSeconds else { return }
        deadline = now.addingTimeInterval(pausedSeconds)
        self.pausedSeconds = nil
    }

    // Advance against a deadline rather than counting ticks, including after sleep.
    @discardableResult
    public mutating func advance(now: Date) -> Bool {
        guard let end = deadline, now >= end else { return false }
        let cycle = workSeconds + breakSeconds
        let elapsed = now.timeIntervalSince(end)
        let cycles = floor(elapsed / cycle)
        let offset = elapsed - cycles * cycle
        let nextDuration = phase == .work ? breakSeconds : workSeconds
        let cycleStart = end.addingTimeInterval(cycles * cycle)
        if offset < nextDuration {
            phase = phase == .work ? .rest : .work
            deadline = cycleStart.addingTimeInterval(nextDuration)
        } else {
            deadline = cycleStart.addingTimeInterval(cycle)
        }
        return true
    }

    public func remainingSeconds(now: Date) -> Int {
        if let pausedSeconds { return Int(ceil(pausedSeconds)) }
        guard let deadline else { return 0 }
        return max(0, Int(ceil(deadline.timeIntervalSince(now))))
    }
}
