import SwiftUI
import PomodoroCore

struct TimerView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var loginItem: LoginItem
    @AppStorage("newTaskDraft") private var newTask = ""
    @State private var deleteConfirmation: DeleteConfirmation?
    @State private var draggingID: UUID?
    @State private var dragStartIndex = 0
    @State private var dragOffset: CGFloat = 0

    private var confirmingClear: Bool { deleteConfirmation == .completed }
    @FocusState private var addingTask: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animation: Animation? { reduceMotion ? nil : .easeInOut(duration: 0.18) }

    // Reserve four rows, then require room for every additional row. A minimum
    // alone lets MenuBarExtra propose its old height and compress the checklist.
    private var taskListHeight: CGFloat {
        max(140, CGFloat(model.checklist.tasks.count) * 34 - 2)
    }

    private var isBreak: Bool { model.timer.isActive && model.timer.phase == .rest }
    private var tint: Color { isBreak ? .green : .accentColor }
    private var displayTime: String {
        model.timer.isActive ? model.timeLabel : String(format: "%02d:00", model.workMinutes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Pomodoro").font(.system(size: 13, weight: .semibold))
                Spacer()
                Menu {
                    Button("Clear completed", action: requestClearCompleted)
                        .disabled(!model.checklist.tasks.contains(where: \.isCompleted))
                    Divider()
                    Toggle("Move completed to bottom", isOn: Binding(
                        get: { model.moveCompletedToBottom },
                        set: { enabled in withAnimation(animation) { model.moveCompletedToBottom = enabled } }
                    ))
                    Toggle("Launch at login", isOn: Binding(
                        get: { loginItem.isEnabled },
                        set: { loginItem.setEnabled($0) }
                    ))
                    if let error = loginItem.error {
                        Text(error)
                    }
                    Divider()
                    Button("Quit Pomodoro") { NSApplication.shared.terminate(nil) }
                } label: {
                    Image(systemName: "ellipsis").foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .accessibilityLabel("More options")
            }

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text((isBreak ? "BREAK" : "FOCUS") + (model.timer.isPaused ? " · PAUSED" : ""))
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(.secondary)
                    Text(displayTime)
                        .font(.system(size: 42, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .accessibilityLabel("\(isBreak ? "Break" : "Focus") time, \(displayTime)")
                }
                Spacer()
                if model.timer.isActive {
                    Button(action: model.togglePause) {
                        Image(systemName: model.timer.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(width: 36, height: 36)
                            .foregroundStyle(tint)
                            .background(tint.opacity(0.1), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help(model.timer.isPaused ? "Resume timer" : "Pause timer")
                    .accessibilityLabel(model.timer.isPaused ? "Resume timer" : "Pause timer")
                }
                Button(action: model.toggleTimer) {
                    Image(systemName: model.timer.isActive ? "arrow.counterclockwise" : "play.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 46, height: 46)
                        .foregroundStyle(.white)
                        .background(tint, in: Circle())
                }
                .buttonStyle(.plain)
                .help(model.timer.isActive ? "Reset timer" : "Start timer")
                .accessibilityLabel(model.timer.isActive ? "Reset timer" : "Start timer")
            }
            .frame(height: 68)

            HStack(spacing: 14) {
                DurationControl(title: "Focus", value: $model.workMinutes, finishEditing: { addingTask = true })
                Divider().frame(height: 18)
                DurationControl(title: "Break", value: $model.breakMinutes, finishEditing: { addingTask = true })
            }
            .disabled(model.timer.isActive)
            .frame(height: 30)

            Divider()

            HStack {
                Text("Tasks").font(.system(size: 13, weight: .semibold))
                Text("\(model.remainingTasks)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.primary.opacity(0.05), in: Capsule())
                Spacer()
                if model.checklist.tasks.contains(where: \.isCompleted) {
                    if confirmingClear {
                        Button("Confirm") {
                            withAnimation(animation) {
                                model.clearCompleted()
                                deleteConfirmation = nil
                            }
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 9)
                        .frame(height: 26)
                        .background(.red.opacity(0.1), in: Capsule())
                        .contentShape(Capsule())
                        .buttonStyle(.plain)
                        .accessibilityLabel("Confirm clear completed tasks")
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        Button {
                            withAnimation(animation) { deleteConfirmation = nil }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(width: 30, height: 26)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Cancel clearing completed tasks")
                        .help("Cancel")
                    } else {
                        Button("Clear done", action: requestClearCompleted)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .frame(height: 28)
                            .background(.primary.opacity(0.055), in: Capsule())
                            .contentShape(Capsule())
                            .buttonStyle(.plain)
                            .transition(.opacity.combined(with: .offset(x: 8)))
                    }
                }
            }
            .frame(height: 18)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.22),
                       value: model.checklist.tasks.contains(where: \.isCompleted))

            HStack(spacing: 8) {
                TextField("Add a task…", text: $newTask)
                    .font(.system(size: 13))
                    .textFieldStyle(.plain)
                    .focused($addingTask)
                    .onSubmit(addTask)
                    .accessibilityLabel("New task")
                Button(action: addTask) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(newTask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary : Color.accentColor)
                }
                .buttonStyle(.plain)
                .disabled(newTask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.storageError != nil)
                .help("Add task (Return)")
                .accessibilityLabel("Add task")
            }
            .padding(.horizontal, 11)
            .frame(height: 36)
            .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 9))

            taskList
                .frame(maxWidth: .infinity)
                .frame(height: taskListHeight, alignment: .top)
        }
        .padding(20)
        .frame(width: 340)
        .frame(minHeight: 440, alignment: .top)
        .fixedSize(horizontal: false, vertical: true)
        .defaultFocus($addingTask, true)
        .onChange(of: model.taskInputFocusRequest) { _, _ in addingTask = true }
        .onChange(of: model.checklist.tasks.filter(\.isCompleted).count) { _, count in
            if count == 0 { deleteConfirmation = nil }
        }
        .onExitCommand { withAnimation(animation) { deleteConfirmation = nil } }
    }

    @ViewBuilder
    private var taskList: some View {
        if let error = model.storageError {
            Text(error).font(.caption).foregroundStyle(.red)
        } else if model.checklist.tasks.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 24, weight: .ultraLight))
                Text("A little focus. One task at a time.")
                    .font(.system(size: 11))
            }
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, minHeight: 140)
        } else {
            VStack(spacing: 2) {
                ForEach(model.checklist.tasks) { task in
                    TaskRow(task: task,
                            toggle: { withAnimation(animation) { model.toggleTask(task.id) } },
                            remove: {
                                model.removeTask(task.id)
                                deleteConfirmation = nil
                            },
                            rename: { model.renameTask(task.id, to: $0) },
                            moveUp: { model.moveTask(task.id, by: -1) },
                            moveDown: { model.moveTask(task.id, by: 1) },
                            canMoveUp: model.checklist.tasks.first?.id != task.id,
                            canMoveDown: model.checklist.tasks.last?.id != task.id,
                            confirmingDelete: Binding(
                                get: { deleteConfirmation == .task(task.id) },
                                set: { deleteConfirmation = $0 ? .task(task.id) : nil }
                            ),
                            dragChanged: { updateDrag(task.id, value: $0) },
                            dragEnded: endDrag)
                        .opacity(draggingID == task.id ? 0.2 : 1)
                }
            }
            .coordinateSpace(name: "taskList")
            .overlay(alignment: .topLeading) {
                if let id = draggingID, let task = model.checklist.tasks.first(where: { $0.id == id }) {
                    TaskDragPreview(task: task)
                        .offset(y: dragOffset)
                        .allowsHitTesting(false)
                }
            }
            .onDisappear { endDrag() }
        }
    }

    private func addTask() {
        if model.addTask(newTask) { newTask = ""; addingTask = true }
    }

    private func requestClearCompleted() {
        withAnimation(animation) { deleteConfirmation = .completed }
    }

    private func updateDrag(_ id: UUID, value: DragGesture.Value) {
        guard let current = model.checklist.tasks.firstIndex(where: { $0.id == id }) else { return }
        if draggingID == nil {
            draggingID = id
            dragStartIndex = current
            deleteConfirmation = nil
        }
        guard draggingID == id else { return }
        let rowStride: CGFloat = 34
        let maximumOffset = CGFloat(max(0, model.checklist.tasks.count - 1)) * rowStride
        dragOffset = min(maximumOffset, max(0, CGFloat(dragStartIndex) * rowStride + value.translation.height))
        let destination = min(model.checklist.tasks.count - 1, max(0, Int((dragOffset + 16) / rowStride)))
        if destination != current {
            withAnimation(animation) { model.moveTask(id, to: model.checklist.tasks[destination].id) }
        }
    }

    private func endDrag() {
        withAnimation(animation) {
            draggingID = nil
            dragOffset = 0
        }
    }
}

