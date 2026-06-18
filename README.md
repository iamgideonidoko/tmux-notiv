# tmux-notiv

`tmux-notiv` is a tmux plugin that gives you persistent floating scratch contexts backed by tmux sessions. Each context opens a command in a directory, keeps that session alive after the popup closes, and reuses it on the next open.

## Features

- Persistent scratch contexts such as `notes`, `todo`, `git`, and `logs`
- Lazy session creation with stable session names like `scratch-notes`
- Popup UI via `tmux display-popup`
- Tmux-style configuration through `@notiv_*` options
- Modular Bash architecture with deterministic unit tests

## Install

### Requirements

- tmux 3.2 or newer
- Bash

`tmux-notiv` depends on `display-popup`, so tmux 3.2+ is required.

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
set -g @notiv_key_notes 'n'
set -g @notiv_key_todo 't'
set -g @notiv_key_git 'g'
set -g @notiv_key_list 'l'
set -g @notiv_key_picker 'p'
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

## Namespaced keybindings

`tmux-notiv` registers a dedicated `notiv` key table behind `prefix + n`.

Default bindings:

| Sequence          | Action                                       |
| ----------------- | -------------------------------------------- |
| `prefix + n`, `n` | Open `notes` when the `notes` context exists |
| `prefix + n`, `t` | Open `todo` when the `todo` context exists   |
| `prefix + n`, `g` | Open `git` when the `git` context exists     |
| `prefix + n`, `l` | Run `notiv list`                             |
| `prefix + n`, `p` | Open the notiv picker                        |

Context bindings are only registered for contexts that exist. For example, if `@notiv_git_dir` is not configured and `git` is not present in `@notiv_auto_register`, `prefix + n`, `g` is not bound.

Override the second key in the namespace with tmux options:

```tmux
set -g @notiv_key_notes 'o'
set -g @notiv_key_todo 'd'
set -g @notiv_key_git 'r'
set -g @notiv_key_list 'L'
set -g @notiv_key_picker 'P'
```

Reload bindings after changing key options:

```sh
~/.tmux/plugins/tmux-notiv/notiv reload bindings
```

## Usage

The plugin ships a standalone CLI wrapper:

```sh
~/.tmux/plugins/tmux-notiv/notiv toggle notes
~/.tmux/plugins/tmux-notiv/notiv open git
~/.tmux/plugins/tmux-notiv/notiv close notes
~/.tmux/plugins/tmux-notiv/notiv picker
~/.tmux/plugins/tmux-notiv/notiv list
~/.tmux/plugins/tmux-notiv/notiv reload
~/.tmux/plugins/tmux-notiv/notiv reload bindings
```

Command summary:

| Command                 | Behavior                                                          |
| ----------------------- | ----------------------------------------------------------------- |
| `notiv toggle <name>`   | Ensure the scratch session exists, then open or refocus the popup |
| `notiv open <name>`     | Same as `toggle`, but named explicitly for scripts and bindings   |
| `notiv close <name>`    | Close the popup on the last known client for that context         |
| `notiv picker`          | Open a tmux menu for selecting a registered context               |
| `notiv list`            | Print all resolved contexts and effective settings                |
| `notiv reload`          | Refresh the registry and re-register namespace bindings           |
| `notiv reload bindings` | Clear and rebuild the `prefix + n` notiv bindings                 |

## Example tmux config

```tmux
set -g @notiv_notes_dir '~/notes'
set -g @notiv_todo_dir '~/todo'
set -g @notiv_git_dir '#{pane_current_path}'
set -g @notiv_git_cmd 'lazygit'
set -g @notiv_key_notes 'n'
set -g @notiv_key_todo 't'
set -g @notiv_key_git 'g'
set -g @notiv_key_list 'l'
set -g @notiv_key_picker 'p'
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
│   ├── bindings.sh
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
│   ├── test_bindings.sh
│   ├── test_popup.sh
│   ├── test_registry.sh
│   ├── test_session.sh
│   └── test_toggle.sh
└── Makefile
```
