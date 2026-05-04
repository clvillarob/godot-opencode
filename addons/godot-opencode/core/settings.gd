@tool
extends Node


const OPENCODE_BINARY: String = "opencode"


func get_opencode_path() -> String:
	return OPENCODE_BINARY


func is_opencode_installed() -> bool:
	var exit_code: int
	if OS.get_name() == "Windows":
		exit_code = OS.execute("where", [OPENCODE_BINARY], [], true)
	else:
		exit_code = OS.execute("which", [OPENCODE_BINARY], [], true)
	return exit_code == 0


func get_opencode_version() -> String:
	var output: Array = []
	var exit_code: int = OS.execute(OPENCODE_BINARY, ["--version"], output, true)
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
