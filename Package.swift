// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PomodoroTasks",
    platforms: [.macOS(.v26)],
    products: [.executable(name: "PomodoroTasks", targets: ["PomodoroTasks"])],
    targets: [
        .target(name: "PomodoroCore"),
        .executableTarget(name: "PomodoroTasks", dependencies: ["PomodoroCore"]),
        .executableTarget(name: "PomodoroCoreTests", dependencies: ["PomodoroCore"], path: "Tests/PomodoroCoreTests")
    ]
)
