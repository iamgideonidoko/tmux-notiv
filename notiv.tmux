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
notiv_set_default_option "@notiv_border_color" "magenta"
notiv_set_default_option "@notiv_text_color" "blue"
notiv_set_default_option "@notiv_border_style" "rounded"
notiv_set_default_option "@notiv_change_path" "true"
notiv_set_default_option "@notiv_key_prefix" "n"
notiv_set_default_option "@notiv_key_menu" "P"
notiv_set_default_option "@notiv_root_bindings" "true"
notiv_set_default_option "@notiv_key_zoom_in" "C-M-s"
notiv_set_default_option "@notiv_key_zoom_out" "C-M-b"
notiv_set_default_option "@notiv_key_fullscreen" "C-M-f"
notiv_set_default_option "@notiv_key_reset" "C-M-r"
notiv_set_default_option "@notiv_key_embed" "C-M-e"
notiv_set_default_option "@notiv_key_lock" "C-M-d"
notiv_set_default_option "@notiv_key_unlock" "C-M-u"

notiv_registry_reload >/dev/null 2>&1 || true
notiv_bindings
