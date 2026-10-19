import AppKit
import SwiftUI
import UserNotifications

@main
struct PomodoroTasksApp: App {
    @StateObject private var model = AppModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Let macOS own both status-item clicks and outside dismissal. Separate
        // mouse monitors can close the window before the same click toggles it.
        MenuBarExtra {
            TimerView(model: model, loginItem: appDelegate.loginItem)
                .background(PopupWindowConfiguration())
                .onAppear { model.taskInputFocusRequest += 1 }
        } label: {
            if model.timer.isActive {
                Text(model.timeLabel)
                    .monospacedDigit()
                    .frame(width: 64)
            } else {
                Image(systemName: "clock")
            }
        }
        .menuBarExtraStyle(.window)

        Settings { EmptyView() }
    }
}

// Configure presentation only; MenuBarExtra retains ownership of visibility.
private struct PopupWindowConfiguration: NSViewRepresentable {
    final class View: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.animationBehavior = .none
        }
    }
    func makeNSView(context: Context) -> View { View() }
    func updateNSView(_ view: View, context: Context) {}
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    let loginItem = LoginItem()
    private var keyboardMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        UNUserNotificationCenter.current().delegate = self
        loginItem.configureOnLaunch()
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection([.control, .command, .option, .shift])
            if event.charactersIgnoringModifiers?.lowercased() == "a",
               modifiers == .control || modifiers == .command,
               let editor = event.window?.firstResponder as? NSTextView,
               editor.isEditable {
                editor.selectAll(nil)
                return nil
            }
            return event
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationWillTerminate(_ notification: Notification) {
        if let keyboardMonitor { NSEvent.removeMonitor(keyboardMonitor) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["phase-end"])
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
