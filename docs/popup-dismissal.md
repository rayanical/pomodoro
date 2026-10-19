# Popup dismissal race (1.9)

The previous AppKit popup had a global mouse-down dismissal monitor and a
separate status-button toggle action. In the captured failing click sequence,
the monitor closed the popup before the button action checked visibility:

```
1791824046.989245 globalMouse close shown=true
1791824046.995550 localMouse [status window] shown=false
1791824046.995856 buttonAction before shown=false
1791824046.995914 show request shown=false
1791824047.002001 buttonAction after shown=true
```

The same pattern repeated during the user's click loop. No application-reopen
callback occurred during these failing clicks. The popup therefore flashed closed
and reopened from the same interaction.

The fix uses SwiftUI MenuBarExtra with window style, matching DevDock's source.
macOS owns the status button and dismissal together; there are no custom mouse
monitors or reopen callbacks. A key-down-only monitor retains Ctrl+A support.
Window configuration disables presentation animation without changing visibility.
The existing app identifier and persistence model remain in use.

Validation: release build and existing core checks passed. After installing and
restarting, the user repeated menu bar toggles and outside-app interactions and
reported that it closes cleanly. This behavior requires the real macOS menu bar;
core unit tests cannot reproduce the cross-process event-delivery order.

Manual regression check: open/close ten times, switch to another app, repeat,
and verify that a close click leaves the popup closed. Also check task entry,
editing, context menus, and the running countdown.
