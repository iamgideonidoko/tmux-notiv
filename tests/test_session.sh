#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./test_helper.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/test_helper.sh"

test_creates_session_if_missing() {
	test_setup
	notiv_session_ensure "notes" "/tmp/notes" "nvim" >/dev/null
	assert_file_contains "new-session -d -s scratch-notiv -n notes -c /tmp/notes nvim" "$MOCK_TMUX_LOG" "global session should be created with a notes window when missing"
	test_teardown
}

test_does_not_recreate_existing_session() {
	test_setup
	notiv_session_ensure "notes" "/tmp/notes" "nvim" >/dev/null
	notiv_session_ensure "notes" "/tmp/notes" "nvim" >/dev/null
	assert_file_line_count "1" "new-session -d -s scratch-notiv -n notes -c /tmp/notes nvim" "$MOCK_TMUX_LOG" "existing global session and window should be reused"
	test_teardown
}

test_creates_new_window_in_existing_session() {
	test_setup
	notiv_session_ensure "notes" "/tmp/notes" "nvim" >/dev/null
	notiv_session_ensure "todo" "/tmp/todo" "vim" >/dev/null
	assert_file_contains "new-window -d -t scratch-notiv -n todo -c /tmp/todo vim" "$MOCK_TMUX_LOG" "new contexts should be created as windows in the global session"
	test_teardown
}

test_recreates_window_when_mapping_changes() {
	test_setup
	notiv_session_ensure "notes" "/tmp/notes" "nvim" >/dev/null
	notiv_session_ensure "notes" "/tmp/wiki" "hx" >/dev/null
	assert_file_contains "kill-window -t scratch-notiv:notes" "$MOCK_TMUX_LOG" "window should be recreated when the resolved mapping changes"
	assert_file_contains "-n notes -c /tmp/wiki hx" "$MOCK_TMUX_LOG" "recreated window should use the new directory and command"
	test_teardown
}

test_creates_session_if_missing
test_does_not_recreate_existing_session
test_creates_new_window_in_existing_session
test_recreates_window_when_mapping_changes
printf 'test_session: ok\n'
