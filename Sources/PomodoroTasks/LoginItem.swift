import Combine
import Foundation
import ServiceManagement
import PomodoroCore

@MainActor
final class LoginItem: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var error: String?

    init() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func configureOnLaunch() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: PreferencesMigration.loginItemKey) {
            setEnabled(defaults.bool(forKey: "startupEnabled"))
            if error == nil { defaults.removeObject(forKey: PreferencesMigration.loginItemKey) }
            return
        }
        // Enable once on installation, then respect changes made in the app or macOS.
        guard UserDefaults.standard.object(forKey: "configuredStartup") == nil else { return }
        setEnabled(true)
        if error == nil { UserDefaults.standard.set(true, forKey: "configuredStartup") }
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled { try SMAppService.mainApp.register() }
            } else {
                try SMAppService.mainApp.unregister()
            }
            error = nil
        } catch {
            self.error = "Startup could not be changed: \(error.localizedDescription)"
        }
        isEnabled = SMAppService.mainApp.status == .enabled
        UserDefaults.standard.set(isEnabled, forKey: "startupEnabled")
        UserDefaults.standard.set(error, forKey: "startupError")
        if SMAppService.mainApp.status == .requiresApproval {
            error = "Allow Pomodoro in System Settings → General → Login Items."
            UserDefaults.standard.set(error, forKey: "startupError")
        }
    }
}
