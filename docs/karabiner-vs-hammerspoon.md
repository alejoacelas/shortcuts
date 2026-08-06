<!--ai-->
# Karabiner versus Hammerspoon

## The short answer

Karabiner can perform actions. It has three routes:

1. Emit keyboard, mouse, consumer, or pointing events.
2. Call one of four built-in software functions: open/focus an application, double-click, move the pointer, or sleep the Mac.
3. Execute an arbitrary shell command.

The shell-command route means Karabiner can indirectly do almost anything a terminal command can do, including run scripts, call `open`, invoke AppleScript through `osascript`, run an Apple Shortcut, or contact an API.

Karabiner is not less *powerful* in the computability sense. It is worse as the place to *express and operate complex actions*. Its native model is a declarative keyboard-event transformer. Once an action needs application state, branching, asynchronous work, several steps, structured errors, or reusable code, the behavior moves into an external script. At that point Karabiner is only the trigger.

Hammerspoon combines the trigger and the action in one long-running Lua environment with direct macOS APIs for applications, menus, windows, input, clipboard, notifications, networking, files, timers, and more.

## Where each sits

```text
Physical keyboard
      │
      ▼
Karabiner event pipeline
  - identifies device and physical key
  - applies timing and conditions
  - suppresses or emits replacement input
  - can launch a shell command
      │
      ▼
macOS event system
      │
      ├──► frontmost application
      │
      └──► Hammerspoon event tap
             - observes or suppresses events
             - runs Lua functions
             - talks to macOS apps and services
```

Karabiner is closer to the keyboard. Hammerspoon is closer to applications and the operating system.

That placement explains their strengths:

- Karabiner can reliably distinguish left versus right modifiers, keyboards, tap versus hold, simultaneous keys, and layers before applications receive the event.
- Hammerspoon can ask which app and window are active, inspect application menus, keep state, wait for callbacks, manipulate data, and decide what to do next.

## Karabiner's complete action model

### Emit input events

This is Karabiner's native language. A rule consumes an input event and produces zero or more output events.

It can emit:

- Ordinary keys and modifier combinations.
- Consumer keys such as volume, brightness, play, and mute.
- Mouse buttons, movement, and scrolling.
- Sticky modifiers.
- Events when a key is pressed, released, held, or tapped alone.
- Repeated or delayed events.
- Different events for simultaneous keys.

Examples:

- Caps Lock → Escape.
- Caps Lock held → Control; tapped → Escape.
- Right Command + H → `⌘⇧H`.
- Two keys pressed together → an unused key such as F18.
- Disable the built-in keyboard while a particular external keyboard is connected.

This is not merely “send another shortcut.” Timing rules let Karabiner define a small state machine around physical input.

### Set internal variables

Karabiner rules can set variables and condition later rules on them. This supports layers and modes:

```text
hold Caps Lock → set navigation_layer = 1
navigation_layer + H → left arrow
release Caps Lock → set navigation_layer = 0
```

Variables are useful for keyboard state. They are not a general application data model: there are no rich tables, domain objects, callbacks, or normal program structure.

### Apply conditions

Karabiner can enable a rule based on:

- Frontmost application bundle identifier or executable path.
- Keyboard or pointing-device identity.
- Keyboard type.
- Current input source or language.
- Whether another device exists.
- Karabiner variables and expressions.
- Whether an event was already changed.

So yes: **Karabiner can perform application-specific mappings.** A rule can say “in Terminal, Control-H becomes Backspace” or “everywhere except Terminal, remap this key.” The official condition uses bundle-identifier regular expressions. [Karabiner application conditions](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/conditions/frontmost-application/)

What Karabiner knows natively is mostly *which app is frontmost*. It does not expose a broad native model of that app's documents, menus, tabs, windows, or selected content.

### Call built-in software functions

Karabiner currently documents four direct software actions:

- `open_application`: launch/focus an app by bundle ID or path, or focus an app from recent history.
- `cg_event_double_click`: emit a double-click.
- `set_mouse_cursor_position`: move the pointer.
- `iokit_power_management_sleep_system`: sleep the Mac.

This is a deliberately narrow API. [Karabiner software functions](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to/software_function/)

Launching Search Bar can therefore be native Karabiner JSON; it does not require Hammerspoon or a terminal:

```json
{
  "to": [{
    "software_function": {
      "open_application": {
        "bundle_identifier": "com.alejo.search-bar"
      }
    }
  }]
}
```

### Execute shell commands

Karabiner's `shell_command` executes an arbitrary command. The official examples use `open -a 'Safari.app'` and external shell scripts. [Karabiner shell commands](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to/shell-command/)

That unlocks:

```sh
# Launch or focus an app.
open -a "Search Bar"

# Open a URL.
open "https://example.com"

# Run an Apple Shortcut.
shortcuts run "Start work"

# Ask an application to perform an AppleScript command.
osascript -e 'tell application "Music" to playpause'

# Run any executable or maintained script.
~/.local/bin/my-automation
```

