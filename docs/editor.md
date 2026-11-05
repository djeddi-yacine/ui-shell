# QML in VS Code and Codium

Open the repository root and a file such as `shell/shell.qml`. The workspace
uses Qt's official `theqtcompany.qt-qml` extension, whose dependency is
`theqtcompany.qt-core`. If QML support is missing in your editor profile,
install `theqtcompany.qt-qml` from Extensions. No extension installation or
global settings changes are performed by this workspace configuration.

The workspace selects `/usr/lib/qt6/bin/qmlls` and adds `/usr/lib/qt6/qml`,
which contains the installed QtQuick and Quickshell modules. Automatic CMake
calls are disabled because this is a standalone Quickshell configuration.
There is no need for a `.qmlls.ini` or a second QML language server.
These server options follow [Qt 6.11's QML Language Server configuration](https://doc.qt.io/qt-6.11/qtqml-tooling-qmlls.html).

After opening the workspace, use **Qt: Restart QML language server** if needed.
The **QML Language Server - ui-shell** Output channel shows server startup and
diagnostics. The workspace explicitly enables `qt-qml.qmlls.enabled` and clears
`qt-qml.qmlls.customArgs`: nonempty custom arguments override the generated
import and CMake options, including the settings above. Global editor settings
remain untouched.

## Verified locally

- The installed extension registries select Qt QML 1.16.0 for VS Code and
  1.8.0 for Code OSS/Codium; both have their Qt Core dependency installed.
- Both local manifests declare `qt-qml.qmlls.customExePath`,
  `qt-qml.qmlls.additionalImportPaths`, and `qt-qml.qmlls.useNoCMakeCalls` as
  workspace-overridable settings. Their installed launch code passes import
  paths with `-I` and the CMake option with `--no-cmake-calls`.
- Qt's `qtpaths --query` and `qmlls --version` report Qt 6.11.2. Quickshell's
  installed modules include `qmldir` and `.qmltypes` metadata.
- A headless stdio LSP check using the workspace configuration successfully
  initialized the server and completed `QtQuick.Item`, `Quickshell.ShellRoot`,
  and `Quickshell.Io.Process`. The in-memory probe had no error diagnostics.
- Opening the actual `shell/shell.qml` through LSP returned warnings about
  `PostReloadHook` and the resulting unresolved `Wallpaper.PickerShortcut`.
  These remain outside the editor configuration change. GUI extension
  activation was not tested.
