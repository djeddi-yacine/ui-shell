# Checkout development only. These targets never launch the isolated test env.
SHELL_DIR := $(ROOT)/shell
DEV_HOME ?= $(ROOT)/.build/home
CONFIG_ROOT ?= $(DEV_HOME)/.config/ui-shell
CONFIG_FILE ?= $(CONFIG_ROOT)/manifest.ini
SETTINGS_FILE ?= $(CONFIG_ROOT)/settings.ini
CONFIG_READER ?= $(ROOT)/scripts/read-shell-config
INI_READER ?= $(ROOT)/scripts/read-ini
RUNTIME_PREPARER ?= $(ROOT)/scripts/prepare-runtime
RUNTIME_FILE ?= $(ROOT)/.build/runtime-path.log
QMLLINT ?= /usr/lib/qt6/bin/qmllint
REFS_DIR ?= $(ROOT)/refs
PHANTOMAT_DIR := $(ROOT)/refs/phantomat
PHANTOMAT_PLUGIN := $(ROOT)/.build/phantomat/spatialoverview.so

.PHONY: dev-release dev-check-update dev-shaders refs-pull dev-help dev-stage dev-seed-clipboard dev-seed-menu dev-configure dev-import-themes dev-bundle-themes dev-lint dev-shellcheck dev-verify-hypr dev-build-phantomat dev-verify-phantomat dev-run

dev-help:
	@printf '%s\n' \
		'Development (not the sandbox):' \
		'  dev-shaders          Rebuild the notification spoiler shader (needs qsb from qt6-shadertools)' \
		'  refs-pull             Pull reference repos; merges allowed, dirty repos skipped' \
		'  dev-release           Build a release from the working tree under .build/release/dev (no updater needed)' \
		'  dev-check-update      Build the dev release and rehearse it against a scratch copy of a clean user directory' \
		'  dev-stage            Stage runtime files privately under .build/' \
		'  dev-configure         Prepare the staged manifest and palettes' \
		'  dev-seed-clipboard    Write ~/.config/cliphist/config (history in the runtime dir) only if absent' \
		'  dev-seed-menu         Write ~/.local/share/applications/uuctl.desktop (asks through the shell menu) only if absent' \
		'  dev-import-themes     Regenerate reference definitions; explicit POSITIVE/WARNING/NEGATIVE required' \
		'  dev-bundle-themes     Maintainers: import, then refresh the checked-in bundled-themes/ (credit in CREDITS.md)' \
		'  dev-lint              Lint the shell QML with its generated files (override QMLLINT explicitly)' \
		'  dev-verify-hypr       Validate the staged production Hyprland config' \
		'  dev-build-phantomat   Build the reference plugin' \
		'  dev-verify-phantomat  Check the plugin build artifact' \
		'  dev-run               Run Quickshell on the HOST display, not in isolation'