private enum DeleteConfirmation: Equatable {
    case task(UUID)
    case completed
}

private struct TaskDragPreview: View {
    let task: ChecklistTask

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 17, weight: .light))
                .foregroundStyle(task.isCompleted ? Color.accentColor : Color.secondary.opacity(0.6))
                .frame(width: 24)
            Text(task.title)
                .font(.system(size: 13))
                .strikethrough(task.isCompleted)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 34)
        }
        .frame(height: 32)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.primary.opacity(0.08)))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .accessibilityHidden(true)
    }
}

private struct TaskRow: View {
    let task: ChecklistTask
    let toggle: () -> Void
    let remove: () -> Void
    let rename: (String) -> Bool
    let moveUp: () -> Void
    let moveDown: () -> Void
    let canMoveUp: Bool
    let canMoveDown: Bool
    @State private var isDeleteHovered = false
    @Binding var confirmingDelete: Bool
    let dragChanged: (DragGesture.Value) -> Void
    let dragEnded: () -> Void
    @State private var showingEdit = false
    @State private var isEditing = false
    @State private var draft = ""
    @FocusState private var editingFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animation: Animation? { reduceMotion ? nil : .easeInOut(duration: 0.18) }

    var body: some View {
        HStack(spacing: 6) {
            Button(action: toggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(task.isCompleted ? Color.accentColor : Color.secondary.opacity(0.6))
                    .frame(width: 24, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.title)
            .accessibilityValue(task.isCompleted ? "Completed" : "Not completed")
            .help(task.isCompleted ? "Mark incomplete" : "Mark complete")

            if isEditing {
                TextField("Task title", text: $draft)
                    .font(.system(size: 13))
                    .textFieldStyle(.plain)
                    .focused($editingFocused)
                    .onSubmit(saveEdit)
                    .onExitCommand { cancelEdit() }
                    .accessibilityLabel("Edit task title")
                Button(action: saveEdit) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 30, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .help("Save changes (Return)")
                .accessibilityLabel("Save task changes")
                cancelButton(action: cancelEdit, label: "Cancel editing")
            } else {
                Text(task.title)
                    .font(.system(size: 13))
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(1)
                    .help(task.title + "\nDrag to reorder · Double-click to edit")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 32)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        withAnimation(animation) { showingEdit = true; confirmingDelete = false }
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 5, coordinateSpace: .named("taskList"))
                            .onChanged(dragChanged)
                            .onEnded { _ in dragEnded() }
                    )
                if confirmingDelete {
                    Button("Confirm") {
                        withAnimation(animation) { remove() }
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 9)
                    .frame(height: 28)
                    .background(.red.opacity(0.1), in: Capsule())
                    .contentShape(Capsule())
                    .buttonStyle(.plain)
                    .accessibilityLabel("Confirm delete \(task.title)")
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    cancelButton(action: {
                        withAnimation(animation) { confirmingDelete = false }
                    }, label: "Cancel deletion")
                } else if showingEdit {
                    Button("Edit", action: beginEdit)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 9)
                        .frame(height: 28)
                        .background(Color.accentColor.opacity(0.1), in: Capsule())
                        .buttonStyle(.plain)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    cancelButton(action: {
                        withAnimation(animation) { showingEdit = false }
                    }, label: "Dismiss edit action")
                } else {
                    Button(action: requestDelete) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .opacity(isDeleteHovered ? 1 : 0.5)
                            .frame(width: 34, height: 32)
                            .background(.primary.opacity(isDeleteHovered ? 0.045 : 0), in: RoundedRectangle(cornerRadius: 6))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .onHover { isDeleteHovered = $0 }
                    .help("Delete task")
                    .accessibilityLabel("Delete \(task.title)")
                }
            }
        }
        .frame(height: 32)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Edit", action: beginEdit)
            Divider()
            Button("Move up") { withAnimation(animation) { moveUp() } }
                .disabled(!canMoveUp)
            Button("Move down") { withAnimation(animation) { moveDown() } }
                .disabled(!canMoveDown)
            Divider()
            Button("Delete", role: .destructive, action: requestDelete)
        }
        .onExitCommand {
            withAnimation(animation) { confirmingDelete = false; showingEdit = false; isEditing = false }
        }
    }

    private func cancelButton(action: @escaping () -> Void, label: String) -> some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }

    private func requestDelete() {
        withAnimation(animation) {
            confirmingDelete = true
            showingEdit = false
            isEditing = false
        }
    }

    private func beginEdit() {
        draft = task.title
        withAnimation(animation) {
            isEditing = true
            showingEdit = false
            confirmingDelete = false
        }
        editingFocused = true
    }

    private func saveEdit() {
        guard rename(draft) else { return }
        withAnimation(animation) { isEditing = false }
    }

    private func cancelEdit() {
        withAnimation(animation) { isEditing = false }
    }
}

