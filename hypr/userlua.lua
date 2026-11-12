-- Loads one user-editable Lua file. The user directory comes from the runtime
-- manifest (`paths.userLua`); a missing user file selects the shipped default
-- in hypr/default/. Files are never merged. An error in a user file stops the
-- Hyprland parse and names the file.
local runtime = require("runtime")

local function readable(path)
  local handle = io.open(path, "r")
  if not handle then return false end
  handle:close()
  return true
end

local M = {}

function M.load(name)
  assert(type(name) == "string" and name:match("^[a-z_]+$"),
    "userlua: name must match [a-z_]+")
  local directory = runtime.paths.userLua
  assert(type(directory) == "string" and directory:sub(1, 1) == "/",
    "userlua: runtime paths.userLua must be an absolute path")
  local user = directory .. "/" .. name .. ".lua"
  local path = readable(user) and user or (runtime.paths.hypr .. "/default/" .. name .. ".lua")
  local chunk, message = loadfile(path)
  assert(chunk, "userlua: cannot load " .. path .. ": " .. tostring(message))
  return chunk()
end

return M
