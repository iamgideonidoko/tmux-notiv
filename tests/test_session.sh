#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./test_helper.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/test_helper.sh"

test_creates_session_if_missing() {
	test_setup
	notiv_session_ensure "notes" "/tmp/notes" "nvim" >/dev/null
	assert_file_contains "new-session -d -s scratch-notes -c /tmp/notes nvim" "$MOCK_TMUX_LOG" "session should be created when missing"
	test_teardown
}

test_does_not_recreate_existing_session() {
	test_setup
	notiv_session_ensure "notes" "/tmp/notes" "nvim" >/dev/null
	notiv_session_ensure "notes" "/tmp/notes" "nvim" >/dev/null
	assert_file_line_count "1" "new-session -d -s scratch-notes -c /tmp/notes nvim" "$MOCK_TMUX_LOG" "existing session should be reused"
	test_teardown
}

test_creates_session_if_missing
test_does_not_recreate_existing_session
printf 'test_session: ok\n'
