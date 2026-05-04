@tool
extends Node


const OPencode_BINARY: String = "opencode"


func get_opencode_path() -> String:
	return OPencode_BINARY


func is_opencode_installed() -> bool:
	var output: Array = []
	var exit_code: int
	if OS.get_name() == "Windows":
		exit_code = OS.execute("where", [OPencode_BINARY], output, true)
	else:
		exit_code = OS.execute("which", [OPencode_BINARY], output, true)
	return exit_code == 0


func get_opencode_version() -> String:
	var output: Array = []
	var exit_code: int = OS.execute(OPencode_BINARY, ["--version"], output, true)
	if exit_code == 0 and output.size() > 0:
		return output[0].strip_edges()
	return ""


func get_project_root() -> String:
	return ProjectSettings.globalize_path("res://")


func get_temp_dir() -> String:
	var tmp = ProjectSettings.globalize_path("user://opencode_temp")
	DirAccess.make_dir_recursive_absolute(tmp)
	return tmp
