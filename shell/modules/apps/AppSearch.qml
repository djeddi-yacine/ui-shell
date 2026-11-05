import QtQuick

QtObject {
    id: root
    required property var entries
    required property list<string> hiddenEntryIds
    required property list<string> searchFields
    // Normalize/sort only when native entries or explicit configuration change.
    readonly property var index: entries.filter(entry => !entry.noDisplay && !hiddenEntryIds.includes(entry.id))
        .map(function(entry) {
            return { entry: entry, fields: root.searchFields.map(field => {
                const value = entry[field]
                return String(Array.isArray(value) ? value.join(" ") : value || "").toLowerCase()
            }) }
        }).sort((a, b) => a.entry.name.localeCompare(b.entry.name) || a.entry.id.localeCompare(b.entry.id))

    function score(text, token) {
        if (text === token) return 0
        if (text.startsWith(token)) return 1
        const substring = text.indexOf(token)
        if (substring >= 0) return 2 + substring / Math.max(1, text.length)
        let position = 0
        let gaps = 0
        for (let index = 0; index < token.length; index++) {
            const found = text.indexOf(token[index], position)
            if (found < 0) return Infinity
            gaps += found - position
            position = found + 1
        }
        return 4 + gaps / Math.max(1, text.length)
    }

    function results(query) {
        const normalized = query.trim().toLowerCase()
        if (!normalized) return index.map(item => item.entry)
        const tokens = normalized.split(/\s+/)
        const matches = []
        for (let order = 0; order < index.length; order++) {
            const item = index[order]
            let rank = 0
            for (const token of tokens) {
                let best = Infinity
                for (let field = 0; field < item.fields.length; field++)
                    best = Math.min(best, score(item.fields[field], token) + field)
                rank += best
            }
            if (isFinite(rank)) matches.push({ entry: item.entry, rank: rank, order: order })
        }
        return matches.sort((a, b) => a.rank - b.rank || a.order - b.order).map(item => item.entry)
    }
}
