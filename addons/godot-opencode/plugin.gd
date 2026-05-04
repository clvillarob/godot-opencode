@tool
extends EditorPlugin

var chat_dock: Control
var files_dock: Control
var terminal_dock: Control

var settings_node: Node
var opencode_client: Node
var project_context: Node
var editor_bridge: Node


func _enter_tree():
	_init_settings()
	_init_core()
	_init_docks()
	_wire_connections()
	_add_docks()


func _exit_tree():
	_remove_docks()
	_cleanup_core()
	_cleanup_settings()


func _init_settings():
	settings_node = preload("core/settings.gd").new()
	add_child(settings_node)


func _init_core():
	opencode_client = preload("core/opencode_client.gd").new()
	add_child(opencode_client)
	opencode_client.initialize(settings_node)

	project_context = preload("core/project_context.gd").new()
	add_child(project_context)

	editor_bridge = preload("core/editor_bridge.gd").new()
	add_child(editor_bridge)
	editor_bridge.opencode_client = opencode_client
	editor_bridge.project_context = project_context


func _init_docks():
	chat_dock = preload("docks/chat_dock.tscn").instantiate()
	files_dock = preload("docks/files_dock.tscn").instantiate()
	terminal_dock = preload("docks/terminal_dock.tscn").instantiate()


func _wire_connections():
	chat_dock.send_prompt.connect(_on_chat_send_prompt)
	chat_dock.start_opencode.connect(_on_start_opencode)
	chat_dock.stop_opencode.connect(_on_stop_opencode)

	opencode_client.status_changed.connect(_on_client_status_changed)
	opencode_client.response_received.connect(_on_client_response)
	opencode_client.error_occurred.connect(_on_client_error)

	terminal_dock.send_command.connect(_on_terminal_command)
	terminal_dock.stop_requested.connect(_on_stop_opencode)

	editor_bridge.files_changed.connect(_on_files_changed)


func _add_docks():
	add_control_to_dock(DOCK_SLOT_LEFT_UL, chat_dock)
	add_control_to_dock(DOCK_SLOT_LEFT_BL, files_dock)
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, terminal_dock)


func _remove_docks():
	remove_control_from_docks(chat_dock)
	remove_control_from_docks(files_dock)
	remove_control_from_docks(terminal_dock)


func _cleanup_core():
	if opencode_client:
		opencode_client.cancel()
		opencode_client.queue_free()
	if editor_bridge:
		editor_bridge.queue_free()
	if project_context:
		project_context.queue_free()


func _cleanup_settings():
	if settings_node:
		settings_node.queue_free()


func _gather_context():
	var ctx = project_context
	ctx.current_script_path = ""
	ctx.current_script_content = ""
	ctx.current_script_language = ""
	ctx.selected_node_paths = []
	ctx.current_scene_path = ""

	var script_editor = EditorInterface.get_script_editor()
	if script_editor:
		var current = script_editor.get_current_script()
		if current:
			ctx.current_script_path = current.resource_path
			var file = FileAccess.open(current.resource_path, FileAccess.READ)
			if file:
				ctx.current_script_content = file.get_as_text()
				file.close()
			if current.resource_path.ends_with(".gd"):
				ctx.current_script_language = "GDScript"
			elif current.resource_path.ends_with(".cs"):
				ctx.current_script_language = "C#"

	var selection = EditorInterface.get_selection()
	if selection:
		var nodes = selection.get_selected_nodes()
		var paths: Array = []
		for node in nodes:
			paths.append(node.get_path())
		ctx.selected_node_paths = paths

	var scene = EditorInterface.get_current_scene()
	if scene:
		ctx.current_scene_path = scene.scene_file_path


func _on_chat_send_prompt(prompt: String):
	if not opencode_client.is_opencode_installed():
		chat_dock.show_error("Opencode no está instalado. Instálalo desde https://opencode.ai")
		return

	_gather_context()
	var context = project_context.context_to_prompt()
	var full_prompt = prompt
	if not context.is_empty():
		full_prompt = context + "\n\n---\n\n" + prompt

	terminal_dock.append_output(">>> " + prompt)
	opencode_client.send_prompt(full_prompt)


func _on_start_opencode():
	if opencode_client.is_opencode_installed():
		opencode_client.status = opencode_client.Status.CONNECTED
		chat_dock.show_message("Sistema", "Opencode conectado. Listo para recibir prompts.")
	else:
		chat_dock.show_error("Opencode no está instalado. Ejecuta: npm install -g @opencode/cli")


func _on_stop_opencode():
	opencode_client.status = opencode_client.Status.DISCONNECTED
	chat_dock.show_message("Sistema", "Opencode desconectado.")


func _on_client_status_changed(new_status: int):
	var status_names = ["Desconectado", "Conectando", "Conectado", "Ocupado", "Error"]
	var name = status_names[new_status] if new_status < status_names.size() else "Desconocido"
	chat_dock.set_status(name)


func _on_client_response(response: String):
	chat_dock.show_message("Opencode", response)
	terminal_dock.append_output(response)

	var applied = editor_bridge.apply_response(response)
	if applied:
		chat_dock.show_message("Sistema", "Cambios aplicados al proyecto.")


func _on_client_error(message: String):
	chat_dock.show_error(message)
	terminal_dock.append_output("[ERROR] " + message)


func _on_terminal_command(text: String):
	_on_chat_send_prompt(text)


func _on_files_changed():
	EditorInterface.get_resource_filesystem().scan()
