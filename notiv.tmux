#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

tmux set-option -gq @notiv_plugin_path "$ROOT_DIR"
tmux set-option -gq @notiv_default_cmd "nvim"
tmux set-option -gq @notiv_popup_width "90%"
tmux set-option -gq @notiv_popup_height "90%"

"$ROOT_DIR/scripts/cli.sh" reload >/dev/null 2>&1 || true
