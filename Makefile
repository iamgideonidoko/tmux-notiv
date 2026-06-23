SHELL := /usr/bin/env bash

FILES := \
	notiv \
	notiv.tmux \
	scripts/bindings.sh \
	scripts/cli.sh \
	scripts/config.sh \
	scripts/registry.sh \
	scripts/session.sh \
	scripts/toggle.sh \
	scripts/zoom.sh \
	scripts/embed.sh \
	scripts/menu.sh \
	lib/core.sh \
	lib/popup.sh \
	lib/state.sh \
	lib/util.sh \
	tests/test_helper.sh \
	tests/test_integration.sh \
	tests/test_bindings.sh \
	tests/test_popup.sh \
	tests/test_registry.sh \
	tests/test_session.sh \
	tests/test_toggle.sh \
	tests/test_zoom.sh \
	tests/test_embed.sh \
	tests/test_menu.sh

.PHONY: test syntax unit integration

test: syntax unit integration

syntax:
	@set -e; for file in $(FILES); do \
		bash -n "$$file"; \
	done
	@echo "syntax: ok"

unit:
	@set -e; for test_file in tests/test_session.sh tests/test_registry.sh tests/test_popup.sh tests/test_toggle.sh tests/test_bindings.sh tests/test_zoom.sh tests/test_embed.sh tests/test_menu.sh; do \
		bash "$$test_file"; \
	done
	@echo "unit: ok"

integration:
	@if [ "$${NOTIV_RUN_INTEGRATION:-0}" = "1" ]; then \
		bash tests/test_integration.sh; \
	else \
		echo "integration: skipped (set NOTIV_RUN_INTEGRATION=1 to enable)"; \
	fi
