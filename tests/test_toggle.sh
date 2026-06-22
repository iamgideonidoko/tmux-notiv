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
	assert_file_contains "display-popup -c client-1 -d $HOME/notes -x C -y C -w 90% -h 90% -T notiv:notes" "$MOCK_TMUX_LOG" "toggle should open the resolved context in a popup"
	test_teardown
}

test_toggle_closes_same_popup_on_repeat() {
	test_setup
	mock_option_set "@notiv_notes_dir" "~/notes"
	mock_option_set "@notiv_default_cmd" "nvim"
	mock_option_set "@notiv_popup_width" "90%"
	mock_option_set "@notiv_popup_height" "90%"

	notiv_toggle_context "notes"
	notiv_toggle_context "notes"
	assert_file_line_count "1" "new-session -d -s scratch-notiv -n notes -c $HOME/notes nvim" "$MOCK_TMUX_LOG" "toggle should reuse the existing shared session"
	assert_file_contains "-C -c client-1" "$TEST_TMP_DIR/display-popup.log" "repeating the same mapping should close the active popup"
	test_teardown
}

test_toggle_switches_between_context_popups() {
	test_setup
	mock_option_set "@notiv_notes_dir" "~/notes"
	mock_option_set "@notiv_todo_dir" "~/todo"
	mock_option_set "@notiv_default_cmd" "nvim"
	mock_option_set "@notiv_popup_width" "90%"
	mock_option_set "@notiv_popup_height" "90%"

	notiv_toggle_context "notes"
	notiv_toggle_context "todo"
	assert_file_contains "-C -c client-1" "$TEST_TMP_DIR/display-popup.log" "opening another context should close the current popup first"
	assert_file_contains "attach-session -t scratch-notiv:todo" "$TEST_TMP_DIR/display-popup.log" "opening another context should retarget the popup to the requested window"
	test_teardown
}

test_toggle_opens_popup
test_toggle_closes_same_popup_on_repeat
test_toggle_switches_between_context_popups
printf 'test_toggle: ok\n'
