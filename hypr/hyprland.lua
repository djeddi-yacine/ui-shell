-- Production Hyprland entry point.
--
-- Every require below has one concern. Keep this file a map, not a second
-- configuration layer.
require("monitors")
require("input")
require("appearance")
require("rules")
require("borders")
require("binds.windows")
require("binds.workspaces")
require("binds.groups")
-- Keep Hyprland layouts available in Canvas mode too. Canvas activation is
-- explicit; until then normal workspace tiling and these layout choices work.
require("binds.layouts")
require("binds.hardware")
require("binds.shell")
require("phantomat")
require("session")
