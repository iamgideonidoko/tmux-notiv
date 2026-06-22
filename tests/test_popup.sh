#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./test_helper.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/test_helper.sh"

test_popup_switches_client_to_context_window() {
	test_setup
	notiv_popup_open "notes" "/tmp/notes" "scratch-notiv:notes" "80%" "70%"
	assert_file_contains "switch-client -c client-1 -t scratch-notiv:notes" "$MOCK_TMUX_LOG" "opening a context should switch the current client to its window"
	assert_eq "workspace:main" "$(mock_option_get "@notiv_client_client-1_return_target")" "opening from a non-notiv target should remember where to return"
	test_teardown
}

test_popup_tracks_last_client() {
	test_setup
	notiv_popup_open "notes" "/tmp/notes" "scratch-notiv:notes" "90%" "90%"
	assert_eq "client-1" "$(mock_option_get "@notiv_popup_notes_client")" "popup client should be stored"
	assert_eq "notes" "$(mock_option_get "@notiv_last_context")" "last context should be stored"
	test_teardown
}

test_popup_close_returns_client_to_previous_target() {
	test_setup
	notiv_popup_open "notes" "/tmp/notes" "scratch-notiv:notes" "90%" "90%"
	notiv_popup_close "notes"
	assert_file_contains "switch-client -c client-1 -t workspace:main" "$MOCK_TMUX_LOG" "closing a context should return to the previous client target"
	test_teardown
}

test_popup_switches_client_to_context_window
test_popup_tracks_last_client
test_popup_close_returns_client_to_previous_target
printf 'test_popup: ok\n'
