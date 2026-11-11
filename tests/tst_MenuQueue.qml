import QtQuick
import QtTest

import "../shell/tests/menu" as Menu

TestCase {
    id: root
    name: "MenuQueue"

    Menu.MenuQueue { id: queue }
    SignalSpy { id: openSpy; target: queue; signalName: "openChanged" }

    function entry(id, app) { return { id: id, app: app, prompt: id + ": ", lines: [id] } }
    function ids() { return queue.entries.map(e => e.id) }

    function init() {
        queue.entries = []
        queue.current = ""
    }

    function test_empty_queue_shows_nothing() {
        compare(queue.empty, true)
        compare(queue.visible, null)
        compare(queue.current, "")
        compare(queue.apps.length, 0)
    }
    function test_first_request_becomes_visible() {
        queue.add(entry("1", "uuctl"))
        compare(queue.current, "uuctl")
        compare(queue.visible.id, "1")
        compare(queue.empty, false)
    }
    function test_requests_of_one_app_wait_in_arrival_order() {
        queue.add(entry("1", "uuctl"))
        queue.add(entry("2", "uuctl"))
        compare(queue.visible.id, "1")
        compare(queue.apps.length, 1)
        compare(queue.apps[0].count, 2)
        queue.remove("1")
        compare(queue.visible.id, "2")
    }
    function test_each_app_has_one_tab_in_order_of_first_request() {
        queue.add(entry("1", "uuctl"))
        queue.add(entry("2", "other"))
        queue.add(entry("3", "uuctl"))
        compare(queue.apps.map(a => a.name), ["uuctl", "other"])
        compare(queue.apps.map(a => a.count), [2, 1])
        compare(queue.current, "uuctl")
    }
    function test_a_new_request_of_another_app_does_not_take_the_card() {
        queue.add(entry("1", "uuctl"))
        queue.add(entry("2", "other"))
        compare(queue.visible.id, "1")
    }
    function test_the_same_id_is_added_once() {
        queue.add(entry("1", "uuctl"))
        queue.add(entry("1", "uuctl"))
        compare(ids(), ["1"])
    }
    function test_removing_an_unknown_id_changes_nothing() {
        queue.add(entry("1", "uuctl"))
        queue.remove("9")
        compare(ids(), ["1"])
        compare(queue.current, "uuctl")
    }
    function test_the_shown_app_stays_while_it_still_has_requests() {
        queue.add(entry("1", "uuctl"))
        queue.add(entry("2", "other"))
        queue.add(entry("3", "uuctl"))
        queue.cycle(1)
        compare(queue.current, "other")
        queue.remove("1")
        compare(queue.current, "other")
        compare(queue.visible.id, "2")
    }
    function test_when_the_shown_app_empties_the_next_app_is_shown() {
        queue.add(entry("1", "uuctl"))
        queue.add(entry("2", "other"))
        queue.remove("1")
        compare(queue.current, "other")
        compare(queue.visible.id, "2")
    }
    function test_removing_the_last_request_clears_the_current_app() {
        queue.add(entry("1", "uuctl"))
        queue.remove("1")
        compare(queue.current, "")
        compare(queue.visible, null)
        compare(queue.empty, true)
    }
    function test_cycle_wraps_both_ways() {
        queue.add(entry("1", "a"))
        queue.add(entry("2", "b"))
        queue.add(entry("3", "c"))
        queue.cycle(1); compare(queue.current, "b")
        queue.cycle(1); compare(queue.current, "c")
        queue.cycle(1); compare(queue.current, "a")
        queue.cycle(-1); compare(queue.current, "c")
    }
    function test_cycle_with_one_app_does_nothing() {
        queue.add(entry("1", "a"))
        queue.cycle(1)
        compare(queue.current, "a")
        queue.cycle(-1)
        compare(queue.current, "a")
    }
    function test_a_removed_tab_leaves_the_others_in_order() {
        queue.add(entry("1", "a"))
        queue.add(entry("2", "b"))
        queue.add(entry("3", "c"))
        queue.remove("2")
        compare(queue.apps.map(a => a.name), ["a", "c"])
    }

    // --- what keeps the card open ----------------------------------------------------------------
    function test_open_follows_waiting_requests() {
        compare(queue.open, false)
        queue.add(entry("1", "a"))
        compare(queue.open, true)
        queue.remove("1")
        compare(queue.open, false)
    }
    function test_a_request_that_replaces_the_last_one_changes_open_only_through_closed() {
        queue.add(entry("1", "a"))
        openSpy.clear()
        queue.remove("1")
        queue.add(entry("2", "a"))
        compare(queue.open, true)
        compare(openSpy.count, 2)
        compare(queue.visible.id, "2")
    }
    function test_an_unknown_id_changes_nothing() {
        queue.add(entry("1", "a"))
        queue.remove("9")
        compare(ids(), ["1"])
    }

    // --- stress --------------------------------------------------------------------------------------
    // A small deterministic generator, so a failure repeats.
    property int seed: 1
    function random(limit) {
        seed = (seed * 1103515245 + 12345) % 2147483648
        return seed % limit
    }
    // What the queue must show, worked out again from the plain list of what is waiting.
    function check_invariants(model, message) {
        compare(ids(), model.map(e => e.id), message + ": entries")
        compare(queue.empty, model.length === 0, message + ": empty")
        const names = []
        for (const e of model) if (!names.includes(e.app)) names.push(e.app)
        compare(queue.apps.map(a => a.name), names, message + ": tabs")
        compare(queue.apps.reduce((n, a) => n + a.count, 0), model.length, message + ": counts")
        if (model.length === 0) {
            compare(queue.current, "", message + ": current")
            compare(queue.visible, null, message + ": visible")
        } else {
            verify(names.includes(queue.current), message + ": current is a tab")
            const first = model.find(e => e.app === queue.current)
            compare(queue.visible.id, first.id, message + ": oldest of the current app")
        }
    }
    function test_random_operations_keep_the_queue_consistent() {
        for (const round of [11, 29, 47, 101, 977]) {
            seed = round
            queue.entries = []
            queue.current = ""
            const model = []
            let next = 1
            for (let step = 0; step < 400; step++) {
                const action = random(10)
                if (action < 4) {
                    const e = entry(String(next++), "app" + random(5))
                    queue.add(e); model.push(e)
                } else if (action < 6 && model.length > 0) {
                    const at = random(model.length)
                    queue.remove(model[at].id, random(2) === 0)
                    model.splice(at, 1)
                } else if (action < 8) {
                    queue.cycle(random(2) === 0 ? 1 : -1)
                } else if (action === 8 && model.length > 0) {
                    queue.add(model[random(model.length)])
                } else {
                    queue.remove("missing-" + random(100), true)
                }
                check_invariants(model, "round " + round + " step " + step)
            }
        }
    }
    function test_a_thousand_requests_are_queued_and_drained_in_order() {
        const model = []
        for (let i = 1; i <= 1000; i++) {
            const e = entry(String(i), "app" + (i % 7))
            queue.add(e); model.push(e)
        }
        check_invariants(model, "filled")
        while (model.length > 0) {
            const shown = queue.visible.id
            queue.remove(shown)
            model.splice(model.findIndex(e => e.id === shown), 1)
            if (model.length % 97 === 0) check_invariants(model, "draining at " + model.length)
        }
        check_invariants(model, "drained")
        compare(queue.open, false)
    }
    function test_many_apps_cycle_through_every_tab_and_return() {
        for (let i = 0; i < 50; i++) queue.add(entry(String(i), "app" + i))
        const seen = []
        for (let i = 0; i < 50; i++) { seen.push(queue.current); queue.cycle(1) }
        compare(queue.current, "app0")
        compare(new Set(seen).size, 50)
        for (let i = 0; i < 50; i++) queue.cycle(-1)
        compare(queue.current, "app0")
    }
}