private struct DurationControl: View {
    let title: String
    @Binding var value: Int
    let finishEditing: () -> Void
    @State private var draft = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(title).font(.system(size: 11)).foregroundStyle(.secondary)
            Spacer(minLength: 0)
            TextField("", text: $draft)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .multilineTextAlignment(.center)
                .frame(width: 46)
                .padding(.vertical, 5)
                .contentShape(Rectangle())
                .controlSize(.regular)
                .focused($isFocused)
                .accessibilityLabel("\(title) minutes")
                .help("Enter \(title.lowercased()) minutes (1–999)")
                .onSubmit { commit(); isFocused = false; finishEditing() }
                .onExitCommand { draft = String(value); isFocused = false; finishEditing() }
                .onChange(of: isFocused) { _, focused in
                    if !focused { commit() }
                }
                .onChange(of: draft) { _, text in
                    let digits = String(text.filter { $0.isASCII && $0.isNumber }.prefix(3))
                    if digits != text { draft = digits }
                    if isFocused, let amount = Int(digits), amount > 0 { value = amount }
                }
            Stepper("", value: $value, in: 1...999)
                .labelsHidden()
                .controlSize(.regular)
                .accessibilityLabel("\(title) minutes")
                .help("Change \(title.lowercased()) minutes")
        }
        .onAppear { draft = String(value) }
        .onChange(of: value) { _, amount in
            draft = String(amount)
        }
    }

    private func commit() {
        if let amount = Int(draft) { value = min(999, max(1, amount)) }
        draft = String(value)
    }
}
