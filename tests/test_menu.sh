#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./test_helper.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/test_helper.sh"
# shellcheck source=../scripts/menu.sh
. "$NOTIV_ROOT/scripts/menu.sh"

test_menu_shows_actions_inside_notiv_session() {
	test_setup
	mock_option_set "@notiv_notes_dir" "~/notes"
	mock_option_set "@notiv_default_cmd" "nvim"
	notiv_session_ensure "notes" "$HOME/notes" "nvim" >/dev/null
	MOCK_CURRENT_SESSION="scratch-notiv"
	MOCK_CURRENT_WINDOW="notes"

	notiv_menu_show

	assert_file_contains "size down" "$TEST_TMP_DIR/display-menu.log" "menu should show size down option"
	assert_file_contains "size up" "$TEST_TMP_DIR/display-menu.log" "menu should show size up option"
	assert_file_contains "full screen" "$TEST_TMP_DIR/display-menu.log" "menu should show fullscreen option"
	assert_file_contains "reset size" "$TEST_TMP_DIR/display-menu.log" "menu should show reset option"
	assert_file_contains "embed in session" "$TEST_TMP_DIR/display-menu.log" "menu should show embed option"
	assert_file_contains "lock bindings" "$TEST_TMP_DIR/display-menu.log" "menu should show lock option"
	test_teardown
}

test_menu_shows_pop_outside_notiv_session() {
	test_setup
	mock_option_set "@notiv_notes_dir" "~/notes"
	mock_option_set "@notiv_default_cmd" "nvim"
	notiv_session_ensure "notes" "$HOME/notes" "nvim" >/dev/null

	notiv_menu_show

	assert_file_contains "pop current window" "$TEST_TMP_DIR/display-menu.log" "menu should show pop option outside notiv session"
	test_teardown
}

test_menu_shows_actions_inside_notiv_session
test_menu_shows_pop_outside_notiv_session
printf 'test_menu: ok\n'
