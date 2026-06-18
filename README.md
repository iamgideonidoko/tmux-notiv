# tmux-notiv

`tmux-notiv` is a tmux plugin that gives you persistent floating scratch contexts backed by tmux sessions. Each context opens a command in a directory, keeps that session alive after the popup closes, and reuses it on the next open.

## Features

- Persistent scratch contexts such as `notes`, `todo`, `git`, and `logs`
- Lazy session creation with stable session names like `scratch-notes`
- Popup UI via `tmux display-popup`
- Tmux-style configuration through `@notiv_*` options
- Modular Bash architecture with deterministic unit tests

## Install

### TPM

Add the plugin to your `~/.tmux.conf`:

```tmux
set -g @plugin 'iamgideonidoko/tmux-notiv'
run '~/.tmux/plugins/tpm/tpm'
```

Reload tmux, then install plugins with `prefix + I`.

### Manual

Clone the repository into your tmux plugins directory and run the entrypoint:

```sh
git clone https://github.com/iamgideonidoko/tmux-notiv ~/.tmux/plugins/tmux-notiv
~/.tmux/plugins/tmux-notiv/notiv.tmux
```

## Configuration

Default options:

```tmux
set -g @notiv_default_cmd 'nvim'
set -g @notiv_popup_width '90%'
set -g @notiv_popup_height '90%'
```

Register contexts one by one:

```tmux
set -g @notiv_notes_dir '~/notes'
set -g @notiv_todo_dir '~/todo'
set -g @notiv_git_dir '#{pane_current_path}'
set -g @notiv_git_cmd 'lazygit'
set -g @notiv_logs_dir '~/logs'
set -g @notiv_logs_cmd 'tail -f app.log'
set -g @notiv_logs_height '75%'
```

Or auto-register several contexts at once:

```tmux
set -g @notiv_auto_register 'notes:~/notes:nvim,todo:~/todo:nvim,git:~/src/project:lazygit:95%:95%'
```

Per-context overrides use:

- `@notiv_<name>_dir`
- `@notiv_<name>_cmd`
- `@notiv_<name>_width`
- `@notiv_<name>_height`

Explicit per-context options override values coming from `@notiv_auto_register`.

## Usage

The plugin ships a standalone CLI wrapper:

```sh
~/.tmux/plugins/tmux-notiv/notiv toggle notes
~/.tmux/plugins/tmux-notiv/notiv open git
~/.tmux/plugins/tmux-notiv/notiv close notes
~/.tmux/plugins/tmux-notiv/notiv list
~/.tmux/plugins/tmux-notiv/notiv reload
```

Command summary:

| Command               | Behavior                                                          |
| --------------------- | ----------------------------------------------------------------- |
| `notiv toggle <name>` | Ensure the scratch session exists, then open or refocus the popup |
| `notiv open <name>`   | Same as `toggle`, but named explicitly for scripts and bindings   |
| `notiv close <name>`  | Close the popup on the last known client for that context         |
| `notiv list`          | Print all resolved contexts and effective settings                |
| `notiv reload`        | Re-parse current tmux options and refresh the cached context list |

## Example tmux bindings

```tmux
set -g @notiv_notes_dir '~/notes'
set -g @notiv_todo_dir '~/todo'
set -g @notiv_git_dir '#{pane_current_path}'
set -g @notiv_git_cmd 'lazygit'

bind-key n run-shell '~/.tmux/plugins/tmux-notiv/notiv toggle notes'
bind-key t run-shell '~/.tmux/plugins/tmux-notiv/notiv toggle todo'
bind-key g run-shell '~/.tmux/plugins/tmux-notiv/notiv toggle git'
bind-key N run-shell '~/.tmux/plugins/tmux-notiv/notiv list'
```

## Session model

Each context maps to a tmux session:

- `notes` -> `scratch-notes`
- `todo` -> `scratch-todo`
- `git` -> `scratch-git`

Sessions are created lazily and stay alive after you close the popup.

## Development

Run the test suite:

```sh
make test
```

The default test run includes:

- shell syntax checks
- unit tests with a mocked `tmux_cmd()`
- an optional real-tmux integration test when `NOTIV_RUN_INTEGRATION=1`

## Project layout

```text
tmux-notiv/
├── notiv
├── notiv.tmux
├── scripts/
│   ├── cli.sh
│   ├── config.sh
│   ├── registry.sh
│   ├── session.sh
│   └── toggle.sh
├── lib/
│   ├── core.sh
│   ├── popup.sh
│   ├── state.sh
│   └── util.sh
├── tests/
│   ├── test_helper.sh
│   ├── test_integration.sh
│   ├── test_popup.sh
│   ├── test_registry.sh
│   ├── test_session.sh
│   └── test_toggle.sh
└── Makefile
```
