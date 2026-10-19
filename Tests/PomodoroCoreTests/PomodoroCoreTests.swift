import Foundation
import PomodoroCore

func timerTransitionsAtExactBoundaries() {
    let start = Date(timeIntervalSince1970: 0)
    var timer = FocusTimer()
    timer.start(workMinutes: 25, breakMinutes: 5, now: start)
    expect(timer.remainingSeconds(now: start.addingTimeInterval(0.2)) == 1500)
    expect(!timer.advance(now: start.addingTimeInterval(1499)))
    expect(timer.advance(now: start.addingTimeInterval(1500)))
    expect(timer.phase == .rest)
    expect(timer.remainingSeconds(now: start.addingTimeInterval(1500)) == 300)
    expect(timer.advance(now: start.addingTimeInterval(1800)))
    expect(timer.phase == .work)
    expect(timer.remainingSeconds(now: start.addingTimeInterval(1800)) == 1500)
    timer.stop()
    expect(!timer.isRunning)
    expect(!timer.advance(now: start.addingTimeInterval(9000)))
}

func timerCatchesUpAfterSleepWithoutDrifting() {
    let start = Date(timeIntervalSince1970: 0)
    var timer = FocusTimer()
    timer.start(workMinutes: 25, breakMinutes: 5, now: start)
    expect(timer.advance(now: start.addingTimeInterval(7000)))
    expect(timer.phase == .rest)
    expect(timer.remainingSeconds(now: start.addingTimeInterval(7000)) == 200)
    expect(timer.advance(now: start.addingTimeInterval(7200)))
    expect(timer.phase == .work)
    expect(timer.remainingSeconds(now: start.addingTimeInterval(7200)) == 1500)
}

func checklistRoundTripPreservesIdentityOrderAndCompletion() throws {
    var list = Checklist()
    expect(!list.add(" \n "))
    expect(list.add("  First task  "))
    expect(list.add("Second task"))
    let firstID = list.tasks[0].id
    list.toggle(firstID)
    let saved = try JSONEncoder().encode(list.tasks)
    let loaded = try JSONDecoder().decode([ChecklistTask].self, from: saved)
    expect(loaded == list.tasks)
    expect(loaded[0].title == "First task")
    expect(loaded[0].isCompleted)
    list.toggle(firstID)
    expect(!list.tasks[0].isCompleted)
    list.toggle(firstID)
    list.clearCompleted()
    expect(list.tasks.map(\.title) == ["Second task"])
    list.remove(list.tasks[0].id)
    expect(list.tasks.isEmpty)
}

func expect(_ condition: @autoclosure () -> Bool, file: StaticString = #file, line: UInt = #line) {
    precondition(condition(), "Check failed", file: file, line: line)
}

func editingAndReorderingPreserveTaskData() throws {
    var list = Checklist()
    list.add("One"); list.add("Two"); list.add("Three")
    let ids = list.tasks.map(\.id)
    list.toggle(ids[1])
    expect(!list.rename(ids[1], to: " \n "))
    expect(list.rename(ids[1], to: "  Edited  "))
    expect(list.tasks[1].id == ids[1] && list.tasks[1].isCompleted)
    list.move(ids[0], to: ids[2])
    expect(list.tasks.map(\.id) == [ids[1], ids[2], ids[0]])
    list.move(ids[0], to: ids[1])
    expect(list.tasks.map(\.id) == ids)
    list.move(ids[0], by: -1)
    expect(list.tasks.map(\.id) == ids)
    list.move(ids[1], by: 1)
    expect(list.tasks.map(\.id) == [ids[0], ids[2], ids[1]])
    let loaded = try JSONDecoder().decode([ChecklistTask].self, from: JSONEncoder().encode(list.tasks))
    expect(loaded == list.tasks)
    expect(loaded[2].title == "Edited" && loaded[2].isCompleted)
}

func pauseResumeAndResetPreserveTimeAndPhase() {
    let start = Date(timeIntervalSince1970: 0)
    var timer = FocusTimer()
    timer.start(workMinutes: 1, breakMinutes: 1, now: start)
    timer.pause(now: start.addingTimeInterval(10.25))
    expect(timer.isPaused && timer.isActive && !timer.isRunning)
    expect(timer.remainingSeconds(now: start.addingTimeInterval(1000)) == 50)
    expect(!timer.advance(now: start.addingTimeInterval(1000)))
    timer.resume(now: start.addingTimeInterval(1000))
    expect(timer.deadline == start.addingTimeInterval(1049.75))
    expect(timer.advance(now: start.addingTimeInterval(1049.75)))
    expect(timer.phase == .rest)
    timer.pause(now: start.addingTimeInterval(1050))
    timer.resume(now: start.addingTimeInterval(2000))
    expect(timer.phase == .rest)
    expect(timer.remainingSeconds(now: start.addingTimeInterval(2000)) == 60)
    timer.pause(now: start.addingTimeInterval(2001))
    timer.stop()
    expect(!timer.isActive && !timer.isPaused && timer.phase == .work)
    timer.resume(now: start.addingTimeInterval(3000))
    expect(!timer.isActive)
    timer.start(workMinutes: 1, breakMinutes: 1, now: start)
    timer.pause(now: start.addingTimeInterval(65))
    expect(timer.phase == .rest)
    expect(timer.remainingSeconds(now: start) == 55)
}

pauseResumeAndResetPreserveTimeAndPhase()
timerTransitionsAtExactBoundaries()
timerCatchesUpAfterSleepWithoutDrifting()
try checklistRoundTripPreservesIdentityOrderAndCompletion()
try editingAndReorderingPreserveTaskData()
var grouped = Checklist(tasks: [
    ChecklistTask(title: "Done one", isCompleted: true),
    ChecklistTask(title: "Open one"),
    ChecklistTask(title: "Done two", isCompleted: true),
    ChecklistTask(title: "Open two")
])
let groupedIDs = Set(grouped.tasks.map(\.id))
grouped.moveCompletedToBottom()
expect(grouped.tasks.map(\.title) == ["Open one", "Open two", "Done one", "Done two"])
expect(Set(grouped.tasks.map(\.id)) == groupedIDs)
expect(grouped.tasks.suffix(2).allSatisfy(\.isCompleted))
print("Passed: timer boundaries, sleep recovery, checklist persistence, editing, reordering and completion grouping")
