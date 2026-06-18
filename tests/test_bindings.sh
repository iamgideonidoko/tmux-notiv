#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./test_helper.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/test_helper.sh"
# shellcheck source=../scripts/bindings.sh
. "$NOTIV_ROOT/scripts/bindings.sh"

test_default_bindings_exist() {
	test_setup
	mock_option_set "@notiv_notes_dir" "~/notes"
	mock_option_set "@notiv_todo_dir" "~/todo"
	mock_option_set "@notiv_git_dir" "~/src/project"
	mock_option_set "@notiv_notes_key" "n"
	mock_option_set "@notiv_todo_key" "t"
	mock_option_set "@notiv_git_key" "g"

	notiv_bindings

	assert_eq "1" "$(mock_binding_count "prefix" "n")" "prefix namespace entry should exist"
	assert_eq "switch-client -T notiv" "$(mock_binding_command "prefix" "n")" "prefix n should switch into the notiv key table"
	assert_contains "toggle notes" "$(mock_binding_command "notiv" "n")" "notes binding should exist"
	assert_contains "toggle todo" "$(mock_binding_command "notiv" "t")" "todo binding should exist"
	assert_contains "toggle git" "$(mock_binding_command "notiv" "g")" "git binding should exist"
	assert_contains "list" "$(mock_binding_command "notiv" "l")" "list binding should exist"
	assert_contains "picker" "$(mock_binding_command "notiv" "p")" "picker binding should exist"
	test_teardown
}

test_context_key_override_works() {
	test_setup
	mock_option_set "@notiv_notes_dir" "~/notes"
	mock_option_set "@notiv_notes_key" "x"

	notiv_bindings

	assert_eq "0" "$(mock_binding_count "notiv" "n")" "default notes key should not remain bound after override"
	assert_eq "1" "$(mock_binding_count "notiv" "x")" "override key should be bound once"
	assert_contains "toggle notes" "$(mock_binding_command "notiv" "x")" "override key should target notes"
	test_teardown
}

test_idempotency_does_not_duplicate_bindings() {
	test_setup
	mock_option_set "@notiv_notes_dir" "~/notes"
	mock_option_set "@notiv_todo_dir" "~/todo"
	mock_option_set "@notiv_notes_key" "n"
	mock_option_set "@notiv_todo_key" "t"

	notiv_bindings
	notiv_bindings

	assert_eq "1" "$(mock_binding_count "prefix" "n")" "namespace entry should remain singular after repeated loads"
	assert_eq "1" "$(mock_binding_count "notiv" "n")" "notes binding should remain singular after repeated loads"
	assert_eq "1" "$(mock_binding_count "notiv" "t")" "todo binding should remain singular after repeated loads"
	assert_eq "1" "$(mock_binding_count "notiv" "l")" "list binding should remain singular after repeated loads"
	test_teardown
}

test_reload_rebinds_cleanly() {
	test_setup
	mock_option_set "@notiv_notes_dir" "~/notes"
	mock_option_set "@notiv_notes_key" "n"

	notiv_bindings
	mock_option_set "@notiv_notes_key" "x"
	notiv_bindings_main reload

	assert_eq "0" "$(mock_binding_count "notiv" "n")" "old notes key should be removed on reload"
	assert_eq "1" "$(mock_binding_count "notiv" "x")" "new notes key should be present on reload"
	assert_contains "toggle notes" "$(mock_binding_command "notiv" "x")" "reloaded binding should still target notes"
	test_teardown
}

test_only_contexts_with_keys_are_bound() {
	test_setup
	mock_option_set "@notiv_notes_dir" "~/notes"
	mock_option_set "@notiv_todo_dir" "~/todo"
	mock_option_set "@notiv_todo_key" "t"

	notiv_bindings

	assert_eq "0" "$(mock_binding_count "notiv" "n")" "notes should not be bound without an explicit key"
	assert_eq "1" "$(mock_binding_count "notiv" "t")" "todo should be bound when context and key exist"
	assert_eq "0" "$(mock_binding_count "notiv" "g")" "git should not be bound without an explicit key"
	test_teardown
}

test_default_bindings_exist
test_context_key_override_works
test_idempotency_does_not_duplicate_bindings
test_reload_rebinds_cleanly
test_only_contexts_with_keys_are_bound
printf 'test_bindings: ok\n'
