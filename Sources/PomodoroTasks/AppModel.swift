import AppKit
import Combine
import PomodoroCore
import UserNotifications

@MainActor
final class AppModel: ObservableObject {
    @Published var workMinutes: Int { didSet { defaults.set(workMinutes, forKey: "workMinutes") } }
    @Published var breakMinutes: Int { didSet { defaults.set(breakMinutes, forKey: "breakMinutes") } }
    @Published var moveCompletedToBottom: Bool {
        didSet {
            defaults.set(moveCompletedToBottom, forKey: "moveCompletedToBottom")
            if moveCompletedToBottom { checklist.moveCompletedToBottom(); saveTasks() }
        }
    }
    @Published private(set) var timer = FocusTimer()
    @Published private(set) var checklist: Checklist
    @Published private(set) var secondsLeft = 0
    @Published private(set) var storageError: String?
    @Published var taskInputFocusRequest = 0
    private let defaults: UserDefaults
    private var ticker: AnyCancellable?
    private let notificationID = "phase-end"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        workMinutes = min(999, max(1, defaults.object(forKey: "workMinutes") as? Int ?? 85))
        breakMinutes = min(999, max(1, defaults.object(forKey: "breakMinutes") as? Int ?? 5))
        moveCompletedToBottom = defaults.object(forKey: "moveCompletedToBottom") as? Bool ?? true
        if let data = defaults.data(forKey: "tasks") {
            do { checklist = Checklist(tasks: try JSONDecoder().decode([ChecklistTask].self, from: data)) }
            catch {
                checklist = Checklist()
                storageError = "Saved tasks could not be read. Your saved data has been kept."
            }
        } else {
            checklist = Checklist()
        }
        if moveCompletedToBottom && storageError == nil {
            checklist.moveCompletedToBottom()
            saveTasks()
        }
        ticker = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect().sink { [weak self] now in self?.tick(now) }
    }

    var timeLabel: String { String(format: "%02d:%02d", secondsLeft / 60, secondsLeft % 60) }
    var remainingTasks: Int { checklist.tasks.filter { !$0.isCompleted }.count }

    func toggleTimer() {
        if timer.isActive {
            timer.stop()
            secondsLeft = 0
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
        } else {
            timer.start(workMinutes: workMinutes, breakMinutes: breakMinutes, now: Date())
            secondsLeft = timer.remainingSeconds(now: Date())
            Task {
                _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                scheduleNotification()
            }
        }
    }

    func togglePause() {
        let now = Date()
        if timer.isPaused {
            timer.resume(now: now)
            scheduleNotification()
        } else if timer.isRunning {
            timer.pause(now: now)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
        }
        secondsLeft = timer.remainingSeconds(now: now)
    }

    private func tick(_ now: Date) {
        guard timer.isRunning else { return }
        if timer.advance(now: now) { scheduleNotification() }
        let remaining = timer.remainingSeconds(now: now)
        if secondsLeft != remaining { secondsLeft = remaining }
    }

    private func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])
        guard let deadline = timer.deadline else { return }
        let content = UNMutableNotificationContent()
        content.title = "Pomodoro Menu Bar"
        content.body = timer.phase == .work ? "Time for a break! ☕️" : "Time to get back to work! 💪"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, deadline.timeIntervalSinceNow), repeats: false)
        center.add(UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger))
    }

    @discardableResult
    func addTask(_ title: String) -> Bool {
        guard storageError == nil, checklist.add(title) else { return false }
        if moveCompletedToBottom { checklist.moveCompletedToBottom() }
        saveTasks()
        return true
    }
    func toggleTask(_ id: UUID) {
        checklist.toggle(id)
        if moveCompletedToBottom { checklist.moveCompletedToBottom() }
        saveTasks()
    }
    @discardableResult
    func renameTask(_ id: UUID, to title: String) -> Bool {
        guard checklist.rename(id, to: title) else { return false }
        saveTasks()
        return true
    }
    func moveTask(_ id: UUID, to destination: UUID) {
        checklist.move(id, to: destination)
        saveTasks()
    }
    func moveTask(_ id: UUID, by offset: Int) {
        checklist.move(id, by: offset)
        saveTasks()
    }
    func removeTask(_ id: UUID) { checklist.remove(id); saveTasks() }
    func clearCompleted() { checklist.clearCompleted(); saveTasks() }

    private func saveTasks() {
        do { defaults.set(try JSONEncoder().encode(checklist.tasks), forKey: "tasks") }
        catch { storageError = "Tasks could not be saved. Please keep the app open." }
    }
}
