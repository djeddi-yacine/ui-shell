import QtQuick
import QtTest

import "../shell/tests/apps" as Apps

Item {
    id: root
    width: 200
    height: 120

    Component {
        id: searchComponent
        Apps.AppSearch {}
    }

    TestCase {
        name: "AppSearch"
        when: windowShown

        function createSearch(entries, hiddenEntryIds, searchFields) {
            const search = createTemporaryObject(searchComponent, root, {
                entries: entries,
                hiddenEntryIds: hiddenEntryIds || [],
                searchFields: searchFields || ["name", "genericName", "keywords"]
            })
            verify(!!search, "Component exists")
            return search
        }

        function ids(entries) {
            return entries.map(entry => entry.id)
        }

        function entry(id, name, genericName, keywords, noDisplay) {
            return {
                id: id,
                name: name,
                genericName: genericName || "",
                keywords: keywords || [],
                noDisplay: noDisplay || false
            }
        }

        function test_alphabeticalOrderAndNameTiesUseId() {
            const search = createSearch([
                entry("zeta", "Zulu"),
                entry("same-z", "Alpha"),
                entry("beta", "Beta"),
                entry("same-a", "Alpha")
            ])

            compare(ids(search.results("")), ["same-a", "same-z", "beta", "zeta"])
        }

        function test_queryTrimsWhitespaceAndIgnoresCase() {
            const search = createSearch([
                entry("calc", "Calculator"),
                entry("calendar", "Calendar")
            ])

            compare(ids(search.results("  cAlC  ")), ["calc"])
        }

        function test_exactThenPrefixThenFuzzy() {
            const search = createSearch([
                entry("fuzzy", "Axxbxxc"),
                entry("prefix", "Abcd"),
                entry("exact", "Abc")
            ])

            compare(ids(search.results("abc")), ["exact", "prefix", "fuzzy"])
        }

        function test_allTokensCanMatchAcrossFields() {
            const search = createSearch([
                entry("match", "Photo Suite", "Editor", ["retouch"]),
                entry("missing", "Photo Suite", "Editor", ["drawing"])
            ])

            compare(ids(search.results("photo retouch")), ["match"])
        }

        function test_subsequenceWithSmallerGapsRanksFirst() {
            const search = createSearch([
                entry("wide", "a---b---c"),
                entry("tight", "a-b-c")
            ])

            compare(ids(search.results("abc")), ["tight", "wide"])
        }

        function test_hiddenEntriesAreExcluded() {
            const search = createSearch([
                entry("visible", "Editor"),
                entry("desktop-hidden", "Editor", "", [], true),
                entry("configured-hidden", "Editor")
            ], ["configured-hidden"])

            compare(ids(search.results("")), ["visible"])
            compare(ids(search.results("editor")), ["visible"])
        }

        function test_noMatchesReturnsEmptyList() {
            const search = createSearch([entry("terminal", "Terminal")])

            compare(search.results("nonexistent"), [])
        }

        function test_entriesAndConfigurationRebuildIndex() {
            const search = createSearch([
                entry("first", "First", "", ["needle"]),
                entry("second", "Second", "", ["needle"])
            ], [], ["name"])

            compare(ids(search.results("needle")), [])
            search.searchFields = ["name", "keywords"]
            compare(ids(search.results("needle")), ["first", "second"])

            search.hiddenEntryIds = ["first"]
            search.entries = [
                entry("first", "First", "", ["needle"]),
                entry("third", "Third", "", ["needle"])
            ]
            compare(ids(search.results("needle")), ["third"])
        }

        function test_warmSearchTiming() {
            const entries = []
            for (let index = 0; index < 1000; index++) {
                const suffix = ("0000" + index).slice(-4)
                entries.push(entry("app-" + suffix, "Application " + suffix,
                                  "Utility", ["warmsearch", "launch"]))
            }
            const search = createSearch(entries)
            search.results("warmsearch")

            const start = Date.now()
            let resultCount = 0
            for (let iteration = 0; iteration < 20; iteration++)
                resultCount = search.results("warmsearch").length
            const elapsed = Date.now() - start
            console.log("AppSearch warm search: 1000 entries, 20 queries, " + elapsed + " ms")
            compare(resultCount, 1000)
        }
    }
}
