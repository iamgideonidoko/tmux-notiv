#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
export NOTIV_ROOT="${NOTIV_ROOT:-$ROOT_DIR}"

# shellcheck source=./lib/state.sh
. "$ROOT_DIR/lib/state.sh"
# shellcheck source=./scripts/registry.sh
. "$ROOT_DIR/scripts/registry.sh"
# shellcheck source=./scripts/bindings.sh
. "$ROOT_DIR/scripts/bindings.sh"

notiv_set_option "@notiv_plugin_path" "$ROOT_DIR"
notiv_set_default_option "@notiv_session_name" "scratch-notiv"
notiv_set_default_option "@notiv_default_cmd" "nvim"
notiv_set_default_option "@notiv_popup_width" "90%"
notiv_set_default_option "@notiv_popup_height" "90%"

notiv_registry_reload >/dev/null 2>&1 || true
notiv_bindings
