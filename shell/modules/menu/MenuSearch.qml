pragma Singleton
import QtQuick

// Plain substring search over the lines of a menu request. Every space-separated word must occur,
// in any order, ignoring case; the order the caller sent is kept, never re-ranked. The same rule
// as the clipboard search, on plain strings.
QtObject {
    // Indexes into `lines` of the lines that match, in order.
    function matches(lines, query) {
        const words = String(query).trim().toLowerCase().split(/\s+/).filter(word => word.length > 0)
        const found = []
        for (let index = 0; index < lines.length; index++) {
            const text = String(lines[index]).toLowerCase()
            if (words.every(word => text.includes(word))) found.push(index)
        }
        return found
    }
}
