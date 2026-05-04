@tool
extends Node

var current_script_path: String = ""
var current_script_content: String = ""
var current_script_language: String = ""
var selected_node_paths: Array = []
var current_scene_path: String = ""


func context_to_prompt() -> String:
	var parts: Array = []

	if not current_script_path.is_empty():
		parts.append("Archivo actual: " + current_script_path)
		parts.append("Lenguaje: " + current_script_language)
		parts.append("")
		parts.append("Contenido del archivo:")
		parts.append("```" + current_script_language.to_lower() if current_script_language else "")
		parts.append(current_script_content)
		parts.append("```")

	if selected_node_paths.size() > 0:
		parts.append("Nodos seleccionados: " + ", ".join(selected_node_paths))

	if not current_scene_path.is_empty():
		parts.append("Escena activa: " + current_scene_path)

	if parts.is_empty():
		return ""

	return "\n".join(parts)
