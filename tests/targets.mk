# Every environment/check entrypoint chooses its state lifetime explicitly.
TEST_RUNNER := $(ROOT)/tests/scripts/test-nested
TEST_STATE := $(ROOT)/tests/scripts/test-state

.PHONY: test-auth test-mpris test-record test-record-live test-shot test-shot-live test-audio test-audio-host test-help test test-scripts test-sandbox test-hypr-config test-qml test-theme-config test-pipelines test-app2unit test-app-launch test-session-close test-env test-env-host test-env-snapshot test-env-clean test-import-themes test-wallpaper test-launcher test-theme test-profiles test-motion test-borders test-notify test-notifications

test-help:
	@printf '%s\n' \
		'Test environment (private HOME and XDG state):' \
		'  test-env          THE interactive session: nested Hyprland with every feature on (wallpaper picker, launcher, tuning, audio on the HOST PipeWire, recording, Phantomat when built); private saved state. UI_SHELL_HOST_PIPEWIRE=0 keeps audio private.' \
		'  test-import-themes Regenerate reference definitions in private themes; no profile/window' \
		'  test-env-host     Run the shell on the REAL session (screen, audio, MPRIS, recorder) with all writes kept in .test-state/host; stop your own shell first.' \
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
		'  test-notify       Send notification cases to the shell in this session: a menu on a terminal, or CASES='3 5-7'' \
		'  test-notifications Nested session: real D-Bus server and popups, asserts ordering, in-place progress, burst, DND, unread, clear, no focus change' \
		'  test-launcher     Check launcher and app2unit dry-run without starting an app' \
		'  test-audio        Stress the audio helper on a PRIVATE PipeWire+WirePlumber session (generated tones; host audio untouched)' \
		'  test-record       Check the screen-record state machine with a fake recorder (no screen, no GPU)' \
		'  test-mpris        Check the media control namespace and keys against the Hyprland config, and the art script with stand-in tools (no player, no network)' \
		'  test-auth         Check the authentication dialog and polkit logic with a fake request (no polkit)' \
		'  test-shot         Check the screenshot script with stand-ins for grim and wl-copy (no screen)' \
		'  test-shot-live    Take real screenshots of THIS desktop with grim and wl-copy and check them' \
		'  test-record-live  Record 3 s of THIS desktop with GPU Screen Recorder and validate the file (real screen)' \
		'  test-audio-host   Same stress test on the CURRENT PipeWire session; only its own uitest-* streams are touched' \
		'  test-app2unit     Register a host scope, then verify its app is sandboxed' \
		'  test-app-launch   Launch a real nested GUI app; verify handoff, error and cleanup' \
		'  test-session-close Close the nested host window with a live app; verify teardown' \
		'  test-theme        Render and verify the configured reference palette' \
		'  test-profiles     Exercise the theme editor in a disposable session' \
		'  test-motion       Profile picker motion and graceful nested exit' \
		'  test-borders      Verify native output-scoped borders in a disposable session' \
		''

test: test-scripts test-sandbox test-hypr-config test-qml test-theme-config test-pipelines test-record test-shot test-auth test-mpris test-notifications
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

# The one interactive session: everything enabled, private saved state. Audio uses the host
# PipeWire socket (changes are real; set UI_SHELL_HOST_PIPEWIRE=0 to keep audio private).
# Phantomat is built if needed and loaded when the build works.
test-env:
	@$(MAKE) --no-print-directory dev-build-phantomat || printf '%s\n' 'Phantomat build failed; starting without it.' >&2
	@UI_SHELL_HOST_PIPEWIRE=$${UI_SHELL_HOST_PIPEWIRE:-1} bash "$(TEST_RUNNER)" run persistent

test-import-themes:
	@bash "$(TEST_RUNNER)" import-themes persistent

# Real screen, audio, MPRIS and gpu-screen-recorder; only the files are private.
test-env-host:
	@bash "$(ROOT)/tests/scripts/host-session"

test-env-snapshot:
	@bash "$(TEST_RUNNER)" snapshot persistent

test-env-clean:
	@bash "$(TEST_STATE)" clean

test-wallpaper:
	@bash "$(TEST_RUNNER)" smoke ephemeral

# Sends every notification case to the running shell's session bus (run it inside test-env / test-env-host).
test-notify:
	@bash "$(ROOT)/tests/notifications/send-cases" $(CASES)

test-notifications:
	@bash "$(TEST_RUNNER)" notifications ephemeral

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

# Audio stress tests run on the host, outside the sandbox: PipeWire needs real sockets.
# `test-audio` starts its own PipeWire and WirePlumber under a temporary runtime directory,
# so nothing of the desktop's audio can be reached; the test verifies that afterwards.
test-audio:
	@bash "$(ROOT)/tests/scripts/check-audio-live" private

test-audio-host:
	@bash "$(ROOT)/tests/scripts/check-audio-live" host

test-record:
	@bash "$(ROOT)/tests/scripts/check-screen-record"

# Records the real screen with the real recorder; needs a Wayland session and gpu-screen-recorder.
test-record-live:
	@bash "$(ROOT)/tests/scripts/check-screen-record-live"

# The authentication dialog and its polkit logic, with a fake request (no polkit daemon).
# The media control: the layer namespace and (from phase 2) the media keys agree with the Hyprland config.
test-mpris:
	@bash "$(ROOT)/tests/scripts/check-mpris"
	@bash "$(ROOT)/tests/scripts/check-media-art"

test-auth:
	@bash "$(ROOT)/tests/scripts/check-auth"

test-shot:
	@bash "$(ROOT)/tests/scripts/check-screen-shot"

# Takes real screenshots of the real screen; needs a Wayland session, grim, wl-copy and wl-paste.
test-shot-live:
	@bash "$(ROOT)/tests/scripts/check-screen-shot-live"
