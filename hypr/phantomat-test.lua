-- Loaded only by the nested test entrypoint; production remains opt-in.
local profile = require("profile")
profile.phantomat.enabled = true

require("nested")
