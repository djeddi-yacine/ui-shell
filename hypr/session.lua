-- Native session startup only; command composition has no event-loop dependency.
local commands = require("session.commands")

hl.on("hyprland.start", function()
  hl.exec_cmd(commands.start_wallpaper)
  hl.exec_cmd(commands.start_shell)
end)
