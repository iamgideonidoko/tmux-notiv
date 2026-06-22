# tmux-notiv

`tmux-notiv` is a tmux plugin that gives you persistent scratch contexts backed by one shared tmux session. Each context lives in its own window inside that shared session, but opens as a popup on whatever tmux client you are currently using.

## Features

- Persistent scratch contexts such as `notes`, `todo`, `git`, and `logs`
- One shared notiv session with one persistent window per context
- Lazy window creation with a stable session name like `scratch-notiv`
- Popup UI that always opens on the current tmux client
- Tmux-style configuration through `@notiv_*` options
- Modular Bash architecture with deterministic unit tests

## Install

### Requirements

- tmux 3.2 or newer
- Bash

`tmux-notiv` targets modern tmux releases and is tested against tmux 3.2+.

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
set -g @notiv_session_name 'scratch-notiv'
set -g @notiv_popup_width '90%'
set -g @notiv_popup_height '90%'
set -g @notiv_key_list 'l'
set -g @notiv_key_picker 'p'
```

Register contexts one by one:

```tmux
set -g @notiv_notes_dir '~/notes'
set -g @notiv_notes_key 'n'
set -g @notiv_todo_dir '~/todo'
set -g @notiv_todo_key 't'
set -g @notiv_git_dir '#{pane_current_path}'
set -g @notiv_git_cmd 'lazygit'
set -g @notiv_git_key 'g'
set -g @notiv_logs_dir '~/logs'
set -g @notiv_logs_cmd 'tail -f app.log'
set -g @notiv_logs_height '75%'
```

Or auto-register several contexts at once:

```tmux
set -g @notiv_auto_register 'notes:~/notes:nvim:::n,todo:~/todo:nvim:::t,git:~/src/project:lazygit:::g'
```

Per-context overrides use:

- `@notiv_<name>_dir`
- `@notiv_<name>_cmd`
- `@notiv_<name>_width`
- `@notiv_<name>_height`
- `@notiv_<name>_key`

Explicit per-context options override values coming from `@notiv_auto_register`.

## Namespaced keybindings

`tmux-notiv` registers a dedicated `notiv` key table behind `prefix + n`.

Default bindings:

| Sequence          | Action                                       |
| ----------------- | -------------------------------------------- |
| `prefix + n`, `l` | Run `notiv list`                             |
| `prefix + n`, `p` | Open the notiv picker                        |

Context bindings are only registered when both the context exists and it has an explicit key. For example, `notes` is only bound when `@notiv_notes_dir` (or `@notiv_auto_register`) exists and `@notiv_notes_key` is set, or the auto-register record includes a key field.

Configure per-context keys with tmux options:

```tmux
set -g @notiv_notes_key 'o'
set -g @notiv_todo_key 'd'
set -g @notiv_git_key 'r'
set -g @notiv_key_list 'L'
set -g @notiv_key_picker 'P'
```

With that configuration:

| Sequence | Action |
| --- | --- |
| `prefix + n`, `o` | Toggle `notes` |
| `prefix + n`, `d` | Toggle `todo` |
| `prefix + n`, `r` | Toggle `git` |
| `prefix + n`, `L` | Run `notiv list` |
| `prefix + n`, `P` | Open the notiv picker |

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
| `notiv toggle <name>`   | Toggle a popup for the named context on the current tmux client   |
| `notiv open <name>`     | Open or retarget the popup to the named context                   |
| `notiv close <name>`    | Close the popup on the last known client for that context         |
| `notiv picker`          | Open a tmux menu for selecting a registered context               |
| `notiv list`            | Print all resolved contexts and effective settings                |
| `notiv reload`          | Refresh the registry and re-register namespace bindings           |
| `notiv reload bindings` | Clear and rebuild the `prefix + n` notiv bindings                 |

## Example tmux config

```tmux
set -g @notiv_notes_dir '~/notes'
set -g @notiv_notes_key 'n'
set -g @notiv_todo_dir '~/todo'
set -g @notiv_todo_key 't'
set -g @notiv_git_dir '#{pane_current_path}'
set -g @notiv_git_cmd 'lazygit'
set -g @notiv_git_key 'g'
set -g @notiv_key_list 'l'
set -g @notiv_key_picker 'p'
```

## Session model

All contexts share one tmux session and each context gets its own window inside it:

- backing session: `scratch-notiv`
- `notes` -> `scratch-notiv:notes`
- `todo` -> `scratch-notiv:todo`
- `git` -> `scratch-notiv:git`

Windows are created lazily, reused on later opens, and recreated automatically if the mapped directory or command changes. Opening a context attaches that window inside a popup on the current client rather than switching your client to the backing session.

## Notes and tmux limits

- `Escape` is still handled by tmux itself for popups, so it cannot be disabled from the plugin while using `display-popup`.
- tmux does not provide a native way to hide a detached backing session from `list-sessions` or session pickers, so the shared notiv session may still appear there.

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
