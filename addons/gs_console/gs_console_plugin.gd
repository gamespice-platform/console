@tool
extends EditorPlugin

## Editor entry point for GameSpice Console. Registers inspector types only.
##
## No autoloads: a host and a client in one process are two consoles with two sets of
## sources, and a global would make them one.

const _ICON := "res://addons/gs_console/icon_placeholder.svg"

const _TYPES := [
	[
		"GSConsoleController",
		"Node",
		"res://addons/gs_console/runtime/gs_console_controller.gd",
	],
	[
		"GSConsolePanel",
		"Control",
		"res://addons/gs_console/runtime/gs_console_panel.gd",
	],
]


func _enter_tree() -> void:
	var icon: Texture2D = null
	if ResourceLoader.exists(_ICON):
		icon = load(_ICON) as Texture2D

	for entry in _TYPES:
		add_custom_type(entry[0], entry[1], load(entry[2]), icon)


func _exit_tree() -> void:
	for i in range(_TYPES.size() - 1, -1, -1):
		remove_custom_type(_TYPES[i][0])
