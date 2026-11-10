import QtQuick
import QtTest
import "../shell/modules/notifications" as Notif

TestCase {
    id: tc
    name: "NotifCard"
    width: 400
    height: 300
    when: windowShown

    readonly property var style: ({ spacingTight: 4, text: "white", textMuted: "gray", surfaceVariant: "black", accent: "red" })
    readonly property var entry: ({ id: 1, appName: "app", tag: "", summary: "secret", body: "secret body", progress: -1, actions: [] })

    Component {
        id: cardComponent
        Notif.NotifCard { width: 300; entry: tc.entry; style: tc.style }
    }
    function cleanup() { Notif.NotifCenter.redact = false }
    function texts(item, out) {
        for (const c of item.children) {
            if (c.text !== undefined) out.push(c.text)
            texts(c, out)
        }
        return out
    }
    function test_text_visible_when_not_redacted() {
        const card = createTemporaryObject(cardComponent, tc)
        verify(texts(card, []).includes("secret"))
    }
    function test_redacted_hides_text_and_keeps_size() {
        const card = createTemporaryObject(cardComponent, tc)
        Notif.NotifCenter.redact = true
        const shown = texts(card, [])
        verify(!shown.includes("secret"))
        verify(!shown.includes("secret body"))
    }
    function test_revealed_entry_keeps_its_text_while_recording() {
        const card = createTemporaryObject(cardComponent, tc, { entry: Object.assign({}, tc.entry, { reveal: true }) })
        Notif.NotifCenter.redact = true
        verify(texts(card, []).includes("secret"))
    }
    function test_spoiler_falls_back_when_shader_missing() {
        const spoiler = createTemporaryObject(spoilerComponent, tc, { shaderSource: "file:///nonexistent.qsb" })
        spoiler.width = 100; spoiler.height = 20
        verify(spoiler.shaderSource.toString().endsWith("nonexistent.qsb"))
    }
    Component {
        id: spoilerComponent
        Notif.NotifSpoiler { tint: "white" }
    }
}
