-- Standard bootstrap only. All remaining addresses come from config.ini.
local cache_home = os.getenv("XDG_CACHE_HOME") or (assert(os.getenv("HOME")) .. "/.cache")
local path = os.getenv("UI_SHELL_RUNTIME_LUA") or (cache_home .. "/ui-shell/runtime/config.lua")
local runtime = dofile(path)
assert(runtime.schema == 1, "ui-shell: unsupported runtime schema; regenerate config.ini projections")
return runtime
