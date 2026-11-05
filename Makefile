SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

ROOT := $(CURDIR)
.DEFAULT_GOAL := help
.PHONY: help

include $(ROOT)/tools/development.mk
include $(ROOT)/tests/targets.mk

help:
	@printf '%s\n' \
		'Start here: make test-env' \
		'Private nested Hyprland with saved test preferences/cache. Exit: Super+Shift+Escape.' \
		''
	@$(MAKE) --no-print-directory test-help dev-help
