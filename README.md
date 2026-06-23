# tmux-notiv

`tmux-notiv` is a tmux plugin that gives you persistent scratch contexts backed by one shared tmux session. Each context lives in its own window inside that shared session, but opens as a popup on whatever tmux client you are currently using — inspired by [tmux-floax](https://github.com/omerxx/tmux-floax).

## Features

- Persistent scratch contexts such as `notes`, `todo`, `git`, and `logs`
- One shared notiv session with one persistent window per context
- Lazy window creation with a stable session name like `scratch-notiv`
- Popup UI that always opens on the current tmux client
- FloaX-style menu with size controls, fullscreen, reset, embed, and lock
- Root key bindings (no prefix needed) for all menu actions while the popup is open
- Configurable border color, text color, border style, and popup title
- Optional path syncing from the origin session into shell-based context windows
- Tmux-style configuration through `@notiv_*` options
- Modular Bash architecture with deterministic unit tests

## Install

### Requirements

- tmux 3.3 or newer (popup support with styles)
- Bash

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

### Default options

```tmux
set -g @notiv_default_cmd 'nvim'
set -g @notiv_session_name 'scratch-notiv'
set -g @notiv_popup_width '90%'
set -g @notiv_popup_height '90%'
set -g @notiv_border_color 'magenta'
set -g @notiv_text_color 'blue'
set -g @notiv_border_style 'rounded'
set -g @notiv_change_path 'true'
set -g @notiv_key_prefix 'n'
set -g @notiv_key_menu 'P'
set -g @notiv_root_bindings 'true'
```

### Root bindings (active inside the popup without prefix)

```tmux
set -g @notiv_key_zoom_in 'C-M-s'    # size down
set -g @notiv_key_zoom_out 'C-M-b'   # size up
set -g @notiv_key_fullscreen 'C-M-f' # fullscreen
set -g @notiv_key_reset 'C-M-r'      # reset size
set -g @notiv_key_embed 'C-M-e'      # embed in origin session
set -g @notiv_key_lock 'C-M-d'       # lock root bindings
set -g @notiv_key_unlock 'C-M-u'     # unlock root bindings
```

Set `@notiv_root_bindings 'false'` to disable all root bindings.

### Registering contexts

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

### Popup appearance

```tmux
# Border color: black, red, green, yellow, blue, magenta, cyan, white,
# brightred, brightyellow, ... colour0-colour255, default, or #RRGGBB
set -g @notiv_border_color 'magenta'

# Text (content) color
set -g @notiv_text_color 'blue'

# Border style: rounded, single, double, heavy, padded, none
set -g @notiv_border_style 'rounded'

# Custom popup title (default shows the context name and root key hints)
set -g @notiv_title 'my notiv'
```

### Path syncing

When `@notiv_change_path` is `true` (default), notiv syncs the origin session's current directory into shell-based context windows on each open. For windows running a shell (`sh`, `bash`, `zsh`, `fish`, etc.) it sends `cd`; for other commands (e.g. `nvim`, `lazygit`) the window is recreated when the resolved directory changes. Set to `false` to disable:

```tmux
set -g @notiv_change_path 'false'
```

## Keybindings

`tmux-notiv` registers a dedicated `notiv` key table behind `prefix + <key_prefix>` (default `n`).

Default bindings:

| Sequence          | Action                |
| ----------------- | --------------------- |
| `prefix + n`, `n` | Toggle `notes`        |
| `prefix + n`, `t` | Toggle `todo`         |
| `prefix + n`, `g` | Toggle `git`          |
| `prefix + n`, `P` | Open the notiv menu   |

Context bindings are only registered when both the context exists and it has an explicit key. The menu binding is always registered.

While the popup is open, these root bindings (no prefix) are active:

| Key     | Action                    |
| ------- | ------------------------- |
| `C-M-s` | Size down                 |
| `C-M-b` | Size up                   |
| `C-M-f` | Fullscreen                |
| `C-M-r` | Reset size                |
| `C-M-e` | Embed in origin session   |
| `C-M-d` | Lock root bindings        |
| `C-M-u` | Unlock root bindings      |

Configure per-context keys with tmux options:

```tmux
set -g @notiv_notes_key 'o'
set -g @notiv_todo_key 'd'
set -g @notiv_git_key 'r'
set -g @notiv_key_menu 'M'
set -g @notiv_key_prefix 'N'
```

Reload bindings after changing key options:

```sh
~/.tmux/plugins/tmux-notiv/notiv reload bindings
```

## Menu

The menu (default `prefix + n`, `P`) shows different options depending on context:

**Inside the popup:**

- Size down (`-`): Decrease popup size
- Size up (`+`): Increase popup size
- Full screen (`f`): Toggle 100% of the screen
- Reset size (`r`): Reset to default dimensions
- Embed in session (`e`): Move the context window to the origin session
- Lock bindings (`d`): Disable root bindings except unlock

**Outside the popup:**

- Pop current window (`p`): Move the current window back into the notiv popup

## Usage

The plugin ships a standalone CLI wrapper:

```sh
~/.tmux/plugins/tmux-notiv/notiv toggle notes
~/.tmux/plugins/tmux-notiv/notiv open git
~/.tmux/plugins/tmux-notiv/notiv close notes
~/.tmux/plugins/tmux-notiv/notiv menu
~/.tmux/plugins/tmux-notiv/notiv zoom in
~/.tmux/plugins/tmux-notiv/notiv zoom full
~/.tmux/plugins/tmux-notiv/notiv zoom reset
~/.tmux/plugins/tmux-notiv/notiv zoom lock
~/.tmux/plugins/tmux-notiv/notiv embed
~/.tmux/plugins/tmux-notiv/notiv embed pop
~/.tmux/plugins/tmux-notiv/notiv reload
~/.tmux/plugins/tmux-notiv/notiv reload bindings
```

Command summary:

| Command                 | Behavior                                                                                   |
| ----------------------- | ------------------------------------------------------------------------------------------ |
| `notiv toggle <name>`   | Open the named context from a normal tmux client, or close/switch it from inside the popup |
| `notiv open <name>`     | Open the popup or switch to the named context window inside it                             |
| `notiv close <name>`    | Close the popup on the last known client for that context                                  |
| `notiv menu`            | Open the tmux menu with size/fullscreen/reset/embed/lock options                           |
| `notiv zoom <action>`   | Resize (`in`/`out`), fullscreen (`full`), reset, or lock/unlock root bindings              |
| `notiv embed [pop]`     | Embed the context window into the origin session, or pop it back                           |
| `notiv reload`          | Refresh the registry and re-register namespace bindings                                    |
| `notiv reload bindings` | Clear and rebuild the `prefix + n` notiv bindings                                          |

## Session model

All contexts share one tmux session and each context gets its own window inside it:

- backing session: `scratch-notiv`
- `notes` -> `scratch-notiv:notes`
- `todo` -> `scratch-notiv:todo`
- `git` -> `scratch-notiv:git`

Windows are created lazily, reused on later opens, and recreated automatically if the mapped directory or command changes (when `@notiv_change_path` is `true`). Opening a context attaches that window inside a popup on the current client rather than switching your client to the backing session. When you trigger a context binding from inside the popup, notiv detaches the popup client to close the current context or switches windows in place for another context.

## Notes and tmux limits

- The popup lifecycle is driven by attaching and detaching a tmux client inside `display-popup`, so the supported close path is the same mapped key from inside the popup.
- Root key bindings are global in tmux. They are set when a popup opens and unset when it closes. If multiple clients open popups simultaneously, the root bindings reflect the last-opened popup's state.
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
│   ├── toggle.sh
│   ├── zoom.sh
│   ├── embed.sh
│   └── menu.sh
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
│   ├── test_toggle.sh
│   ├── test_zoom.sh
│   ├── test_embed.sh
│   └── test_menu.sh
└── Makefile
```
