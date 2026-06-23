#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./test_helper.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/test_helper.sh"
# shellcheck source=../scripts/zoom.sh
. "$NOTIV_ROOT/scripts/zoom.sh"

zoom_test_setup_context() {
	mock_option_set "@notiv_notes_dir" "~/notes"
	mock_option_set "@notiv_default_cmd" "nvim"
	mock_option_set "@notiv_popup_width" "90%"
	mock_option_set "@notiv_popup_height" "90%"
	notiv_session_ensure "notes" "$HOME/notes" "nvim" >/dev/null
	notiv_state_set_last_context "notes"
	notiv_state_set_popup_client "notes" "$MOCK_CURRENT_CLIENT"
	notiv_state_set_origin_session "$MOCK_CURRENT_CLIENT" "$MOCK_CURRENT_SESSION"
	MOCK_WINDOW_WIDTH="100"
	MOCK_WINDOW_HEIGHT="30"
	MOCK_ORIGIN_WIDTH="200"
	MOCK_ORIGIN_HEIGHT="50"
}

test_zoom_in_sets_env_vars_and_reopens() {
	test_setup
	zoom_test_setup_context
	MOCK_CURRENT_SESSION="scratch-notiv"
	MOCK_CURRENT_WINDOW="notes"

	notiv_zoom_resize -5

	assert_eq "95" "$(mock_env_get NOTIV_WIDTH)" "zoom in should decrease width by 5"
	assert_eq "25" "$(mock_env_get NOTIV_HEIGHT)" "zoom in should decrease height by 5"
	assert_file_contains "detach-client" "$MOCK_TMUX_LOG" "zoom in should detach the client"
	assert_file_contains "display-popup" "$MOCK_TMUX_LOG" "zoom in should reopen the popup"
	test_teardown
}

test_zoom_out_sets_env_vars_and_reopens() {
	test_setup
	zoom_test_setup_context
	MOCK_CURRENT_SESSION="scratch-notiv"
	MOCK_CURRENT_WINDOW="notes"

	notiv_zoom_resize 5

	assert_eq "105" "$(mock_env_get NOTIV_WIDTH)" "zoom out should increase width by 5"
	assert_eq "35" "$(mock_env_get NOTIV_HEIGHT)" "zoom out should increase height by 5"
	assert_file_contains "detach-client" "$MOCK_TMUX_LOG" "zoom out should detach the client"
	test_teardown
}

test_zoom_out_does_not_exceed_origin_size() {
	test_setup
	zoom_test_setup_context
	MOCK_WINDOW_WIDTH="200"
	MOCK_WINDOW_HEIGHT="50"
	MOCK_CURRENT_SESSION="scratch-notiv"
	MOCK_CURRENT_WINDOW="notes"

	notiv_zoom_resize 5

	assert_eq "" "$(mock_env_get NOTIV_WIDTH)" "zoom out should not set width beyond origin"
	assert_eq "" "$(mock_env_get NOTIV_HEIGHT)" "zoom out should not set height beyond origin"
	test_teardown
}

test_zoom_fullscreen_sets_100_percent() {
	test_setup
	zoom_test_setup_context
	MOCK_CURRENT_SESSION="scratch-notiv"
	MOCK_CURRENT_WINDOW="notes"

	notiv_zoom_fullscreen

	assert_eq "100%" "$(mock_env_get NOTIV_WIDTH)" "fullscreen should set width to 100%"
	assert_eq "100%" "$(mock_env_get NOTIV_HEIGHT)" "fullscreen should set height to 100%"
	assert_file_contains "detach-client" "$MOCK_TMUX_LOG" "fullscreen should detach the client"
	test_teardown
}

test_zoom_reset_clears_env_vars() {
	test_setup
	zoom_test_setup_context
	mock_env_set NOTIV_WIDTH "195"
	mock_env_set NOTIV_HEIGHT "45"
	MOCK_CURRENT_SESSION="scratch-notiv"
	MOCK_CURRENT_WINDOW="notes"

	notiv_zoom_reset

	assert_eq "" "$(mock_env_get NOTIV_WIDTH)" "reset should clear NOTIV_WIDTH"
	assert_eq "" "$(mock_env_get NOTIV_HEIGHT)" "reset should clear NOTIV_HEIGHT"
	assert_file_contains "detach-client" "$MOCK_TMUX_LOG" "reset should detach the client"
	test_teardown
}

test_zoom_lock_sets_locked_state() {
	test_setup
	zoom_test_setup_context
	MOCK_CURRENT_SESSION="scratch-notiv"
	MOCK_CURRENT_WINDOW="notes"

	notiv_zoom_lock

	assert_eq "true" "$(mock_option_get "@notiv_bindings_locked")" "lock should set bindings locked state"
	assert_contains "Bindings locked" "$(mock_env_get NOTIV_TITLE_OVERRIDE)" "lock should set locked title override"
	assert_file_contains "detach-client" "$MOCK_TMUX_LOG" "lock should detach the client"
	test_teardown
}

test_zoom_unlock_clears_locked_state() {
	test_setup
	zoom_test_setup_context
	mock_option_set "@notiv_bindings_locked" "true"
	mock_env_set NOTIV_TITLE_OVERRIDE "locked title"
	MOCK_CURRENT_SESSION="scratch-notiv"
	MOCK_CURRENT_WINDOW="notes"

	notiv_zoom_unlock

	assert_eq "false" "$(mock_option_get "@notiv_bindings_locked")" "unlock should clear locked state"
	assert_eq "" "$(mock_env_get NOTIV_TITLE_OVERRIDE)" "unlock should clear title override"
	assert_file_contains "detach-client" "$MOCK_TMUX_LOG" "unlock should detach the client"
	test_teardown
}

test_zoom_in_sets_env_vars_and_reopens
test_zoom_out_sets_env_vars_and_reopens
test_zoom_out_does_not_exceed_origin_size
test_zoom_fullscreen_sets_100_percent
test_zoom_reset_clears_env_vars
test_zoom_lock_sets_locked_state
test_zoom_unlock_clears_locked_state
printf 'test_zoom: ok\n'
