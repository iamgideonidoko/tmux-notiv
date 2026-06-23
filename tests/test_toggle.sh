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
	assert_file_contains "new-session -d -s scratch-notiv -n notes -c $HOME/notes nvim" "$MOCK_TMUX_LOG" "toggle should create the shared session and context window when needed"
	assert_file_contains "display-popup" "$MOCK_TMUX_LOG" "toggle should open the resolved context in a popup"
	assert_file_contains "-c client-1" "$MOCK_TMUX_LOG" "popup should target the current client"
	assert_file_contains "-d $HOME/notes" "$MOCK_TMUX_LOG" "popup should use the context directory"
	assert_file_contains "-w 90%" "$MOCK_TMUX_LOG" "popup should use the configured width"
	assert_file_contains "-h 90%" "$MOCK_TMUX_LOG" "popup should use the configured height"
	assert_file_contains "attach-session -t scratch-notiv:notes" "$TEST_TMP_DIR/display-popup.log" "popup should attach to the context window"
	test_teardown
}

test_toggle_closes_same_context_inside_popup() {
	test_setup
	mock_option_set "@notiv_notes_dir" "~/notes"
	mock_option_set "@notiv_default_cmd" "nvim"
	notiv_session_ensure "notes" "$HOME/notes" "nvim" >/dev/null
	mock_option_set "@notiv_popup_notes_client" "client-1"
	mock_set_current_target "scratch-notiv:notes"
	notiv_toggle_context "notes"
	assert_file_contains "detach-client" "$MOCK_TMUX_LOG" "repeating the same mapping inside the popup should detach and close it"
	test_teardown
}

test_toggle_switches_between_context_windows_inside_popup() {
	test_setup
	mock_option_set "@notiv_notes_dir" "~/notes"
	mock_option_set "@notiv_todo_dir" "~/todo"
	mock_option_set "@notiv_default_cmd" "nvim"
	notiv_session_ensure "notes" "$HOME/notes" "nvim" >/dev/null
	notiv_session_ensure "todo" "$HOME/todo" "nvim" >/dev/null
	mock_set_current_target "scratch-notiv:notes"
	notiv_toggle_context "todo"
	assert_file_contains "select-window -t scratch-notiv:todo" "$MOCK_TMUX_LOG" "switching contexts inside the popup should select the matching window"
	assert_eq "todo" "$(mock_option_get "@notiv_last_context")" "switching contexts inside the popup should track the new last context"
	test_teardown
}

test_toggle_opens_popup
test_toggle_closes_same_context_inside_popup
test_toggle_switches_between_context_windows_inside_popup
printf 'test_toggle: ok\n'
