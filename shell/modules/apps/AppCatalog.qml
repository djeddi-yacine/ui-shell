pragma Singleton
import QtQuick
import Quickshell
import "../../config" as Config

AppSearch {
    entries: DesktopEntries.applications.values
    hiddenEntryIds: Config.AppLauncher.hiddenEntryIds
    searchFields: Config.AppLauncher.searchFields
}
