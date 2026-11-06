.pragma library

// Patchbay decisions that need no scene: which nodes are sources or destinations,
// where their rows sit, and the curve between two rows. The cabling look (control
// points pulled out horizontally by half the distance, clamped) follows Ziryt's
// omarchy-plugin-audio.

var ROW = 54
var GAP = 10

// A class as people say it.
function kindLabel(mediaClass) {
  if (mediaClass.startsWith("Stream/Output")) return "Playback"
  if (mediaClass.startsWith("Stream/Input")) return "Recording"
  if (mediaClass.startsWith("Audio/Sink")) return "Output"
  if (mediaClass.startsWith("Audio/Source")) return "Input"
  return mediaClass
}

function step() { return ROW + GAP }
function rowCenter(index) { return index * step() + ROW / 2 }
function rowTop(index) { return index * step() }

function audioPorts(ports, node, direction) {
  return ports.filter(port => port.node === node && port.direction === direction && port.audio)
}

// Sources have audio output ports (playback streams, inputs, and a sink's monitor
// only when something is linked to it); destinations have audio input ports
// (sinks and recording streams). Applications come first, then devices.
function split(nodes, ports, links) {
  const linkedFrom = new Set(links.map(link => link.outNode))
  const kindRank = node => node.class.startsWith("Stream/") ? 0 : 1
  const byLabel = (a, b) => kindRank(a) - kindRank(b) || a.label.localeCompare(b.label) || a.id - b.id
  const sources = nodes.filter(node => audioPorts(ports, node.id, "output").length > 0
    && (!node.class.startsWith("Audio/Sink") || linkedFrom.has(node.id))
    && node.class !== "Stream/Input/Audio").sort(byLabel)
  const destinations = nodes.filter(node => audioPorts(ports, node.id, "input").length > 0
    && node.class !== "Stream/Output/Audio"
    && !node.class.startsWith("Audio/Source")).sort((a, b) => {
      const rank = node => node.class.startsWith("Audio/Sink") ? 0 : 1
      return rank(a) - rank(b) || a.label.localeCompare(b.label) || a.id - b.id
    })
  return { sources: sources, destinations: destinations }
}

// One edge per source/destination pair, however many channels are linked.
function edges(links, sources, destinations) {
  const from = new Map(sources.map((node, index) => [node.id, index]))
  const to = new Map(destinations.map((node, index) => [node.id, index]))
  const seen = new Map()
  for (const link of links) {
    if (!from.has(link.outNode) || !to.has(link.inNode)) continue
    const key = link.outNode + ":" + link.inNode
    const edge = seen.get(key) ?? { out: link.outNode, in: link.inNode, from: from.get(link.outNode), to: to.get(link.inNode), count: 0 }
    edge.count += 1
    seen.set(key, edge)
  }
  return Array.from(seen.values())
}

function linked(edgeList, out, into) {
  return edgeList.some(edge => edge.out === out && edge.in === into)
}

function controlPoints(x1, y1, x2, y2) {
  const pull = Math.max(40, Math.min(160, Math.abs(x2 - x1) * 0.5))
  return { c1x: x1 + pull, c1y: y1, c2x: x2 - pull, c2y: y2 }
}
