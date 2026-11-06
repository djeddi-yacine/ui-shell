# Every environment/check entrypoint chooses its state lifetime explicitly.
TEST_RUNNER := $(ROOT)/tests/scripts/test-nested
TEST_STATE := $(ROOT)/tests/scripts/test-state

.PHONY: test-env-audio test-audio test-audio-host test-help test test-scripts test-sandbox test-hypr-config test-qml test-theme-config test-pipelines test-app2unit test-app-launch test-session-close test-env test-env-persistent test-env-fresh test-env-apps test-env-phantomat test-env-snapshot test-env-clean test-import-themes test-wallpaper test-launcher test-theme test-profiles test-motion test-borders

test-help:
	@printf '%s\n' \
		'Test environment (private HOME and XDG state):' \
		'  test-env          Open the nested session with popups closed; retain private state' \
		'  test-env-persistent Restart the nested session with saved private choices' \
		'  test-import-themes Regenerate reference definitions in private themes; no profile/window' \
		'  test-env-fresh    Open a disposable nested session' \
		'  test-env-apps     Open a disposable launcher; apps use private test scopes' \
		'  test-env-audio    Open a disposable session with the audio panel on the HOST PipeWire (real devices)' \
		'  test-env-phantomat Open test-env with Phantomat loaded; retain private state' \
		'  test-env-snapshot Restart saved test state, capture diagnostics, then close' \
		'  test-env-clean    Reset private choices/cache; keep all Theme definitions' \
		'' \
		'Automated checks (disposable state; visual runs close automatically):' \
		'  test              Run all script, sandbox, Hyprland, QML, theme and pipeline checks' \
		'  test-scripts      Validate every runtime, development and test script' \
		'  test-sandbox      Check private sandbox boundaries and staging paths' \
		'  test-hypr-config  Verify production and nested Hyprland configs in private XDG state' \
		'  test-qml          Lint QML and run isolated Qt Quick Test suites' \
		'  test-theme-config Check theme definitions, references and config contracts' \
		'  test-pipelines    Check generated wallpaper and component pipelines' \
		'  test-wallpaper    Check picker/UI and real wallpaper application' \
		'  test-launcher     Check launcher and app2unit dry-run without starting an app' \
		'  test-audio        Stress the audio helper on a PRIVATE PipeWire+WirePlumber session (generated tones; host audio untouched)' \
		'  test-audio-host   Same stress test on the CURRENT PipeWire session; only its own uitest-* streams are touched' \
		'  test-app2unit     Register a host scope, then verify its app is sandboxed' \
		'  test-app-launch   Launch a real nested GUI app; verify handoff, error and cleanup' \
		'  test-session-close Close the nested host window with a live app; verify teardown' \
		'  test-theme        Render and verify the configured reference palette' \
		'  test-profiles     Exercise the theme editor in a disposable session' \
		'  test-motion       Profile picker motion and graceful nested exit' \
		'  test-borders      Verify native output-scoped borders in a disposable session' \
		''

test: test-scripts test-sandbox test-hypr-config test-qml test-theme-config test-pipelines
	@printf '%s\n' 'Checks passed.'

test-scripts:
	@for script in "$(ROOT)"/scripts/* "$(ROOT)"/tools/scripts/* "$(ROOT)"/tests/scripts/*; do \
		[[ -f "$$script" ]] || continue; \
		case "$$script" in *.lua) luac -p "$$script" ;; *) \
			IFS= read -r shebang <"$$script" || true; \
			case "$$shebang" in *python*) python3 -c 'import ast,pathlib,sys; ast.parse(pathlib.Path(sys.argv[1]).read_text())' "$$script" ;; *) bash -n "$$script" ;; esac ;; \
		esac; \
	done
	@bash -n "$(ROOT)/tests/nested.conf"

test-env test-env-persistent:
	@bash "$(TEST_RUNNER)" run persistent

test-import-themes:
	@bash "$(TEST_RUNNER)" import-themes persistent

test-env-fresh:
	@bash "$(TEST_RUNNER)" run ephemeral

# The nested session with the audio panel open on the HOST's PipeWire (real devices).
# Everything you change there (volume, mute, default, routing, links) is real; Esc closes the panel.
test-env-audio:
	@UI_SHELL_HOST_PIPEWIRE=1 UI_SHELL_OPEN_AUDIO=1 bash "$(TEST_RUNNER)" run ephemeral

test-env-apps:
	@bash "$(TEST_RUNNER)" apps ephemeral

test-env-snapshot:
	@bash "$(TEST_RUNNER)" snapshot persistent

test-env-clean:
	@bash "$(TEST_STATE)" clean

test-wallpaper:
	@bash "$(TEST_RUNNER)" smoke ephemeral

test-launcher:
	@bash "$(TEST_RUNNER)" launcher ephemeral

test-app2unit:
	@bash "$(ROOT)/tests/scripts/check-app2unit-scope"

test-app-launch:
	@bash "$(TEST_RUNNER)" app-launch ephemeral

test-session-close:
	@bash "$(TEST_RUNNER)" app-close ephemeral

test-theme:
	@bash "$(TEST_RUNNER)" theme ephemeral

test-profiles:
	@bash "$(TEST_RUNNER)" profiles ephemeral

test-motion:
	@bash "$(TEST_RUNNER)" motion ephemeral

test-borders:
	@bash "$(TEST_RUNNER)" borders ephemeral

test-sandbox:
	@bash "$(TEST_RUNNER)" check ephemeral

test-hypr-config:
	@bash "$(ROOT)/tests/scripts/check-hypr-config"

test-qml:
	@bash "$(TEST_RUNNER)" qml ephemeral

test-theme-config:
	@bash "$(TEST_RUNNER)" theme-config ephemeral

test-pipelines:
	@bash "$(TEST_RUNNER)" pipelines ephemeral

test-env-phantomat: dev-build-phantomat
	@bash "$(TEST_RUNNER)" phantomat persistent

# Audio stress tests run on the host, outside the sandbox: PipeWire needs real sockets.
# `test-audio` starts its own PipeWire and WirePlumber under a temporary runtime directory,
# so nothing of the desktop's audio can be reached; the test verifies that afterwards.
test-audio:
	@bash "$(ROOT)/tests/scripts/check-audio-live" private

test-audio-host:
	@bash "$(ROOT)/tests/scripts/check-audio-live" host
