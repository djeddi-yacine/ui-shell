---
id: toolkit-sandbox
title: "Rice demo apps run in a toolkit sandbox: private home, masked host theming, engine output as the only theme input"
category: decision
status: active
tags: [theme, tests, sandbox, gtk, qt]
created: "2026-11-14T04:59:53"
updated: "2026-11-14T05:08:12"
---

<!-- compiled_truth -->
# Decision (owner, 2026-11-14)

Rice demo apps (projects/rice-*/demo) are checked inside a toolkit sandbox so a demo shows its toolkit exactly as an engine themes it, with no host user overrides. It follows [[isolated-nested-test-environment]] (Bubblewrap, private HOME and XDG dirs, read-only system, explicit sharing, explicit environment) but is development tooling for the engines, not a shell test.

- **Code:** one new standalone script `tools/scripts/toolkit-sandbox` plus one static user-owned config in the nested.conf style, with each toolkit's environment defined in one place. `tests/scripts/test-nested` is left unchanged (no shared helper extracted) so `make test-env` cannot regress.
- **D-Bus:** a private session bus (`dbus-run-session` with `tests/session-bus.conf`, no service directories), so GtkApplication/AdwApplication register while no portal, a11y or other service can start. The host bus is never shared, so the host portal color-scheme cannot leak in.
- **X11 (Qt4, GTK2):** share only the host Xwayland path socket `/tmp/.X11-unix/X0` with `DISPLAY=:0`. Hyprland's Xwayland runs without `-auth`, so no Xauthority entry exists to share. Known leak path: X resources (`RESOURCE_MANAGER`) or XSETTINGS (`_XSETTINGS_S0`, e.g. from xsettingsd) on :0 would reach Qt4/GTK2, so the sandbox refuses to start an X11 toolkit when either is set. Owner rejected a private Xwayland for now.
- **System files:** /usr and /etc read-only, and host theming masked with empty tmpfs: toolkit config dirs (/etc/xdg, /etc/gtk-2.0, /etc/gtk-3.0, /etc/gtk-4.0) AND installed themes and theme plugins (/usr/share/themes, Kvantum, color-schemes, qt5ct/qt6ct data, Qt styles/platformthemes/wayland-decoration-client plugin dirs, GTK2 engines dir). The empty sandbox therefore shows the toolkit's raw built-in default.
- **Engine input:** an engine's output is the only thing that changes the look. It is supplied as a theme directory laid out like the private home, copied into it at start, plus explicit environment from an allowlist per toolkit.


## Timeline

- time: 2026-11-14T04:59:53
  kind: decision
  summary: "Created this page: Rice demo apps run in a toolkit sandbox: private home, masked host theming, engine output as the only theme input"
  source: owner chat 2026-11-14
  affects: [toolkit-sandbox]

- time: 2026-11-14T04:59:53
  kind: decision
  summary: Owner choices for the toolkit sandbox
  source: owner chat 2026-11-14
  affects: [toolkit-sandbox]

- time: 2026-11-14T05:08:12
  kind: evidence
  summary: "Built tools/scripts/toolkit-sandbox + tools/toolkit-sandbox.conf + make toolkit-env. strace -ff on all 7 toolkits: 0 lookups of the real home, home empty at start, masked dirs seen only as empty mount points, /etc reads limited to fonts/libc/NSS/ssl/vulkan/fstab. A poisoned scratch HOME plus poisoned caller env (GTK_THEME, GTK2_RC_FILES, QT_STYLE_OVERRIDE, QT_QPA_PLATFORMTHEME) is read outside the sandbox (control) and never inside. Engine input = --theme-dir copied into the private home plus an allowlisted sandbox.env. Qt4 needs QT_X11_NO_MITSHM=1 (private IPC namespace)."
  source: session 2026-11-14 verification
  affects: [toolkit-sandbox]
