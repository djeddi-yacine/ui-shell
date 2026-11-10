pragma Singleton
import QtQuick

// Plain substring search over the shown text of the entries. Every space-separated word must
// occur, in any order; the history order (newest first) is kept, never re-ranked.
QtObject {
    function results(items, query) {
        const words = String(query).trim().toLowerCase().split(/\s+/).filter(word => word.length > 0)
        if (words.length === 0) return items
        return items.filter(function(item) {
            const text = String(item.text ?? "").toLowerCase()
            return words.every(word => text.includes(word))
        })
    }
}
