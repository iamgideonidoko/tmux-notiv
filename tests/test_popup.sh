#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./test_helper.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/test_helper.sh"

test_popup_opens_requested_context() {
	test_setup
	notiv_popup_open "notes" "/tmp/notes" "scratch-notiv:notes" "80%" "70%"
	assert_file_contains "display-popup -c client-1 -d /tmp/notes -x C -y C -w 80% -h 70% -T notiv:notes -E" "$MOCK_TMUX_LOG" "opening a context should create an auto-closing popup on the current client"
	assert_file_contains "attach-session -t scratch-notiv:notes" "$TEST_TMP_DIR/display-popup.log" "popup should attach to the requested context window"
	test_teardown
}

test_popup_tracks_last_client() {
	test_setup
	notiv_popup_open "notes" "/tmp/notes" "scratch-notiv:notes" "90%" "90%"
	assert_eq "client-1" "$(mock_option_get "@notiv_popup_notes_client")" "popup client should be stored"
	assert_eq "notes" "$(mock_option_get "@notiv_last_context")" "last context should be stored"
	test_teardown
}

test_popup_close_clears_active_popup() {
	test_setup
	notiv_popup_open "notes" "/tmp/notes" "scratch-notiv:notes" "90%" "90%"
	notiv_popup_close "notes"
	assert_file_contains "-C -c client-1" "$TEST_TMP_DIR/display-popup.log" "closing a context should close the popup on the current client"
	test_teardown
}

test_popup_close_detaches_inside_notiv_session() {
	test_setup
	mock_option_set "@notiv_popup_notes_client" "client-1"
	mock_set_current_target "scratch-notiv:notes"
	notiv_popup_close "notes"
	assert_file_contains "detach-client" "$MOCK_TMUX_LOG" "closing from inside the popup should detach the popup client"
	test_teardown
}

test_popup_opens_requested_context
test_popup_tracks_last_client
test_popup_close_clears_active_popup
test_popup_close_detaches_inside_notiv_session
printf 'test_popup: ok\n'