refs-pull:
	@status=0; \
	for repo in "$(REFS_DIR)"/*; do \
		[[ -e "$$repo/.git" ]] || continue; \
		printf 'Pulling %s\n' "$$repo"; \
		if ! changes=$$(git -C "$$repo" status --porcelain); then status=1; continue; fi; \
		if [[ -n "$$changes" ]]; then \
			printf 'Skipped %s: local changes present.\n' "$$repo" >&2; \
			status=1; continue; \
		fi; \
		git -C "$$repo" pull --no-rebase --ff --no-edit || status=1; \
	done; \
	exit "$$status"

dev-release:
	@bash "$(ROOT)/tools/scripts/dev-release" "$(ROOT)" "$(ROOT)/.build"

dev-check-update:
	@bash "$(ROOT)/tools/scripts/dev-release" "$(ROOT)" "$(ROOT)/.build" --check

dev-stage:
	@bash "$(ROOT)/tools/scripts/stage-config" "$(ROOT)" "$(CONFIG_ROOT)"

# Writes the user's own cliphist config, so it is never part of staging; an existing file is kept.
dev-seed-clipboard:
	@bash "$(ROOT)/update/seed-cliphist-config" "$(ROOT)" "$${XDG_CONFIG_HOME:-$$HOME/.config}"

# Writes the user's own uuctl entry (outside staging), pointing at the staged scripts/menu that
# make dev-run uses; an existing file is kept.
dev-seed-menu: dev-stage
	@bash "$(ROOT)/update/seed-menu-entry" "$(ROOT)" "$(CONFIG_ROOT)/scripts/menu" "$${XDG_DATA_HOME:-$$HOME/.local/share}"

dev-configure: dev-stage
	@mkdir -p "$(ROOT)/.build"
	@resolved=$$(mktemp "$(ROOT)/.build/.paths.XXXXXX"); trap 'rm -f -- "$$resolved"' EXIT; \
	env HOME="$(DEV_HOME)" XDG_CONFIG_HOME="$(DEV_HOME)/.config" XDG_CACHE_HOME="$(DEV_HOME)/.cache" XDG_DATA_HOME="$(DEV_HOME)/.local/share" XDG_STATE_HOME="$(DEV_HOME)/.local/state" "$(CONFIG_READER)" "$(CONFIG_FILE)" "$(SETTINGS_FILE)" "$(INI_READER)" >"$$resolved"; \
	"$(RUNTIME_PREPARER)" "$$resolved" >"$(RUNTIME_FILE)"

# Terminal slots are not automatically semantic status colors.
dev-bundle-themes: dev-import-themes
	@bash "$(ROOT)/tools/scripts/bundle-reference-themes" "$(CONFIG_ROOT)/themes" "$(ROOT)/refs/100-themes" "$(ROOT)/bundled-themes"

dev-import-themes: dev-stage
	@test -n "$(POSITIVE)" -a -n "$(WARNING)" -a -n "$(NEGATIVE)" || { printf '%s\n' 'Set POSITIVE, WARNING and NEGATIVE explicitly.' >&2; exit 2; }
	@mkdir -p "$(ROOT)/.build"
	@resolved=$$(mktemp "$(ROOT)/.build/.import-paths.XXXXXX"); trap 'rm -f -- "$$resolved"' EXIT; \
	env HOME="$(DEV_HOME)" XDG_CONFIG_HOME="$(DEV_HOME)/.config" XDG_CACHE_HOME="$(DEV_HOME)/.cache" XDG_DATA_HOME="$(DEV_HOME)/.local/share" XDG_STATE_HOME="$(DEV_HOME)/.local/state" "$(CONFIG_READER)" "$(CONFIG_FILE)" "$(SETTINGS_FILE)" "$(INI_READER)" >"$$resolved"; \
	bash "$(ROOT)/tools/scripts/import-reference-themes" "$$resolved" "$(ROOT)/refs/100-themes" "$(POSITIVE)" "$(WARNING)" "$(NEGATIVE)"

dev-lint: dev-configure
	@runtime=$$(<"$(RUNTIME_FILE)"); bash "$(ROOT)/tools/scripts/lint-qml" "$(ROOT)" "$$(jq -r '.paths.runtime' "$$runtime")/config" "$(QMLLINT)"

dev-shellcheck:
	@files=$$(git -C "$(ROOT)" ls-files -co --exclude-standard | while read -r file; do [ -f "$(ROOT)/$$file" ] && head -n 1 "$(ROOT)/$$file" | grep -q '^#!.*bash' && printf '%s\n' "$$file"; done || true); \
	cd "$(ROOT)" && shellcheck -x -S warning $$files

dev-verify-hypr: dev-configure
	@runtime=$$(<"$(RUNTIME_FILE)"); env UI_SHELL_RUNTIME="$$runtime" UI_SHELL_RUNTIME_LUA="$$(jq -r '.runtimeLua' "$$runtime")" Hyprland --verify-config --config "$$(jq -r '.paths.hypr' "$$runtime")/hyprland.lua"

# The plugin's objects do not depend on Hyprland's headers, so after a Hyprland upgrade make would
# only relink them and the plugin would refuse to load ("Version mismatch"). Remember which
# Hyprland the objects were built against and rebuild them all when it changes.
PHANTOMAT_STAMP := $(PHANTOMAT_DIR)/.build/hyprland-build-stamp
dev-build-phantomat:
	@stamp=$$(pkg-config --modversion hyprland)-$$(for dir in $$(pkg-config --cflags-only-I hyprland | sed 's/-I//g'); do if [ -f "$$dir/src/version.h" ]; then sed -n 's/^#define GIT_COMMIT_HASH *"\(.*\)"/\1/p' "$$dir/src/version.h"; fi; done | head -n 1); \
	if [ "$$(cat "$(PHANTOMAT_STAMP)" 2>/dev/null)" != "$$stamp" ]; then \
		printf 'Hyprland changed (%s): rebuilding Phantomat from scratch.\n' "$$stamp"; \
		rm -rf -- "$(PHANTOMAT_DIR)/.build/obj"; \
	fi; \
	$(MAKE) -C "$(PHANTOMAT_DIR)" OUT="$(PHANTOMAT_PLUGIN)" -j2 all && mkdir -p "$(dir $(PHANTOMAT_STAMP))" && printf '%s' "$$stamp" >"$(PHANTOMAT_STAMP)"

dev-verify-phantomat: dev-build-phantomat
	@test -s "$(PHANTOMAT_PLUGIN)"
	@printf '%s\n' 'Phantomat build is ready. make test-env loads it automatically.'

dev-run: dev-configure
	@runtime=$$(<"$(RUNTIME_FILE)"); env UI_SHELL_RUNTIME="$$runtime" qs --no-duplicate --path "$$(jq -r '.paths.quickshell' "$$runtime")"

SPOILER_DIR := $(ROOT)/shell/modules/notifications/shaders
dev-shaders:
	@QSB=$$(command -v qsb || ls /usr/lib/qt6/bin/qsb 2>/dev/null); \
	[ -n "$$QSB" ] || { echo 'qsb not found: install qt6-shadertools' >&2; exit 1; }; \
	cd $(SPOILER_DIR) && "$$QSB" --qt6 --glsl "100es,120,150" --hlsl 50 --msl 12 -o spoiler.frag.qsb spoiler.frag && \
	sha256sum spoiler.frag | cut -d" " -f1 > spoiler.frag.sha256
