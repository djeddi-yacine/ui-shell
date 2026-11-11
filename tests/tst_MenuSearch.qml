import QtQuick
import QtTest

import "../shell/tests/menu" as Menu

TestCase {
    name: "MenuSearch"

    readonly property var lines: ["Alpha Beta", "beta gamma", "delta", "", "unit.service (active)"]

    function test_empty_query_matches_every_line_in_order() {
        compare(Menu.MenuSearch.matches(lines, ""), [0, 1, 2, 3, 4])
        compare(Menu.MenuSearch.matches(lines, "   "), [0, 1, 2, 3, 4])
    }
    function test_search_is_case_insensitive_substring() {
        compare(Menu.MenuSearch.matches(lines, "BET"), [0, 1])
    }
    function test_every_word_must_match_in_any_order() {
        compare(Menu.MenuSearch.matches(lines, "gamma beta"), [1])
        compare(Menu.MenuSearch.matches(lines, "alpha gamma"), [])
    }
    function test_the_senders_order_is_kept() {
        compare(Menu.MenuSearch.matches(lines, "a"), [0, 1, 2, 4])
    }
    function test_punctuation_is_matched_literally() {
        compare(Menu.MenuSearch.matches(lines, "(active)"), [4])
        compare(Menu.MenuSearch.matches(lines, ".service"), [4])
    }
    function test_a_blank_line_matches_only_the_empty_query() {
        compare(Menu.MenuSearch.matches([""], "x"), [])
        compare(Menu.MenuSearch.matches([""], ""), [0])
    }
}
