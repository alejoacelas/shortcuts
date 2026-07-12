<!--ai-->
# Remapping shortcuts on macOS

## Recommendation

Use **Hammerspoon as the source of truth**, with **Karabiner-Elements only for low-level key transformations** that Hammerspoon cannot express cleanly.

See [Karabiner versus Hammerspoon](karabiner-vs-hammerspoon.md) for the detailed capability map.

Expected outcome:

- Initial setup: 30–60 minutes, including macOS permissions and a version-controlled config.
- Each ordinary mapping afterward: about 1–5 lines of Lua and 1–3 minutes.
- Shortcut response: effectively immediate; normally below the roughly 50 ms where input starts to feel delayed. [This is an estimate to verify on the installed setup.]
- Cost: free and open source.
- Scope: global shortcuts, app-specific shortcuts, app launching/focusing, menu commands, shell commands, URLs, window control, and multi-step automation.
- Maintenance: one config in `~/.hammerspoon/init.lua`, reloadable when saved.

Hammerspoon is the best center because a shortcut can call real code instead of being limited to another keystroke. Its official guide demonstrates global hotkeys, application events, menu selection, AppleScript, window management, and automatic config reloads. [Hammerspoon guide](https://www.hammerspoon.org/go/)

Karabiner belongs underneath it when we want a Hyper key, tap-versus-hold behavior, device-specific rules, or interception before an app sees the key. It supports app conditions, arbitrary key transformations, and shell commands, but large configurations become verbose JSON. [Karabiner complex modifications](https://karabiner-elements.pqrs.org/docs/manual/configuration/configure-complex-modifications/)

## Replacing `⌘ Space`

`⌘ Space` currently belongs to Spotlight. The clean path is:

1. Disable or change Spotlight's shortcut in **System Settings → Keyboard → Keyboard Shortcuts → Spotlight**.
2. Bind `⌘ Space` in Hammerspoon to launch or focus Search Bar.
3. Keep a recovery shortcut for Spotlight for the first week, such as `⌥ Space`.

Apple documents `⌘ Space` as Spotlight's default. macOS must release the binding before another tool can own it reliably. [Apple's shortcut reference](https://support.apple.com/en-us/102650)

The Hammerspoon mapping would look roughly like:

```lua
hs.hotkey.bind({ "cmd" }, "space", function()
  hs.application.launchOrFocus("Search Bar")
end)
```

This should take under five minutes after Hammerspoon has Accessibility permission. It will work globally rather than only inside one app.

## Options

| Option | Setup | New mapping | Best at | Hard limit | Cost |
| --- | ---: | ---: | --- | --- | --- |
| **Hammerspoon** | 30–60 min | 1–3 min | One programmable, version-controlled automation layer | Requires writing small amounts of Lua | Free |
| **Karabiner-Elements** | 20–45 min | 5–20 min for custom rules | Low-level remapping, Hyper keys, tap/hold, keyboard- and app-specific interception | Actions and application automation are awkward in JSON | Free |
| **BetterTouchTool** | 15–30 min | 1–3 min | Broad GUI configuration for keys, mouse, trackpad, windows, and macros | Proprietary config is harder to review and generate than text | Paid |
| **skhd** | 15–30 min | 1–2 min | Minimal text-configured hotkeys that run shell commands | Narrower action model; complex behavior moves into scripts | Free |
| **macOS App Shortcuts** | 2–5 min | 1–2 min | Reassigning an existing menu item in one app | Only menu commands; exact menu title required; conflicts can fail | Built in |
| **Apple Shortcuts** | 5–20 min | 3–15 min | Multi-app workflows with a graphical editor | Some system shortcuts are reserved; remapping existing keys is not its strength | Built in |

Times are working estimates for a technically comfortable user, not vendor benchmarks. The decision changes if avoiding code matters more than inspectability: choose BetterTouchTool in that case.

### Hammerspoon

Use it when a key should do something:

```lua
-- Launch or focus an app.
hs.hotkey.bind({ "cmd", "alt" }, "S", function()
  hs.application.launchOrFocus("Search Bar")
end)

-- Make the same key app-specific.
hs.hotkey.bind({ "ctrl" }, "J", function()
  local app = hs.application.frontmostApplication():name()
  if app == "Safari" then
    hs.eventtap.keyStroke({ "cmd" }, "l")
  else
    hs.eventtap.keyStroke({}, "down")
  end
end)
```

The configuration is ordinary text, so we can generate mappings, review diffs, test helper functions, and commit every change. Hammerspoon can also select application menu items directly, which is usually more stable than replaying several keys.

### Karabiner-Elements

Use it when a physical key should become another input before normal shortcut handling:

- Caps Lock becomes Hyper (`⌘⌥⌃⇧`).
- Caps Lock tapped alone sends Escape but held acts as Control.
- A rule applies only to a particular keyboard or frontmost app.
- A shortcut must be swallowed before an app receives it.

Karabiner can launch shell commands itself, but a cleaner division is:

```text
physical key → Karabiner emits unused key such as F18 → Hammerspoon performs action
```

That keeps timing-sensitive keyboard logic in Karabiner and readable application logic in Hammerspoon.

### BetterTouchTool

Choose this if the desired outcome is the broadest automation with the least code. It supports app-specific keyboard triggers and actions, plus trackpad, mouse, window, and macro features. [BetterTouchTool keyboard documentation](https://docs.folivora.ai/docs/keyboard-shortcuts/overview/)

The tradeoff is not responsiveness. It is ownership: the configuration lives in a proprietary application's model rather than a small text program we fully control.

### skhd

Choose this if almost every shortcut should execute a shell command and we want the smallest configuration surface. A mapping is concise, but application state, menus, window inspection, and multi-step logic require external scripts. It fits a terminal-centered setup better than a general Mac automation layer.

### Built-in macOS options

**App Shortcuts** can reassign an existing menu command for one app or all apps. It cannot open arbitrary applications or create general actions. The menu title must match exactly. [Apple App Shortcuts guide](https://support.apple.com/en-ie/guide/mac-help/mchlp2271/mac)

**Apple Shortcuts** is useful as an action destination. Hammerspoon can bind a key that runs a named Apple Shortcut, while Shortcuts handles the visual multi-step workflow. Apple also lets a Shortcut receive a keyboard shortcut directly, but warns that reserved combinations cannot be overridden. [Apple Shortcuts guide](https://support.apple.com/en-ie/guide/shortcuts-mac/-apd163eb9f95/mac)

## What we could map

The recommended stack can cover:

- Launch or focus Search Bar with `⌘ Space`.
- Give the same key different meanings in different apps.
- Replace inconvenient default shortcuts without changing each app's settings.
- Create a Hyper layer, giving most letter keys an unused global namespace.
- Run shell commands, Apple Shortcuts, AppleScript, URLs, or application menu items.
- Move and resize windows.
- Turn sequences or tap/hold gestures into commands.
- Keep the entire mapping in a public Git repository.

## Proposed implementation

If we proceed, put the working configuration in this repository:

```text
shortcuts/
├── README.md
├── options.md
├── hammerspoon/
│   ├── init.lua
│   ├── apps.lua
│   └── windows.lua
└── karabiner/
    └── complex_modifications/
```

Start with Hammerspoon only and three mappings: `⌘ Space` for Search Bar, one app launcher, and one app-specific remap. Add Karabiner only when a concrete mapping needs lower-level interception. This keeps the first setup small without closing off the more ambitious system.
<!--/ai-->
