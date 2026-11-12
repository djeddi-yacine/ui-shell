-- User-owned static output policy. Names and hardware overrides belong here.
-- Set the default monitor values, then add named hardware overrides.
-- Select default-wallpaper or output-wallpaper explicitly. Output selection
-- requires a matching saved wallpaper entry; an unknown name is an error.
return {
  palette_source = {
    kind = "default-wallpaper",
    output = "",
  },
  default = {
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
    bitdepth = 8,
  },
  overrides = {},
}
