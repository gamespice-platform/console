# GameSpice Console

The player's console: a key, a line, a history, and a bridge to whatever can run it. **dot-server's console is the machine that decides; dot-console is the person typing**: it has a key and a caret and no authority, and it is not a second command system.

**The distributable is `addons/dot_console/`.** It requires [GameSpice Core](../dot-core) API level 16 or later and nothing else: not dot-server, which it bridges to by duck typing, and not dot-ui.

Also requires **GameSpice Profile** (`GSProfileSet`, `GSProfile`, `GSProfileRuntime`, split from GameSpice Core): link `addons/dot_profile` next to `addons/dot_core`.

```bash
ln -s ../../dot-core/addons/dot_core addons/dot_core
```

Read the family [CLAUDE.md](../../CLAUDE.md) first.

## Read before

| Read | Before |
| --- | --- |
| [docs/design.md](docs/design.md) | the key, input handling, redaction, sources and precedence, completion, suggestions |
| [docs/console-kit.md](docs/console-kit.md) | `GSConsoleKit`, or wiring a console into a game |
| [docs/history.md](docs/history.md) | what the suite and real typing found |

## The pieces

| Class | What |
| --- | --- |
| `GSConsoleSource` | anything a line can be sent to: `claims`, `execute`, `complete`, `names` |
| `GSConsoleLocal` | the client's own commands and variables; `bind_setting` wires one straight through to GameSpice Settings by duck typing, so there is one copy of a value |
| `GSConsoleBridge` | wraps an existing console (GameSpice Server's); the file that stops this being a second command system |
| `GSConsoleRemote` | a `send_fn` to a wire; deliberately the least capable source |
| `GSConsoleProfileEdit` | the `profile_edit` command (set, reset_key, reset, save) that builds a `GSProfileRuntime` request and hands it to a `submit` callable; the server decides who may |
| `GSConsoleLine` | splitting, statements and redaction, one pass over one string |
| `GSConsoleBuffer` | scrollback and history, both rings |
| `GSConsoleConfig` | the key, sizes and colours; a `GSConfig` |
| `GSConsoleController` | everything, with no `Control` in it |
| `GSConsolePanel` | the `Control` that draws it; also `is_open`/`close`/`closed`, the shape a menu's overlay list duck-types |
| `GSConsoleKit` | the console a game client builds, in one call |

`core/` holds the sources, line, buffer and config; `runtime/` the controller, panel and kit; `examples/console_selftest.tscn` is the suite and `examples/cfg_selftest.tscn` covers the yml layout (new path, flat shim, server layer).

## Running and testing

The family's two steps ([family CLAUDE.md](../../CLAUDE.md#validating-anything)), then `timeout 120 godot --headless --path . res://examples/console_selftest.tscn`.

- **`SECTIONS` and `CHECKS` in the suite are guards**: a script error aborts one test, not the run. Update `CHECKS` in the same commit as any test you add; a guard that is always red is one nobody reads. [history](docs/history.md#the-guard-that-was-always-red)
- The last section builds a real `GSConsolePanel` and asserts it has a size, because `set_anchors_preset` does not set offsets. The rest of the panel wants a screenshot.

## Rules that bite

- The open key is a physical keycode (the key under Escape), never a character; `open_action` is checked first. [design](docs/design.md#three-things-that-are-easy-to-get-wrong)
- Input is handled in `_input`, so the console opens when a screen stack has swallowed input; the panel does not use GameSpice UI. [design](docs/design.md#three-things-that-are-easy-to-get-wrong)
- Redact by command name, before the echo and before the history, with a fixed number of asterisks. [design](docs/design.md#three-things-that-are-easy-to-get-wrong)
- Never re-implement a server command here; bridge it. `GSConsoleLocal` is for the client's own handful. [design](docs/design.md#why-this-is-not-a-second-command-system)
- A remote source never asks the server per keystroke; it learns names once (`learn_names`). An unprefixed remote source is added last; use `prefix` when the console is not the server's. [design](docs/design.md#decisions)
- Completion text: `lstrip`, never `strip_edges`; candidates are whole lines. [design](docs/design.md#argument-completion)
- The console does not pause the game, and a failed statement does not stop the next. [design](docs/design.md#decisions)
- `sm` (the player's block list) is a kit command found by registry name or GameSpice Chat's script path, never named. [kit](docs/console-kit.md)
- In a game, register the panel as one of the menu's overlays (`GSConsoleKit` does), or typing walks the player. [kit](docs/console-kit.md)
- A test that captures a local in a lambda captures it by value: capture an `Array`. [history](docs/history.md#what-building-it-found)

## Things deliberately not here

- **A command system.** GameSpice Server's console is the one.
- **A theme.** A `StyleBoxFlat` built in code and nothing else.
- **Log mirroring on by default.** `mirror_log` is off: a server at DEBUG is a wall of noise.
