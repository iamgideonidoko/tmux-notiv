#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./test_helper.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/test_helper.sh"

test_popup_uses_requested_dimensions() {
	test_setup
	notiv_popup_open "notes" "/tmp/notes" "scratch-notes" "80%" "70%"
	assert_file_contains "-w 80%" "$TEST_TMP_DIR/display-popup.log" "popup width should be passed through"
	assert_file_contains "-h 70%" "$TEST_TMP_DIR/display-popup.log" "popup height should be passed through"
	assert_file_contains "-x C -y C" "$TEST_TMP_DIR/display-popup.log" "popup should be centered"
	assert_file_contains "attach-session -t scratch-notes" "$TEST_TMP_DIR/display-popup.log" "popup should attach to the target session"
	test_teardown
}

test_popup_tracks_last_client() {
	test_setup
	notiv_popup_open "notes" "/tmp/notes" "scratch-notes" "90%" "90%"
	assert_eq "client-1" "$(mock_option_get "@notiv_popup_notes_client")" "popup client should be stored"
	assert_eq "notes" "$(mock_option_get "@notiv_last_context")" "last context should be stored"
	test_teardown
}

test_popup_uses_requested_dimensions
test_popup_tracks_last_client
printf 'test_popup: ok\n'
