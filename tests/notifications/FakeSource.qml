import QtQuick

// Stands in for NotifSource in tests: the test emits entries and reads what the center sent back.
QtObject {
    signal received(var entry)
    signal updated(var entry)
    signal closed(int id)
    property var dismissed: []
    property var invoked: []
    function dismiss(id) { dismissed = dismissed.concat([id]) }
    function invoke(id, identifier) { invoked = invoked.concat([{ id: id, identifier: identifier }]) }
}
