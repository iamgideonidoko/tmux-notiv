#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./test_helper.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/test_helper.sh"
# shellcheck source=../scripts/embed.sh
. "$NOTIV_ROOT/scripts/embed.sh"

embed_test_setup() {
	mock_option_set "@notiv_notes_dir" "~/notes"
	mock_option_set "@notiv_default_cmd" "nvim"
	mock_option_set "@notiv_popup_width" "90%"
	mock_option_set "@notiv_popup_height" "90%"
	notiv_session_ensure "notes" "$HOME/notes" "nvim" >/dev/null
	notiv_state_set_last_context "notes"
	notiv_state_set_popup_client "notes" "$MOCK_CURRENT_CLIENT"
	notiv_state_set_origin_session "$MOCK_CURRENT_CLIENT" "workspace"
}

test_embed_moves_window_to_origin_session() {
	test_setup
	embed_test_setup
	MOCK_CURRENT_SESSION="scratch-notiv"
	MOCK_CURRENT_WINDOW="notes"

	notiv_embed_embed

	assert_file_contains "movew -t workspace" "$MOCK_TMUX_LOG" "embed should move the current window to the origin session"
	assert_file_contains "detach-client" "$MOCK_TMUX_LOG" "embed should detach the client"
	test_teardown
}

test_embed_creates_placeholder_when_only_one_window() {
	test_setup
	embed_test_setup
	MOCK_CURRENT_SESSION="scratch-notiv"
	MOCK_CURRENT_WINDOW="notes"

	notiv_embed_embed

	assert_file_contains "new-window -d -t scratch-notiv" "$MOCK_TMUX_LOG" "embed should create a placeholder window when only one window remains"
	test_teardown
}

test_embed_does_not_create_placeholder_when_multiple_windows() {
	test_setup
	embed_test_setup
	notiv_session_ensure "todo" "$HOME/todo" "nvim" >/dev/null
	MOCK_CURRENT_SESSION="scratch-notiv"
	MOCK_CURRENT_WINDOW="notes"

	notiv_embed_embed

	local new_window_count
	new_window_count="$(grep -F -x -c -- "new-window -d -t scratch-notiv" "$MOCK_TMUX_LOG" 2>/dev/null || true)"
	assert_eq "0" "$new_window_count" "embed should not create a placeholder when multiple windows exist"
	test_teardown
}

test_embed_unsets_root_bindings() {
	test_setup
	embed_test_setup
	notiv_popup_set_root_bindings
	assert_eq "1" "$(mock_binding_count "root" "C-M-s")" "root binding should exist before embed"
	MOCK_CURRENT_SESSION="scratch-notiv"
	MOCK_CURRENT_WINDOW="notes"

	notiv_embed_embed

	assert_eq "0" "$(mock_binding_count "root" "C-M-s")" "root bindings should be unset after embed"
	test_teardown
}

test_pop_moves_window_to_notiv_session() {
	test_setup
	embed_test_setup
	MOCK_CURRENT_SESSION="workspace"
	MOCK_CURRENT_WINDOW="notes"

	notiv_embed_pop

	assert_file_contains "movew -t scratch-notiv" "$MOCK_TMUX_LOG" "pop should move the current window to the notiv session"
	assert_file_contains "display-popup" "$MOCK_TMUX_LOG" "pop should reopen the popup"
	test_teardown
}

test_embed_moves_window_to_origin_session
test_embed_creates_placeholder_when_only_one_window
test_embed_does_not_create_placeholder_when_multiple_windows
test_embed_unsets_root_bindings
test_pop_moves_window_to_notiv_session
printf 'test_embed: ok\n'
