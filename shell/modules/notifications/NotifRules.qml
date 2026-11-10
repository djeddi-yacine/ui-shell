import QtQuick
import "NotifMatch.js" as Matcher

// The user's rules, read from component settings by a QmlSettingsFile made in shell.qml.
// First matching rule wins; no rules file means no rules.
QtObject {
    required property var file
    readonly property var rules: file.values.rules || []
    readonly property string error: file.error
    function match(entry) {
        for (const rule of rules) if (Matcher.match(rule, entry)) return rule
        return null
    }
}
