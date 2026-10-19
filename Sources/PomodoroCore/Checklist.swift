import Foundation

public struct ChecklistTask: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var isCompleted: Bool

    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

public struct Checklist {
    public private(set) var tasks: [ChecklistTask]
    public init(tasks: [ChecklistTask] = []) { self.tasks = tasks }

    @discardableResult
    public mutating func add(_ title: String) -> Bool {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return false }
        tasks.append(ChecklistTask(title: cleanTitle))
        return true
    }

    public mutating func toggle(_ id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].isCompleted.toggle()
    }

    @discardableResult
    public mutating func rename(_ id: UUID, to title: String) -> Bool {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty, let index = tasks.firstIndex(where: { $0.id == id }) else { return false }
        tasks[index].title = cleanTitle
        return true
    }

    public mutating func move(_ id: UUID, to destination: UUID) {
        guard id != destination,
              let from = tasks.firstIndex(where: { $0.id == id }),
              let to = tasks.firstIndex(where: { $0.id == destination }) else { return }
        let task = tasks.remove(at: from)
        tasks.insert(task, at: to)
    }

    public mutating func move(_ id: UUID, by offset: Int) {
        guard let from = tasks.firstIndex(where: { $0.id == id }) else { return }
        let to = from + offset
        guard tasks.indices.contains(to) else { return }
        let task = tasks.remove(at: from)
        tasks.insert(task, at: to)
    }

    public mutating func remove(_ id: UUID) { tasks.removeAll { $0.id == id } }
    public mutating func clearCompleted() { tasks.removeAll( where: \.isCompleted) }

    public mutating func moveCompletedToBottom() {
        tasks = tasks.filter { !$0.isCompleted } + tasks.filter(\.isCompleted)
    }
}
