import Foundation

public enum PreferencesMigration {
    // Retained only to import installations made before the public identifier.
    public static let legacyDomain = "local.rayan.pomodoro-tasks"
    public static let completionKey = "migratedLegacyPreferences"
    public static let loginItemKey = "needsLoginItemMigration"

    private static let keys = [
        "tasks", "workMinutes", "breakMinutes", "newTaskDraft",
        "moveCompletedToBottom", "configuredStartup", "startupEnabled"
    ]

    public static func migrate(from legacy: [String: Any], into defaults: UserDefaults) {
        guard !defaults.bool(forKey: completionKey) else { return }
        let migrateLoginItem = defaults.object(forKey: "configuredStartup") == nil
            && legacy["configuredStartup"] as? Bool == true
        for key in keys where defaults.object(forKey: key) == nil {
            if let value = legacy[key] { defaults.set(value, forKey: key) }
        }
        if migrateLoginItem { defaults.set(true, forKey: loginItemKey) }
        defaults.set(true, forKey: completionKey)
    }
}
