import QtQuick
import QtTest
import "mpris" as Fake
import "../shell/tests/mpris" as Shell

// The art logic with a fake runner: the provider steps in order, the stale guard, the debounce,
// the failure memory and which failures are reported.
Item {
    id: root
    Component { id: playerComponent; Fake.FakePlayer {} }
    Component { id: runnerComponent; Fake.FakeRunner {} }
    Component { id: artComponent; Shell.MediaArt {} }
    SignalSpy { id: faults; signalName: "faultReported" }
    TestCase {
        name: "MediaArt"

        function player(entry, address) { return createTemporaryObject(playerComponent, root, { desktopEntry: entry, identity: entry, trackArtUrl: address ?? "http://example.test/a.jpg" }) }
        function make(p, props) {
            const runner = createTemporaryObject(runnerComponent, root)
            const options = Object.assign({}, props || {})
            delete options.noProbe
            const art = createTemporaryObject(artComponent, root, Object.assign({
                runner: runner, player: p, keyOf: p => p.desktopEntry, enabled: true, debounceMs: 1, cacheDir: "/cache",
                modes: { mpd: "cover", firefox: "blurhash" }, defaultMode: "cover",
                providers: { cover: ["fetch"], blurhash: ["fetch", "shrink", "blurhash"], off: [] }
            }, options))
            faults.target = art
            faults.clear()
            // The tool check answers first, as it does at start-up.
            if (!(props && props.noProbe === true)) runner.finished("capabilities", { ok: true, fetch: true, shrink: "vips", blurhash: true })
            return { runner: runner, art: art }
        }
        function started(t) { tryVerify(() => t.runner.last() !== null, 2000) }
        // Calls that are steps of the art chain (not the start-up tool check or the clean-up).
        function steps(t) { return t.runner.calls.filter(call => call.step !== "capabilities" && call.step !== "prune") }

        function test_nothingToDoUntilEnabledAndThereIsAnAddress() {
            const t = make(player("mpd", ""))
            wait(20)
            compare(steps(t).length, 0)
            compare(t.art.state, "none")
            const u = make(player("mpd"), { enabled: false })
            wait(20)
            compare(steps(u).length, 0)
        }
        function test_aCoverIsOneFetchAndEndsReady() {
            const t = make(player("mpd"))
            started(t)
            compare(t.runner.last().step, "fetch")
            compare(t.runner.last().input, "http://example.test/a.jpg")
            compare(t.art.state, "loading")
            t.runner.reply({ ok: true, path: "/cache/a.src" })
            compare(t.art.state, "ready")
            compare(t.art.kind, "cover")
            compare(t.art.path, "/cache/a.src")
            verify(t.runner.calls.some(call => call.step === "prune" && call.flags.includes("/cache/a.src")))
        }
        function test_aBlurhashRunsFetchShrinkBlurhashAndEachFeedsTheNext() {
            const t = make(player("firefox"))
            started(t)
            compare(t.runner.last().step, "fetch")
            t.runner.reply({ ok: true, path: "/cache/1" })
            compare(t.runner.last().step, "shrink")
            compare(t.runner.last().input, "/cache/1")
            t.runner.reply({ ok: true, path: "/cache/2" })
            compare(t.runner.last().step, "blurhash")
            compare(t.runner.last().input, "/cache/2")
            compare(t.art.state, "loading")
            t.runner.reply({ ok: true, path: "/cache/3" })
            compare(t.art.state, "ready")
            compare(t.art.kind, "blurhash")
            compare(t.art.path, "/cache/3")
        }
        function test_aSkippedTrackKillsTheRunAndItsLateAnswerNeverShows() {
            const p = player("mpd", "http://example.test/one.jpg")
            const t = make(p)
            started(t)
            const stale = t.runner.last().runKey
            const kills = t.runner.kills
            p.trackArtUrl = "http://example.test/two.jpg"
            verify(t.runner.kills > kills)
            compare(t.art.state, "none")
            compare(t.art.path, "")
            t.runner.finished(stale, { ok: true, path: "/cache/old" })
            compare(t.art.path, "")
            tryVerify(() => t.runner.last().input === "http://example.test/two.jpg", 2000)
            t.runner.reply({ ok: true, path: "/cache/new" })
            compare(t.art.path, "/cache/new")
        }
        function test_thePreviousArtDoesNotStayWhileTheNextLoads() {
            const p = player("mpd", "http://example.test/one.jpg")
            const t = make(p)
            started(t)
            t.runner.reply({ ok: true, path: "/cache/one" })
            compare(t.art.state, "ready")
            p.trackArtUrl = "http://example.test/two.jpg"
            compare(t.art.state, "none")
            compare(t.art.path, "")
        }
        function test_theSameAddressKeepsTheArtWhenOnlyTheTitleChanges() {
            const p = player("mpd")
            const t = make(p)
            started(t)
            t.runner.reply({ ok: true, path: "/cache/one" })
            p.trackTitle = "Another title"
            compare(t.art.state, "ready")
            compare(t.art.path, "/cache/one")
        }
        function test_aRapidSkipStartsOnlyTheLastAddressAfterTheDebounce() {
            const p = player("mpd", "http://example.test/one.jpg")
            const t = make(p, { debounceMs: 80 })
            p.trackArtUrl = "http://example.test/two.jpg"
            p.trackArtUrl = "http://example.test/three.jpg"
            wait(200)
            const fetches = t.runner.calls.filter(call => call.step === "fetch")
            compare(fetches.length, 1)
            compare(fetches[0].input, "http://example.test/three.jpg")
        }
        function test_disablingStopsTheRunAndClearsTheArt() {
            const t = make(player("mpd"))
            started(t)
            const kills = t.runner.kills
            t.art.enabled = false
            verify(t.runner.kills > kills, "a step in flight is killed")
            compare(t.art.state, "none")
            // And once the art is ready there is nothing to kill; it is only cleared.
            t.art.enabled = true
            started(t)
            t.runner.reply({ ok: true, path: "/cache/one" })
            const idle = t.runner.kills
            t.art.enabled = false
            compare(t.runner.kills, idle)
            compare(t.art.path, "")
        }
        function test_modeOffDoesNothing() {
            const t = make(player("mpd"), { modes: { mpd: "off" } })
            wait(20)
            compare(steps(t).length, 0)
            compare(t.art.state, "none")
        }
        function test_anUnknownPlayerUsesTheDefaultMode() {
            const t = make(player("someplayer"), { defaultMode: "blurhash" })
            started(t)
            t.runner.reply({ ok: true, path: "/a" })
            compare(t.runner.last().step, "shrink")
        }
        function test_aRefusedSchemeIsSilentAndAFaultIsReportedOncePerCause() {
            const p = player("mpd", "http://example.test/one.jpg")
            const t = make(p)
            started(t)
            t.runner.reply({ ok: false, error: "scheme", detail: "data" })
            compare(t.art.state, "failed")
            compare(faults.count, 0)
            p.trackArtUrl = "http://example.test/two.jpg"
            tryVerify(() => t.runner.last().input === "http://example.test/two.jpg", 2000)
            t.runner.reply({ ok: false, error: "missing-tool", detail: "curl was not found" })
            compare(faults.count, 1)
            const failure = faults.signalArguments[0][0]
            compare(failure.source, "mpris")
            verify(failure.sequence >= 1)
            verify(failure.title.length > 0 && failure.message.length > 0 && failure.operation.length > 0 && failure.target.length > 0)
            p.trackArtUrl = "http://example.test/three.jpg"
            tryVerify(() => t.runner.last().input === "http://example.test/three.jpg", 2000)
            t.runner.reply({ ok: false, error: "missing-tool", detail: "curl was not found" })
            compare(faults.count, 1)
            p.trackArtUrl = "http://example.test/four.jpg"
            tryVerify(() => t.runner.last().input === "http://example.test/four.jpg", 2000)
            t.runner.reply({ ok: false, error: "timeout", detail: "slow" })
            compare(faults.count, 2)
            verify(faults.signalArguments[1][0].sequence > failure.sequence)
        }
        function test_aFailedAddressIsNotTriedAgainWhileItIsRemembered() {
            const p = player("mpd", "http://example.test/bad.jpg")
            const t = make(p)
            started(t)
            t.runner.reply({ ok: false, error: "tool-failed", detail: "x" })
            const calls = t.runner.calls.length
            p.trackArtUrl = "http://example.test/other.jpg"
            tryVerify(() => t.runner.last().input === "http://example.test/other.jpg", 2000)
            p.trackArtUrl = "http://example.test/bad.jpg"
            wait(30)
            compare(t.art.state, "failed")
            compare(t.runner.calls.filter(call => call.input === "http://example.test/bad.jpg").length, 1)
        }
        function test_aBrokenAnswerIsAToolFailure() {
            const t = make(player("mpd"))
            started(t)
            t.runner.reply(undefined)
            compare(t.art.state, "failed")
            compare(faults.count, 1)
        }
        function test_flagsCarryTheConfiguredLimits() {
            const t = make(player("firefox"), { shrinkSize: 200, blurhashComponents: "5,4", stepTimeoutSeconds: 7, downloadMaxBytes: 1234 })
            started(t)
            const fetch = t.runner.last().flags
            verify(fetch.includes("--max-bytes") && fetch.includes("1234") && fetch.includes("7") && fetch.includes("/cache"))
            verify(!fetch.includes("--tool"))
            t.runner.reply({ ok: true, path: "/cache/1" })
            verify(t.runner.last().flags.includes("200") && t.runner.last().flags.includes("vips"))
            t.runner.reply({ ok: true, path: "/cache/2" })
            verify(t.runner.last().flags.includes("5,4"))
        }
        function test_theToolCheckRunsFirstAndNothingRunsUntilItAnswers() {
            const t = make(player("mpd"), { noProbe: true })
            compare(t.runner.calls[0].step, "capabilities")
            verify(t.runner.calls[0].flags.includes("--shrink-tools") && t.runner.calls[0].flags.includes("vips,ffmpeg"))
            wait(30)
            compare(t.runner.calls.filter(call => call.step === "fetch").length, 0)
            compare(t.art.capabilities.known, false)
            t.runner.finished("capabilities", { ok: true, fetch: true, shrink: "ffmpeg", blurhash: false })
            started(t)
            compare(t.runner.last().step, "fetch")
        }
        function test_blurhashFallsBackToTheCoverWhenItsToolsAreMissing() {
            const t = make(player("firefox"), { noProbe: true })
            t.runner.finished("capabilities", { ok: true, fetch: true, shrink: "", blurhash: false })
            compare(t.art.blurhashAvailable, false)
            compare(t.art.mode, "cover")
            started(t)
            compare(t.runner.last().step, "fetch")
            t.runner.reply({ ok: true, path: "/cache/c" })
            compare(t.art.kind, "cover")
            compare(t.runner.calls.filter(call => call.step === "shrink").length, 0)
        }
        function test_blurhashIsOfferedBeforeTheCheckAnswersAndWhenItsToolsExist() {
            const t = make(player("mpd"), { noProbe: true })
            compare(t.art.blurhashAvailable, true)
            t.runner.finished("capabilities", { ok: true, fetch: true, shrink: "vips", blurhash: true })
            compare(t.art.blurhashAvailable, true)
        }
        function test_aBrokenToolCheckLeavesBlurhashOffAndTheCoverWorking() {
            const t = make(player("mpd"), { noProbe: true })
            t.runner.finished("capabilities", { ok: false, error: "tool-failed", detail: "x" })
            compare(t.art.blurhashAvailable, false)
            started(t)
            compare(t.runner.last().step, "fetch")
        }
        function test_theShrinkToolChosenByTheCheckIsUsed() {
            const t = make(player("firefox"), { noProbe: true })
            t.runner.finished("capabilities", { ok: true, fetch: true, shrink: "ffmpeg", blurhash: true })
            started(t)
            t.runner.reply({ ok: true, path: "/cache/1" })
            const flags = t.runner.last().flags
            compare(flags[flags.indexOf("--tool") + 1], "ffmpeg")
        }
        function test_theSameStateComingBackShowsTheArtAtOnceWithNoStepAndNoGap() {
            const p = player("mpd", "http://example.test/one.jpg")
            const t = make(p)
            started(t)
            t.runner.reply({ ok: true, path: "/cache/one" })
            compare(t.art.state, "ready")
            const fetches = t.runner.calls.filter(call => call.step === "fetch").length
            // The panel is closed (the art is cleared: nobody sees it) and opened again.
            t.art.enabled = false
            const seen = []
            t.art.stateChanged.connect(() => seen.push(t.art.state))
            t.art.pathChanged.connect(() => seen.push("path:" + t.art.path))
            t.art.enabled = true
            compare(t.art.state, "ready")
            compare(t.art.path, "/cache/one")
            compare(t.runner.calls.filter(call => call.step === "fetch").length, fetches)
            verify(!seen.includes("none") && !seen.includes("path:"), "no empty moment in between: " + JSON.stringify(seen))
        }
        function test_aTrackThatWasShownBeforeComesBackFromTheHotCache() {
            const p = player("mpd", "http://example.test/one.jpg")
            const t = make(p)
            started(t)
            t.runner.reply({ ok: true, path: "/cache/one" })
            p.trackArtUrl = "http://example.test/two.jpg"
            tryVerify(() => t.runner.last().input === "http://example.test/two.jpg", 2000)
            t.runner.reply({ ok: true, path: "/cache/two" })
            const fetches = t.runner.calls.filter(call => call.step === "fetch").length
            p.trackArtUrl = "http://example.test/one.jpg"
            compare(t.art.path, "/cache/one")
            compare(t.art.state, "ready")
            compare(t.runner.calls.filter(call => call.step === "fetch").length, fetches)
        }
        function test_theHotCacheKeepsOnlyTheMostRecentEntries() {
            const p = player("mpd", "http://example.test/0.jpg")
            const t = make(p, { hotEntries: 2 })
            for (let i = 0; i < 3; i++) {
                p.trackArtUrl = "http://example.test/" + i + ".jpg"
                tryVerify(() => t.runner.last() && t.runner.last().input === "http://example.test/" + i + ".jpg", 2000)
                t.runner.reply({ ok: true, path: "/cache/" + i })
            }
            compare(t.art.memo.length, 2)
            const fetches = t.runner.calls.filter(call => call.step === "fetch").length
            p.trackArtUrl = "http://example.test/0.jpg"
            compare(t.art.state, "none")
            tryVerify(() => t.runner.calls.filter(call => call.step === "fetch").length === fetches + 1, 2000)
        }
        function test_aDifferentModeIsADifferentRequestSoItIsNotServedFromTheOtherModesArt() {
            const p = player("mpd", "http://example.test/one.jpg")
            const t = make(p)
            started(t)
            t.runner.reply({ ok: true, path: "/cache/cover" })
            t.art.modes = { mpd: "blurhash" }
            compare(t.art.state, "none")
            tryVerify(() => t.runner.last().step === "fetch" && t.runner.calls.length > 3, 2000)
        }
        function test_aLostFileIsForgottenAndMadeAgain() {
            const p = player("mpd")
            const t = make(p)
            started(t)
            t.runner.reply({ ok: true, path: "/cache/one" })
            const fetches = t.runner.calls.filter(call => call.step === "fetch").length
            t.art.lost("/cache/one")
            compare(t.art.memo.length, 0)
            tryVerify(() => t.runner.calls.filter(call => call.step === "fetch").length === fetches + 1, 2000)
        }
        function test_aLostFileThatIsNotShownOnlyLeavesTheMemory() {
            const p = player("mpd", "http://example.test/one.jpg")
            const t = make(p)
            started(t)
            t.runner.reply({ ok: true, path: "/cache/one" })
            t.art.lost("/cache/other")
            compare(t.art.path, "/cache/one")
            compare(t.art.memo.length, 1)
        }
        function test_aForcedModeAppliesToEveryPlayerWhateverTheTable() {
            const mpd = make(player("mpd"), { forcedMode: "blurhash" })
            started(mpd)
            mpd.runner.reply({ ok: true, path: "/a" })
            compare(mpd.runner.last().step, "shrink")
            const browser = make(player("firefox"), { forcedMode: "cover" })
            started(browser)
            browser.runner.reply({ ok: true, path: "/b" })
            compare(browser.art.kind, "cover")
            compare(browser.runner.calls.filter(call => call.step === "shrink").length, 0)
            const other = make(player("someplayer"), { forcedMode: "off" })
            wait(20)
            compare(steps(other).length, 0)
        }
        function test_autoUsesThePerPlayerTable() {
            const mpd = make(player("mpd"), { forcedMode: "auto" })
            started(mpd)
            mpd.runner.reply({ ok: true, path: "/a" })
            compare(mpd.art.kind, "cover")
            const browser = make(player("firefox"), { forcedMode: "auto" })
            started(browser)
            browser.runner.reply({ ok: true, path: "/b" })
            compare(browser.runner.last().step, "shrink")
        }
        function test_changingTheForcedModeRestartsWithTheNewMode() {
            const t = make(player("mpd", "http://example.test/one.jpg"))
            started(t)
            t.runner.reply({ ok: true, path: "/cover" })
            compare(t.art.kind, "cover")
            t.art.forcedMode = "off"
            compare(t.art.state, "none")
            compare(t.art.path, "")
        }
    }
}
