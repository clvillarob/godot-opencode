@tool
extends Node


var opencode_client: Node
var project_context: Node


func apply_response(response: String) -> bool:
	var blocks = _extract_code_blocks(response)
	if blocks.is_empty():
		return false

	var applied_count = 0
	for block in blocks:
		var lang = block.language.to_lower()
		var code = block.code

		if lang in ["gdscript", "cs", "json", "xml", "yaml", "txt"]:
			if _apply_file(code, block.path, lang):
				applied_count += 1

	return applied_count > 0


func _extract_code_blocks(text: String) -> Array:
	var blocks: Array = []
	var regex = RegEx.new()
	regex.compile("```(\\w*)\\s*(?:path=([^\\n]+))?\\n([\\s\\S]*?)```")
	var result = regex.search_all(text)

	for res in result:
		blocks.append({
			"language": res.get_string(1),
			"path": res.get_string(2).strip_edges() if res.get_string(2) != "" else "",
			"code": res.get_string(3)
		})

	return blocks


func _apply_file(code: String, path: String, language: String) -> bool:
	if path.is_empty():
		var ctx = project_context
		if ctx:
			path = ctx.get_current_script_path()

	if path.is_empty():
		var ext = _extension_for_language(language)
		path = "res://generated_" + str(Time.get_ticks_usec()) + ext

	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(code)
	file.close()

	EditorInterface.get_resource_filesystem().scan()
	return true


func _extension_for_language(language: String) -> String:
	match language:
		"gdscript": return ".gd"
		"cs": return ".cs"
		"json": return ".json"
		"xml": return ".xml"
		"yaml": return ".yaml"
		"txt": return ".txt"
		_: return ".txt"
