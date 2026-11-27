[![Console - GameSpice addon](docs/banner.png)](https://moddingcommunity.com/a/51-gs-console)

The in-game developer console for Godot 4.7+, opened with a key. It gives you a line editor, history, tab completion, scrollback and a bridge to whatever command system your game already has. Part of the [GameSpice](https://github.com/gamespice-platform) family. It needs only [GameSpice Core](https://github.com/gamespice-platform/core).

A GameSpice addon (MIT, built with Claude Code) with two offline headless tests, `console_selftest` and `cfg_selftest` under `examples/`. The games in [Zee's Games](https://zeesgames.com) are built on the GameSpice addons and run on live servers, so this is the console their players and admins open.

GameSpice Console is a console, not a command system. GameSpice Server already has commands, cvars, permissions, aliases and completion, and a second copy would drift. GameSpice Console owns the key, line editing, history, scrollback and drawing, and asks sources to run the line.

## Install

1. Copy `addons/gs_console/` and `addons/gs_core/` into your project.
2. Enable gs-console in *Project > Project Settings > Plugins*.

## Sources

Sources are asked in order, and the first that claims a name handles it. A local `quit` therefore quits the client, not the dedicated server.

| Source | What it is for |
| --- | --- |
| `GSConsoleLocal` | Things that belong to the player's own machine: a volume, a bind, a screenshot, `quit`. Works with no server in the process. |
| `GSConsoleBridge` | Wraps anything with `execute` and `complete` (duck typing), so a server's console becomes a source without this addon naming its types. |
| `GSConsoleRemote` | A `send_fn` that puts the line on a wire, for RCON or a chat command. |

## Quick start

```gdscript
var console := GSConsoleController.new()
add_child(console)
console.setup()

var local := GSConsoleLocal.new()
local.add_command(&"quit", "Quit", func(_a): get_tree().quit())
local.bind_setting(&"sensitivity", settings)      # duck-typed; one copy of the value
console.add_source(local)
console.add_source(GSConsoleBridge.wrap(server.console))   # when there is a server

var panel := GSConsolePanel.new()
panel.controller = console
canvas_layer.add_child(panel)
```

Or do all of that in one call. It adds `help`, `clear`, `settings`, a command for every setting the settings manager's schema declares, the server's console when one runs in this process, and the panel on its own CanvasLayer. Given a menu (anything with `add_overlay`), the console registers as one of its overlays, so the game does the same things for the console as for the menu (stop the player, free the pointer).

```gdscript
console = GSConsoleKit.build(self, settings_manager, menu)
```

The one line every game with a console forgets:

```gdscript
if panel.has_keyboard_focus():
    return      # otherwise typing `noclip` walks the player forward
```

See [docs/console-kit.md](docs/console-kit.md).

## Design choices

| Choice | Why |
| --- | --- |
| The key is bound by physical position. | The key under Escape types `` ` `` on a UK keyboard, `^` on a German one and `²` on a French one. Binding a character makes the console unopenable across much of Europe. `open_physical_key` is a physical keycode, and `open_action` is checked first so a player can rebind it. |
| The scrollback is a ring. | An unbounded buffer is a memory leak, and a server logging a line per tick would fill it. The size is `scrollback_lines`. |
| Secrets are redacted. | A password typed into a console lands in scrollback, in history and in screenshots. `GSConsoleLine.redact` keeps the command name and replaces the rest with asterisks of a fixed length, because the length of a password is information too. |
| The controller draws nothing. | `GSConsoleController` is a `Node` with no `Control`. `GSConsolePanel` draws it. That is what makes a headless suite possible. |
| The panel does not use GameSpice UI. | A console must work when the interface does not. Half its use is finding out why a screen stack is stuck. |

## Settings

Defaults are in `cfg/addon/gs_console/console.yml`. A game overrides them in `cfg/game/<game>/gs_console/`, and the server operator in `cfg/server/addon/gs_console/` or `cfg/server/game/<game>/gs_console/` (strongest). `GSConsoleConfig.new().load_cfg()` reads these, then `GS_CONSOLE_*` environment variables and `--console-*` flags.

| Setting | Default | What it does |
| --- | --- | --- |
| `open_action` | `gs_console_toggle` | The input action that opens the console. |
| `scrollback_lines` | 2048 | Lines of scrollback kept. The inspector slider runs 16 to 100000. |
| `history_lines` | 128 | Lines of typed history kept. The inspector slider runs 4 to 10000. |
| `chat_command_prefixes` | `/` and `!` | Prefixes treated as chat commands. |

The RCON port, allow-list and password are not this addon's. GameSpice Server Deploy reads `rcon.yml`, and the password stays in a file only.

## Test

```bash
godot --headless --path . --import
godot --headless --path . res://examples/console_selftest.tscn
godot --headless --path . res://examples/cfg_selftest.tscn
```

The self-tests are offline and exit non-zero on any failure. The design is in [docs/design.md](docs/design.md).

## Used by

### Zee's Games

Zee's Games is a collection of games I made on GameSpice, for demonstration and for fun. They show what the platform can do, and they run on live servers you can join. Anybody can create games on GameSpice, and each addon is its own repository and can be used separately from the games and from the rest of GameSpice.

Every game in the collection vendors it:

- [Fatal Contact](https://zeesgames.com/fatal-contact)
- [Airdrift](https://zeesgames.com/airdrift)
- [Playlot](https://zeesgames.com/playlot)
- [Hungario](https://zeesgames.com/hungario)
- [Buses From Hell](https://zeesgames.com/buses-from-hell)
- [Smash Copter](https://zeesgames.com/smash-copter)
- [Zombie Zone](https://zeesgames.com/zombie-zone)
- [Hide n Seek](https://zeesgames.com/hide-n-seek)
- [Prop Hunt](https://zeesgames.com/prop-hunt)
- [Murder Mystery](https://zeesgames.com/murder-mystery)
- [Deathrun](https://zeesgames.com/deathrun)
- [Wipeout](https://zeesgames.com/wipeout)
- [Dangerous Delivery](https://zeesgames.com/dangerous-delivery)
- [Look At Me](https://zeesgames.com/look-at-me)

The whole collection is at [zeesgames.com](https://zeesgames.com).

## Licence

MIT. See [LICENSE](LICENSE). Only the TMC back-end web infrastructure is not open source.