The answer to “can it perform only actions available from a terminal?” is:

- Directly, it can emit input plus the four built-in software functions.
- Indirectly, `shell_command` can invoke any automation surface reachable from a process: CLI programs, scripts, AppleScript, JavaScript for Automation, URL schemes, HTTP APIs, or another automation daemon.
- If neither macOS nor the target app exposes an API, Karabiner can still emit the same keyboard/mouse input a person would use.

This is extremely broad. The limitation is the interface around the action, not whether execution is possible.

### What becomes awkward

Consider: “When Safari is frontmost, copy the selected text, wait until the clipboard changes, transform it, send it to an API, show an error if the request fails, then paste the result without destroying the previous clipboard.”

Karabiner can trigger a shell script that does this. Karabiner itself cannot naturally express it. We would need to build the application logic elsewhere and manage:

- The script file and its runtime.
- Input and output encoding.
- Environment variables and `PATH`—Karabiner documents that shell commands receive a limited environment by default.
- Timeouts and process overlap when the shortcut is pressed twice.
- Logging and user-visible errors.
- State shared across invocations.
- Access to macOS Accessibility, Automation, or network permissions.

The Karabiner JSON would still contain only “when this input occurs, run that script.”

## Hammerspoon's action model

Hammerspoon embeds Lua and exposes macOS through modules. A hotkey runs a normal Lua function. That function can read state, branch, call helpers, start asynchronous work, store values, and handle the result.

### Applications and application-specific actions

Hammerspoon can:

- Find, launch, focus, hide, unhide, or terminate an app.
- Identify the frontmost app by bundle ID or name.
- Watch applications launch, terminate, activate, hide, or unhide.
- Enumerate an app's windows.
- Read the app's menu hierarchy.
- Find and select a menu command by path or regular expression.
- Send a constructed input event to a specific application.

