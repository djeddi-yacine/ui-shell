import QtQuick
import QtTest

import "../shell/tests/clipboard" as Clipboard

TestCase {
    name: "ClipboardSearch"

    readonly property var items: [
        { line: "3\tAlpha Beta", text: "Alpha Beta" },
        { line: "2\tbeta gamma", text: "beta gamma" },
        { line: "1\tdelta", text: "delta" },
        { line: "0\tno text field" }
    ]

    function texts(list) { return list.map(item => item.line) }

    function test_empty_query_keeps_every_entry_in_order() {
        compare(texts(Clipboard.ClipboardSearch.results(items, "")), texts(items))
        compare(texts(Clipboard.ClipboardSearch.results(items, "   ")), texts(items))
    }
    function test_search_is_case_insensitive_substring() {
        compare(texts(Clipboard.ClipboardSearch.results(items, "BET")), [items[0].line, items[1].line])
    }
    function test_every_word_must_match_in_any_order() {
        compare(texts(Clipboard.ClipboardSearch.results(items, "gamma beta")), [items[1].line])
        compare(texts(Clipboard.ClipboardSearch.results(items, "alpha gamma")), [])
    }
    function test_history_order_is_kept() {
        const found = Clipboard.ClipboardSearch.results(items, "a")
        compare(texts(found), [items[0].line, items[1].line, items[2].line])
    }
    function test_entry_without_text_never_matches_a_word() {
        compare(texts(Clipboard.ClipboardSearch.results(items, "field")), [])
    }
}
