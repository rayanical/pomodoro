# Pomodoro

A small native macOS menu bar timer with a persistent task list. No Dock icon, account, or cloud service.

## Features

- Focus and break timers with editable durations, pause/resume, and reset.
- Live countdown in the menu bar; a clock icon when idle.
- Add, edit, complete, delete, and drag tasks to reorder them.
- Optional automatic sorting of completed tasks to the bottom.
- A compact popup with room for four tasks that grows as more are added, without scrolling.
- Tasks, order, durations, draft text, and preferences saved locally between launches.
- Launch at login and notifications when a timer phase ends.

## Download and install

Download **Pomodoro.zip** from this repository's **Releases** page, unzip it, and move **Pomodoro.app** into **Applications**. Launch it, then click the clock icon in the menu bar.

**Requirements:** macOS 26 or later. The downloadable app is built for Apple Silicon (M1 or later).

This community build is ad-hoc signed, **not notarized by Apple**. macOS may block its first launch. If you trust the downloaded build, follow Apple's instructions for opening an app from an unidentified developer through **System Settings → Privacy & Security → Open Anyway**. No changes to system security are required.

Launch at login is enabled on first launch. Turn it off in the app's **…** menu or macOS Login Items if you prefer. Allow notifications when starting a timer if you want phase alerts.

## Use

Set Focus and Break minutes, then press Play. Pause freezes the remaining time; Resume continues it. The circular arrow resets to the full Focus duration. An active or paused timer ends when the app quits.

Add a task with Return or the plus button. Double-click a task title to reveal Edit, or right-click for Edit and Move up/down. Drag a title to reorder its row. Delete and Clear done show an inline confirmation before removing tasks.

The **…** menu includes **Move completed to bottom**, **Launch at login**, and Quit. Tasks and settings are stored in macOS UserDefaults under `local.rayan.pomodoro-tasks`. The app includes no analytics or network service. macOS handles notification and login-item permissions.

Very long task lists are limited by the available screen height. Long titles display on one line; hover to read the full title.

## Build from source

Requires macOS 26+, Swift 6.2 command line tools, Python 3, and Git. There are no third-party package dependencies.

Clone this repository, change into its folder, then run:

```sh
zsh scripts/build-app.sh
```

Outputs:

- `build/Pomodoro.app` — the app bundle
- `build/Pomodoro.zip` — the distributable archive

The build uses the host Mac's architecture. It preserves the app's bundle identifier so rebuilding does not discard existing tasks or preferences.

## Tests

```sh
CLANG_MODULE_CACHE_PATH="$PWD/.build/module-cache" \
SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache" \
swift run --disable-sandbox --cache-path .build/cache PomodoroCoreTests
```

Checks cover timer boundaries, sleep recovery, pause/resume/reset, task encoding, editing, reordering, and completed-task grouping. The test runner is an executable so it works with Command Line Tools installations that lack usable XCTest/Swift Testing modules.

## License

MIT. The app icon was generated with AI; its source image and generation prompt are in `Assets/`.
