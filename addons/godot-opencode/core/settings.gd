@tool
extends Node

var _opencode_path: String = ""


func _ready():
	_resolve_opencode_path()


func _resolve_opencode_path():
	var output: Array = []
	var exit_code: int
	if OS.get_name() == "Windows":
		exit_code = OS.execute("where", ["opencode"], output, true)
	else:
		exit_code = OS.execute("which", ["opencode"], output, true)
	if exit_code == 0 and output.size() > 0:
		_opencode_path = output[0].strip_edges()


func get_opencode_path() -> String:
	if _opencode_path.is_empty():
		_resolve_opencode_path()
	return _opencode_path


func is_opencode_installed() -> bool:
	if _opencode_path.is_empty():
		_resolve_opencode_path()
	return not _opencode_path.is_empty()


func get_opencode_version() -> String:
	if _opencode_path.is_empty():
		return ""
	var output: Array = []
	var exit_code: int = OS.execute(_opencode_path, ["--version"], output, true)
	if exit_code == 0 and output.size() > 0:
		return output[0].strip_edges()
	return ""


func get_project_root() -> String:
	return ProjectSettings.globalize_path("res://")


func get_temp_dir() -> String:
	var tmp = ProjectSettings.globalize_path("user://opencode_temp")
	var err = DirAccess.make_dir_recursive_absolute(tmp)
	if err != OK:
		push_warning("No se pudo crear directorio temp: " + tmp)
	return tmp
