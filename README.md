---
human_edit_tracking:
  enabled: true
  history: []
---
# Shortcuts

I want one flexible, version-controlled place to decide what every keyboard shortcut does on my Mac.

## Use it on a Mac

```sh
git clone https://github.com/alejoacelas/shortcuts.git
cd shortcuts
./setup.sh
```

The script installs Hammerspoon and Karabiner-Elements with Homebrew, links this repository's Hammerspoon configuration, and exposes the optional Karabiner rules in its rule picker. Karabiner's installer asks for an administrator password. macOS then requires the manual permissions in [Finish setup](#finish-setup).

The configuration starts conservatively:

- `⌃⌥⌘H` shows a confirmation that Hammerspoon works.
- `⌃⌥⌘R` reloads the Hammerspoon configuration.
- No existing system shortcut or physical key is changed automatically.
- An optional “Caps Lock: Escape when tapped, Hyper when held” Karabiner rule is available but disabled until I enable it.

## Finish setup

1. Open Hammerspoon. Approve **System Settings → Privacy & Security → Accessibility → Hammerspoon**.
2. Choose **Reload Config** from Hammerspoon's menu-bar icon. Press `⌃⌥⌘H`; a “Shortcuts are working” alert should appear.
3. Open Karabiner-Elements. Follow its prompts for the background services, Driver Extension, Input Monitoring, and login item. The exact prompts vary by macOS version; Karabiner's app shows anything still missing.
4. In Karabiner-Elements, open **Complex Modifications → Add predefined rule**. Enable the local rule only if I want Caps Lock to become Escape/Hyper.
5. Test changed keys in Karabiner-EventViewer before relying on them.

After Hammerspoon reloads, this terminal check should print `true`:

```sh
hs -c 'return hs.accessibilityState()'
```

If Karabiner is not installed yet:

```sh
brew install --cask karabiner-elements
```

That command invokes Apple's installer and therefore needs the Mac administrator password.

## Read before expanding it

- [Choosing a shortcut system](docs/choosing-a-shortcut-system.md) compares the practical options and recommends the initial architecture.
- [Karabiner versus Hammerspoon](docs/karabiner-vs-hammerspoon.md) explains exactly what each can observe and do, including application-specific actions.

## Add a mapping

Put application and workflow logic in `hammerspoon/`. Put physical-key timing, device rules, and low-level transformations in `karabiner/complex_modifications/`.

After changing Lua, press `⌃⌥⌘R`. After changing a Karabiner rule, disable and re-enable it in Karabiner-Elements. Commit and push the configuration so another Mac can reproduce it with `./setup.sh`.

`setup.sh` refuses to replace an existing non-symlinked configuration. Move or merge that file deliberately, then rerun setup; the script will not discard it.
