import QtQuick
import QtTest
import "../shell/modules/audio/PatchLogic.js" as Logic

Item {
    id: root
    width: 10
    height: 10

    readonly property var nodes: [
        { id: 1, label: "Firefox", class: "Stream/Output/Audio", detail: "Video", icon: "" },
        { id: 2, label: "Mic", class: "Audio/Source", detail: "", icon: "" },
        { id: 3, label: "Speakers", class: "Audio/Sink", detail: "", icon: "" },
        { id: 4, label: "Recorder", class: "Stream/Input/Audio", detail: "", icon: "" },
        { id: 5, label: "Alpha", class: "Stream/Output/Audio", detail: "", icon: "" },
        { id: 6, label: "Midi-less", class: "Audio/Sink", detail: "", icon: "" },
        { id: 7, label: "No ports", class: "Stream/Output/Audio", detail: "", icon: "" }
    ]
    function port(id, node, direction, channel) { return { id: id, node: node, direction: direction, channel: channel, audio: true } }
    readonly property var ports: [
        port(10, 1, "output", "FL"), port(11, 1, "output", "FR"),
        port(12, 2, "output", "MONO"),
        port(13, 3, "input", "FL"), port(14, 3, "input", "FR"), port(15, 3, "output", "FL"),
        port(16, 4, "input", "FL"),
        port(17, 5, "output", "FL"),
        port(18, 6, "input", "FL"), port(19, 6, "output", "FL")
    ]
    readonly property var links: [
        { id: 100, out: 10, in: 13, outNode: 1, inNode: 3 },
        { id: 101, out: 11, in: 14, outNode: 1, inNode: 3 },
        { id: 102, out: 12, in: 16, outNode: 2, inNode: 4 }
    ]

    TestCase {
        // Explicit numbers: the logic has none of its own, the view feeds it the theme's.
        readonly property var metrics: ({ row: 54, gap: 10, pullMinimum: 40, pullMaximum: 160, pullFraction: 0.5 })
        name: "PatchLogic"

        function ids(list) { return list.map(node => node.id) }

        function test_splitSourcesAndDestinations() {
            const parts = Logic.split(root.nodes, root.ports, root.links)
            // Applications first, then devices; a node with no audio ports is not drawn;
            // a sink's monitor is a source only once something is linked from it.
            compare(ids(parts.sources), [5, 1, 2])
            compare(ids(parts.destinations), [6, 3, 4])
        }

        function test_aLinkedSinkMonitorBecomesASource() {
            const linked = root.links.concat([{ id: 103, out: 15, in: 16, outNode: 3, inNode: 4 }])
            const parts = Logic.split(root.nodes, root.ports, linked)
            verify(ids(parts.sources).includes(3), "speakers' monitor is a source once linked")
            verify(!ids(Logic.split(root.nodes, root.ports, root.links).sources).includes(3))
        }

        function test_edgesAreOnePerNodePairWithChannelCount() {
            const parts = Logic.split(root.nodes, root.ports, root.links)
            const edges = Logic.edges(root.links, parts.sources, parts.destinations)
            compare(edges.length, 2)
            const firefox = edges.find(edge => edge.out === 1)
            compare(firefox.in, 3)
            compare(firefox.count, 2, "two linked channels are one edge")
            compare(firefox.from, parts.sources.findIndex(node => node.id === 1))
            compare(firefox.to, parts.destinations.findIndex(node => node.id === 3))
            verify(Logic.linked(edges, 1, 3))
            verify(!Logic.linked(edges, 1, 4))
        }

        function test_linksToUnlistedNodesAreIgnored() {
            const parts = Logic.split(root.nodes, root.ports, root.links)
            const edges = Logic.edges(root.links.concat([{ id: 9, out: 1, in: 1, outNode: 1, inNode: 99 }]), parts.sources, parts.destinations)
            compare(edges.length, 2)
        }

        function test_rowGeometry() {
            compare(Logic.step(metrics), metrics.row + metrics.gap)
            compare(Logic.rowTop(metrics, 2), 2 * Logic.step(metrics))
            compare(Logic.rowCenter(metrics, 0), metrics.row / 2)
        }

        function test_curveControlPointsAreClamped() {
            const near = Logic.controlPoints(metrics, 0, 0, 20, 100)
            compare(near.c1x, 40, "short links still bow out by at least 40")
            const far = Logic.controlPoints(metrics, 0, 0, 2000, 100)
            compare(far.c1x, 160, "long links bow out by at most 160")
            const middle = Logic.controlPoints(metrics, 0, 10, 200, 90)
            compare(middle.c1x, 100)
            compare(middle.c2x, 100)
            compare(middle.c1y, 10)
            compare(middle.c2y, 90)
        }

        function test_kindLabelsAreHumanWords() {
            compare(Logic.kindLabel("Stream/Output/Audio"), "Playback")
            compare(Logic.kindLabel("Stream/Input/Audio"), "Recording")
            compare(Logic.kindLabel("Audio/Sink"), "Output")
            compare(Logic.kindLabel("Audio/Sink/Virtual"), "Output")
            compare(Logic.kindLabel("Audio/Source"), "Input")
            compare(Logic.kindLabel("Something/Else"), "Something/Else")
        }
    }
}
