#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=./test_helper.sh
. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/test_helper.sh"

test_auto_register_parses_config() {
	test_setup
	mock_option_set "@notiv_auto_register" "notes:~/notes:nvim,todo:~/todo:nvim"
	mock_option_set "@notiv_popup_width" "90%"
	mock_option_set "@notiv_popup_height" "90%"

	local names record dir cmd width height
	names="$(notiv_registry_reload)"
	assert_contains "notes" "$names" "notes should be registered"
	assert_contains "todo" "$names" "todo should be registered"

	record="$(notiv_registry_resolve "todo")"
	dir="$(notiv_record_field "$record" 2)"
	cmd="$(notiv_record_field "$record" 3)"
	width="$(notiv_record_field "$record" 4)"
	height="$(notiv_record_field "$record" 5)"

	assert_eq "$HOME/todo" "$dir" "registry should expand the configured directory"
	assert_eq "nvim" "$cmd" "registry should preserve the configured command"
	assert_eq "90%" "$width" "registry should apply the default popup width"
	assert_eq "90%" "$height" "registry should apply the default popup height"
	test_teardown
}

test_explicit_context_overrides_auto_register() {
	test_setup
	mock_option_set "@notiv_auto_register" "git:~/src/project:lazygit:95%:95%"
	mock_option_set "@notiv_git_dir" "~/worktree"
	mock_option_set "@notiv_git_cmd" "tig"
	mock_option_set "@notiv_git_width" "80%"
	mock_option_set "@notiv_git_height" "70%"

	local record dir cmd width height
	record="$(notiv_registry_resolve "git")"
	dir="$(notiv_record_field "$record" 2)"
	cmd="$(notiv_record_field "$record" 3)"
	width="$(notiv_record_field "$record" 4)"
	height="$(notiv_record_field "$record" 5)"

	assert_eq "$HOME/worktree" "$dir" "explicit dir should override auto register"
	assert_eq "tig" "$cmd" "explicit command should override auto register"
	assert_eq "80%" "$width" "explicit width should override auto register"
	assert_eq "70%" "$height" "explicit height should override auto register"
	test_teardown
}

test_auto_register_parses_config
test_explicit_context_overrides_auto_register
printf 'test_registry: ok\n'
