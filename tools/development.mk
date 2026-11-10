# Checkout development only. These targets never launch the isolated test env.
SHELL_DIR := $(ROOT)/shell
DEV_HOME ?= $(ROOT)/.build/home
CONFIG_ROOT ?= $(DEV_HOME)/.config/ui-shell
CONFIG_FILE ?= $(CONFIG_ROOT)/config.ini
CONFIG_READER ?= $(ROOT)/scripts/read-shell-config
INI_READER ?= $(ROOT)/scripts/read-ini
RUNTIME_PREPARER ?= $(ROOT)/scripts/prepare-runtime
RUNTIME_FILE ?= $(ROOT)/.build/runtime-path.log
QMLLINT ?= /usr/lib/qt6/bin/qmllint
QML_FILES := $(shell find "$(SHELL_DIR)" -type f -name '*.qml' -print)
REFS_DIR ?= $(ROOT)/refs
PHANTOMAT_DIR := $(ROOT)/refs/phantomat
PHANTOMAT_PLUGIN := $(ROOT)/.build/phantomat/spatialoverview.so

.PHONY: dev-shaders refs-pull dev-help dev-stage dev-configure dev-import-themes dev-bundle-themes dev-lint dev-verify-hypr dev-build-phantomat dev-verify-phantomat dev-run

dev-help:
	@printf '%s\n' \
		'Development (not the sandbox):' \
		'  dev-shaders          Rebuild the notification spoiler shader (needs qsb from qt6-shadertools)' \
		'  refs-pull             Pull reference repos; merges allowed, dirty repos skipped' \
		'  dev-stage             Stage runtime files privately under .build/' \
		'  dev-configure         Prepare the staged manifest and palettes' \
		'  dev-import-themes     Regenerate reference definitions; explicit POSITIVE/WARNING/NEGATIVE required' \
		'  dev-bundle-themes     Maintainers: import, then refresh the checked-in bundled-themes/ (credit in CREDITS.md)' \
		'  dev-lint              Check source QML (override QMLLINT explicitly)' \
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

dev-stage:
	@bash "$(ROOT)/tools/scripts/stage-config" "$(ROOT)" "$(CONFIG_ROOT)"

dev-configure: dev-stage
	@mkdir -p "$(ROOT)/.build"
	@resolved=$$(mktemp "$(ROOT)/.build/.paths.XXXXXX"); trap 'rm -f -- "$$resolved"' EXIT; \
	env HOME="$(DEV_HOME)" XDG_CONFIG_HOME="$(DEV_HOME)/.config" XDG_CACHE_HOME="$(DEV_HOME)/.cache" XDG_DATA_HOME="$(DEV_HOME)/.local/share" XDG_STATE_HOME="$(DEV_HOME)/.local/state" "$(CONFIG_READER)" "$(CONFIG_FILE)" "$(INI_READER)" >"$$resolved"; \
	"$(RUNTIME_PREPARER)" "$$resolved" >"$(RUNTIME_FILE)"

# Terminal slots are not automatically semantic status colors.
dev-bundle-themes: dev-import-themes
	@bash "$(ROOT)/tools/scripts/bundle-reference-themes" "$(CONFIG_ROOT)/themes" "$(ROOT)/refs/100-themes" "$(ROOT)/bundled-themes"

dev-import-themes: dev-stage
	@test -n "$(POSITIVE)" -a -n "$(WARNING)" -a -n "$(NEGATIVE)" || { printf '%s\n' 'Set POSITIVE, WARNING and NEGATIVE explicitly.' >&2; exit 2; }
	@mkdir -p "$(ROOT)/.build"
	@resolved=$$(mktemp "$(ROOT)/.build/.import-paths.XXXXXX"); trap 'rm -f -- "$$resolved"' EXIT; \
	env HOME="$(DEV_HOME)" XDG_CONFIG_HOME="$(DEV_HOME)/.config" XDG_CACHE_HOME="$(DEV_HOME)/.cache" XDG_DATA_HOME="$(DEV_HOME)/.local/share" XDG_STATE_HOME="$(DEV_HOME)/.local/state" "$(CONFIG_READER)" "$(CONFIG_FILE)" "$(INI_READER)" >"$$resolved"; \
	bash "$(ROOT)/tools/scripts/import-reference-themes" "$$resolved" "$(ROOT)/refs/100-themes" "$(POSITIVE)" "$(WARNING)" "$(NEGATIVE)"

dev-lint:
	@"$(QMLLINT)" $(QML_FILES)

dev-verify-hypr: dev-configure
	@runtime=$$(<"$(RUNTIME_FILE)"); env UI_SHELL_RUNTIME="$$runtime" UI_SHELL_RUNTIME_LUA="$$(jq -r '.runtimeLua' "$$runtime")" Hyprland --verify-config --config "$$(jq -r '.paths.hypr' "$$runtime")/hyprland.lua"

dev-build-phantomat:
	@$(MAKE) -C "$(PHANTOMAT_DIR)" OUT="$(PHANTOMAT_PLUGIN)" -j2 all

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