These are direct APIs, not shell-command workarounds. [Hammerspoon application API](https://www.hammerspoon.org/docs/hs.application.html)

Yes: **Hammerspoon can take application-specific actions in both senses**:

1. Bind the same key to different behavior according to the frontmost app.
2. Address a particular app and ask it to focus, expose windows, or select one of its menu commands.

```lua
hs.hotkey.bind({ "cmd" }, "space", function()
  local front = hs.application.frontmostApplication()

  if front:bundleID() == "com.apple.Safari" then
    front:selectMenuItem({ "History", "Show All History" })
  else
    hs.application.launchOrFocus("Search Bar")
  end
end)
```

This code inspects state at the instant the key is pressed. Adding three applications is another branch or a lookup table, not three large JSON manipulators.

### Windows and screens

Hammerspoon can inspect and change:

- Focused, visible, minimized, hidden, and application-owned windows.
- Window position, size, screen, fullscreen state, minimization, and focus.
- Multi-monitor layouts and geometry.
- Window filters and event watchers.
- Window switchers, layouts, and tiling behavior.

This makes actions like “move the current window to the right half of the next display unless it is already there” straightforward. [Hammerspoon window API](https://www.hammerspoon.org/docs/hs.window.html)

Karabiner can trigger the menu shortcut for a window action or call an external window tool. It does not natively model windows.

### Keyboard, mouse, and event interception

Hammerspoon can:

- Bind global hotkeys.
- Observe and optionally suppress keyboard, mouse, and trackpad events.
- Emit keystrokes, text, clicks, scrolling, and constructed events.
- Send an event to a particular application.
- Inspect current modifiers, mouse buttons, and Secure Input state.

[Hammerspoon event-tap API](https://www.hammerspoon.org/docs/hs.eventtap.html)

Hammerspoon is still not a complete replacement for Karabiner. Secure Input can disable event taps, and Hammerspoon operates on macOS events rather than Karabiner's lower-level device-aware transformation pipeline. Karabiner remains better for physical-key semantics and interception that must be independent of ordinary application event handling.

### Clipboard and selected content

Hammerspoon can read and write text, URLs, images, styled text, property lists, and raw clipboard types. It can watch for clipboard changes and preserve or restore content.

This supports multi-step actions such as:

```text
send Copy → wait for clipboard change → transform content → paste → restore clipboard
```

The callback and timeout live in the same Lua process. [Hammerspoon pasteboard API](https://www.hammerspoon.org/docs/hs.pasteboard.html)

### Processes and scripts

Hammerspoon can start background processes with explicit arguments, environment, working directory, standard input, streaming output, completion callbacks, exit status, pause, terminate, and interrupt controls. [Hammerspoon task API](https://www.hammerspoon.org/docs/hs.task.html)

Karabiner's `shell_command` starts the command. Hammerspoon can supervise it.

### AppleScript and JavaScript for Automation

Hammerspoon can execute AppleScript or JavaScript for Automation directly and receive a structured success value, parsed result, and error descriptor. [Hammerspoon OSA API](https://www.hammerspoon.org/docs/hs.osascript.html)

Karabiner can run `osascript` through the shell, but result handling then belongs to an external script or process.

### Apple Shortcuts, URLs, and inter-process entry points

Hammerspoon can run Apple Shortcuts through its `hs.shortcuts` module, open URLs, register `hammerspoon://` URL handlers, and perform HTTP requests. Other apps or shell scripts can also call into named Hammerspoon handlers. [Hammerspoon module index](https://www.hammerspoon.org/docs/)

This lets Hammerspoon act as the local router:

```text
keyboard → Hammerspoon → Apple Shortcut
browser URL → Hammerspoon → app/window action
Karabiner F18 → Hammerspoon → Lua workflow
```

### Timers, watchers, and persistent state

Hammerspoon can react without a keyboard event:

- At a time or interval.
- When an app launches or becomes active.
- When a file changes.
- When screens, USB devices, Wi-Fi, power state, clipboard, or network state change.
- When a notification, URL, socket message, or callback arrives.

Lua variables remain alive between events, and `hs.settings` can persist simple state across restarts. This is the largest conceptual difference: Hammerspoon is an event-driven automation runtime, not only a remapper.

### User interface and feedback

Hammerspoon can show alerts, notifications, menus, chooser interfaces, drawing overlays, custom web views, and menu-bar items. An action can say what happened or expose a searchable command palette.

Karabiner normally produces no application-level UI beyond its configuration and EventViewer tools. A shell command can create UI through some other program.

## Direct comparison by action

| Desired behavior | Karabiner | Hammerspoon |
| --- | --- | --- |
| Remap Caps Lock to Escape | Native and ideal | Possible, but wrong layer |
| Tap Caps for Escape, hold for Control | Native and ideal | Less reliable and device-agnostic |
| Different remap in Safari | Native frontmost-app condition | Native runtime condition |
| Launch/focus Search Bar | Native `open_application` | Native `launchOrFocus` |
| Run a shell script | Native trigger, limited process supervision | Native task with callbacks, status, output, and termination |
| Select Safari's History menu | Emit its shortcut, or shell/AppleScript | Direct menu-selection API |
| Move a window to another monitor | External command or emitted shortcut | Direct window and screen APIs |
| Copy, transform, paste, restore clipboard | External script | Direct event and clipboard APIs |
| Call an HTTP API and show an error | External program | Direct asynchronous HTTP and notification APIs |
| Run AppleScript and branch on its result | External script or complicated shell | Direct structured API |
| Maintain a mode with a boolean variable | Native variable | Native Lua state |
| Maintain rich state across events | External process/file | Native tables plus persistent settings |
| React when an app launches | Not its normal trigger model | Native application watcher |
| Show a chooser or overlay | External application | Native UI modules |
| Distinguish two physical keyboards | Native and ideal | Not its strength |
| Work below ordinary app shortcut handling | Native and ideal | Higher-level event tap |

## Why the hybrid is clean

The boundary should be:

```text
Karabiner decides what the physical input means.
Hammerspoon decides what the Mac should do.
```

Example:

```text
Caps Lock + S
  → Karabiner recognizes the layer and emits F18
  → Hammerspoon binds F18
  → Hammerspoon launches Search Bar, focuses its window,
    records success, and shows an error if it cannot launch
```

F13–F20 are useful internal signals because most keyboards and applications do not use them. They prevent Karabiner from knowing application logic and prevent Hammerspoon from reconstructing complicated physical-key timing.

The hybrid does add a dependency. If a mapping only launches an app, Karabiner's built-in `open_application` is simpler. If a mapping is an ordinary global hotkey with no special physical-key behavior, Hammerspoon alone is simpler. Use both only when the mapping genuinely crosses the boundary.

## Decision rule

Put a mapping in **Karabiner** when the sentence starts with:

- “When this physical key is tapped, held, or combined…”
- “On this particular keyboard…”
- “Before the application sees the key…”
- “This key should become another key…”

Put it in **Hammerspoon** when the sentence starts with:

- “If this application or window is active…”
- “Open, focus, move, inspect, copy, fetch, wait, or show…”
- “Do these steps, then branch on the result…”
- “When an application, file, network, screen, or timer changes…”

Use **Karabiner `shell_command` alone** when the action is already a stable standalone executable and Karabiner is the natural trigger. Do not introduce Hammerspoon merely to call one command.

For the current goal—replacing `⌘ Space` with Search Bar—Hammerspoon alone is enough after disabling Spotlight's binding. Karabiner becomes useful later if we add a Hyper layer, tap/hold keys, per-device rules, or shortcuts macOS refuses to release cleanly.
<!--/ai-->
