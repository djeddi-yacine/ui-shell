import QtQuick

// Stands in for MediaArtRunner: records what was asked and answers when the test says so.
QtObject {
    property var calls: []
    property int kills: 0
    signal finished(string runKey, var result)
    function run(step, flags, input, runKey) { calls = calls.concat([{ step: step, flags: flags, input: input, runKey: runKey }]) }
    function kill() { kills++ }
    // The last call that is neither the cache clean-up nor the tool check.
    function last() { const list = calls.filter(call => call.step !== "prune" && call.step !== "capabilities"); return list.length ? list[list.length - 1] : null }
    function reply(result) { const call = last(); finished(call.runKey, result) }
}
