#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./test_helper.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/test_helper.sh"

test_toggle_opens_popup() {
	test_setup
	mock_option_set "@notiv_notes_dir" "~/notes"
	mock_option_set "@notiv_default_cmd" "nvim"
	mock_option_set "@notiv_popup_width" "90%"
	mock_option_set "@notiv_popup_height" "90%"

	notiv_toggle_context "notes"
	assert_file_contains "new-session -d -s scratch-notes -c $HOME/notes nvim" "$MOCK_TMUX_LOG" "toggle should create the session when needed"
	assert_file_contains "display-popup -c client-1 -d $HOME/notes -x C -y C -w 90% -h 90% -T notiv:notes" "$MOCK_TMUX_LOG" "toggle should open the popup"
	test_teardown
}

test_toggle_reuses_session() {
	test_setup
	mock_option_set "@notiv_notes_dir" "~/notes"
	mock_option_set "@notiv_default_cmd" "nvim"

	notiv_toggle_context "notes"
	notiv_toggle_context "notes"
	assert_file_line_count "1" "new-session -d -s scratch-notes -c $HOME/notes nvim" "$MOCK_TMUX_LOG" "toggle should reuse the existing session"
	assert_file_line_count "2" "display-popup -c client-1 -d $HOME/notes" "$MOCK_TMUX_LOG" "toggle should reopen or refocus the popup on reuse"
	test_teardown
}

test_toggle_opens_popup
test_toggle_reuses_session
printf 'test_toggle: ok\n'
