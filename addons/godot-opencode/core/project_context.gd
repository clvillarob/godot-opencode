@tool
extends Node


func get_current_script_path() -> String:
	var script_editor = EditorInterface.get_script_editor()
	if not script_editor:
		return ""
	var current = script_editor.get_current_script()
	if not current:
		return ""
	return current.resource_path


func get_current_script_content() -> String:
	var path = get_current_script_path()
	if path.is_empty():
		return ""
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return ""
	var content = file.get_as_text()
	file.close()
	return content


func get_current_script_language() -> String:
	var path = get_current_script_path()
	if path.ends_with(".gd"):
		return "GDScript"
	elif path.ends_with(".cs"):
		return "C#"
	elif path.ends_with(".tscn"):
		return "Scene"
	return ""


func get_selected_node_paths() -> Array:
	var selection = EditorInterface.get_selection()
	if not selection:
		return []
	var nodes = selection.get_selected_nodes()
	var paths: Array = []
	for node in nodes:
		paths.append(node.get_path())
	return paths


func get_current_scene_path() -> String:
	var scene = EditorInterface.get_current_scene()
	if not scene:
		return ""
	return scene.scene_file_path


func get_project_type() -> String:
	var root = EditorInterface.get_current_scene()
	if not root:
		return ""
	return "2D" if root is Node2D else "3D"


func collect_context() -> Dictionary:
	return {
		"script_path": get_current_script_path(),
		"script_content": get_current_script_content(),
		"script_language": get_current_script_language(),
		"selected_nodes": get_selected_node_paths(),
		"current_scene": get_current_scene_path(),
		"os": OS.get_name(),
		"godot_version": Engine.get_version_info()
	}


func context_to_prompt() -> String:
	var ctx = collect_context()
	var parts: Array = []

	if not ctx.script_path.is_empty():
		parts.append("Archivo actual: " + ctx.script_path)
		parts.append("Lenguaje: " + ctx.script_language)
		parts.append("")
		parts.append("Contenido del archivo:")
		parts.append("```" + ctx.script_language.to_lower() if ctx.script_language else "")
		parts.append(ctx.script_content)
		parts.append("```")

	if ctx.selected_nodes.size() > 0:
		parts.append("Nodos seleccionados: " + ", ".join(ctx.selected_nodes))

	if not ctx.current_scene.is_empty():
		parts.append("Escena activa: " + ctx.current_scene)

	if parts.is_empty():
		return ""

	return "\n".join(parts)
