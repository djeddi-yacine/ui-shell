-- Standard bootstrap only. All remaining addresses come from manifest.ini and settings.ini.
local cache_home = os.getenv("XDG_CACHE_HOME") or (assert(os.getenv("HOME")) .. "/.cache")
local path = os.getenv("UI_SHELL_RUNTIME_LUA") or (cache_home .. "/ui-shell/runtime/config.lua")

-- The generated runtime must belong to the release that is parsing it: the stamp beside
-- config.lua is written by scripts/prepare-runtime, the release's own RELEASE file is its id.
local function stamp(file)
  local handle = io.open(file, "r")
  if not handle then return nil end
  local line = handle:read("l")
  handle:close()
  return line
end
local release_root = debug.getinfo(1, "S").source:match("^@(/.*)/hypr/runtime%.lua$")
assert(release_root, "ui-shell: hypr/runtime.lua must be loaded by its absolute path inside a release")
local running = stamp(release_root .. "/RELEASE")
local generated = stamp(path:match("^(.*)/[^/]+$") .. "/RELEASE")
assert(running and generated and running == generated,
  "ui-shell: the generated runtime (" .. tostring(generated) .. ") does not match this release ("
  .. tostring(running) .. "); start the session with scripts/start-session")

local runtime = dofile(path)
assert(runtime.schema == 1, "ui-shell: unsupported runtime schema; regenerate with scripts/start-session")
return runtime
