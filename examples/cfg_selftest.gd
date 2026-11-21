extends Node

## The yml layout of GameSpice Console's settings: the new path, the flat shim and the operator's layer.
## Run: `timeout 120 godot --headless --path . res://examples/cfg_selftest.tscn`.

const FOLDER := "gs_console"
const FILE := "console.yml"
const LEGACY := "user://gs_console_cfg_selftest_legacy"

const SECTIONS := 1
const CHECKS := 11

var _passed := 0
var _failed := 0
var _sections := 0


func _ready() -> void:
	GSLog.set_level(GSLog.Level.ERROR)
	_run.call_deferred()


func _run() -> void:
	print("gs-console cfg self-test")
	var addon_dir := "user://cfg/addons/" + FOLDER
	var server_dir := "user://cfg/server/addons/" + FOLDER
	_clean(addon_dir, server_dir)
	GSCfgLegacy.reset()

	_write(LEGACY.path_join(FILE), "scrollback_lines: 1000\nfont_size: 20\n")
	var config := GSConsoleConfig.new()
	var res := config.load_cfg(FILE, LEGACY)
	_check(res.ok and config.scrollback_lines == 1000, "only the flat file: it is still read")
	_check(GSCfgLegacy.warned_count() == 1, "and warned once")
	GSConsoleConfig.new().load_cfg(FILE, LEGACY)
	_check(GSCfgLegacy.warned_count() == 1, "a second load does not warn again")

	_write(addon_dir.path_join(FILE), "scrollback_lines: 2000\n")
	config = GSConsoleConfig.new()
	res = config.load_cfg(FILE, LEGACY)
	_check(res.ok and config.scrollback_lines == 2000, "the new path wins over the flat file")
	_check(config.font_size == GSConsoleConfig.new().font_size, "and the two are never merged")

	_write(server_dir.path_join(FILE), "scrollback_lines: 3000\n")
	config = GSConsoleConfig.new()
	res = config.load_cfg(FILE, LEGACY)
	_check(res.ok and config.scrollback_lines == 3000, "the operator's server layer wins")

	var game_dir := "user://cfg/game/mg-test/" + FOLDER
	var server_game_dir := "user://cfg/server/game/mg-test/" + FOLDER
	GSAddonConfig.game = "mg-test"
	_write(game_dir.path_join(FILE), "scrollback_lines: 3500\n")
	config = GSConsoleConfig.new()
	res = config.load_cfg(FILE, LEGACY)
	_check(res.ok and config.scrollback_lines == 3000, "the operator's layer still wins over the game tier")
	GSPaths.remove_tree(server_dir)
	config = GSConsoleConfig.new()
	res = config.load_cfg(FILE, LEGACY)
	_check(res.ok and config.scrollback_lines == 3500, "the game tier wins over the addon's own")
	_write(server_game_dir.path_join(FILE), "scrollback_lines: 3700\n")
	config = GSConsoleConfig.new()
	res = config.load_cfg(FILE, LEGACY)
	_check(res.ok and config.scrollback_lines == 3700, "the operator's per-game tier wins over the game's")
	GSAddonConfig.game = ""
	GSPaths.remove_tree("user://cfg/game/mg-test")
	GSPaths.remove_tree("user://cfg/server/game/mg-test")

	_clean(addon_dir, server_dir)
	GSCfgLegacy.reset()
	_write("user://cfg/server/" + FOLDER + "/" + FILE, "scrollback_lines: 4000\n")
	config = GSConsoleConfig.new()
	res = config.load_cfg(FILE, LEGACY)
	_check(res.ok and config.scrollback_lines == 4000, "the old cfg/server/gs_console/ still loads")
	_check(GSCfgLegacy.warned_count() == 1, "and warns once")
	GSPaths.remove_tree("user://cfg/server/" + FOLDER)

	_clean(addon_dir, server_dir)
	GSCfgLegacy.reset()
	_sections += 1
	print("%d sections, %d passed, %d failed" % [_sections, _passed, _failed])
	if _sections != SECTIONS or _passed + _failed != CHECKS:
		print("ERROR: %d of %d sections, %d of %d checks ran." % [_sections, SECTIONS, _passed + _failed, CHECKS])
		get_tree().quit(1)
		return
	get_tree().quit(1 if _failed > 0 else 0)


func _clean(addon_dir: String, server_dir: String) -> void:
	GSPaths.remove_tree(addon_dir)
	GSPaths.remove_tree(server_dir)
	GSPaths.remove_tree(LEGACY)


func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _check(condition: bool, what: String) -> void:
	if condition:
		_passed += 1
		print("   ok   ", what)
	else:
		_failed += 1
		print("  FAIL  ", what)
