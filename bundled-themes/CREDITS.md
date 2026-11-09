# Bundled themes

The 500 Theme definitions in this directory (100 palettes × 5 variants: dark, day,
high-contrast, day-high-contrast, oled) are the colors of **100-themes** by
**Bjarne Øverli** ([@bjarneo](https://github.com/bjarneo)):

- Source: <https://github.com/bjarneo/100-themes> (gallery: <https://bjarneo.github.io/100-themes>)
- Imported from commit `3bc337833cc1025a66b68e4d8c06d2899fd1d860`

The palettes, names and colors are his work. Only the `config.ini` conversion
(schema 2, semantic roles mapped positive=green, warning=yellow, negative=red) is
ours; wallpapers and icons from that repo are not included. The upstream repository
ships no license file at that commit; if the author asks, these files are removed.

Regenerate (maintainers only): `make dev-bundle-themes`. Runtime never reads `refs/`.
