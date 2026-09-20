# Shortcut configuration decisions

## Core decisions

### Division of responsibility

- [Use Hammerspoon for workflows and Karabiner for physical-key behavior](#decision-1).

### Safe installation

- [Start without changing existing system keys](#decision-2).
- [Refuse to overwrite an existing regular configuration file](#decision-3).

## Details

<a id="decision-1"></a>

### Use Hammerspoon for workflows and Karabiner for physical-key behavior

Application logic belongs in Lua; timing, device rules and low-level transformations belong in Karabiner rules. Preserve this split so additions do not become overlapping implementations of the same shortcut. See [README.md](README.md).

<a id="decision-2"></a>

### Start without changing existing system keys

The initial configuration only supplies confirmation/reload shortcuts. Caps Lock Escape/Hyper is optional and remains disabled until chosen; installation and permissions do not imply permission to activate remappings. See [hammerspoon/init.lua](hammerspoon/init.lua).

<a id="decision-3"></a>

### Refuse to overwrite an existing regular configuration file

setup.sh links repository configuration but stops at a non-symlink target. Merge or move an existing user file deliberately instead of making setup destructive; macOS permissions and administrator installation steps remain explicit. See [setup.sh](setup.sh). History inspected: [9315e53](https://github.com/alejoacelas/shortcuts/commit/9315e53).
