require("hs.ipc")

hyper = { "ctrl", "alt", "shift", "cmd" }
local setupShortcut = { "ctrl", "alt", "cmd" }

hs.hotkey.bind(setupShortcut, "H", "Confirm shortcuts setup", function()
  hs.alert.show("Shortcuts are working")
end)

hs.hotkey.bind(setupShortcut, "R", "Reload shortcuts configuration", function()
  hs.reload()
end)

hs.alert.show("Shortcuts loaded")
