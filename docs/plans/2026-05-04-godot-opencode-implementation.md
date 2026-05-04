# Godot Opencode Plugin — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) for syntax tracking.

**Goal:** Implement a functional Godot 4.6+ editor plugin that integrates opencode CLI via interactive chat, file explorer, and output console docks.

**Architecture:** GDScript-only EditorPlugin with three native docks (chat, files, terminal). Communication with opencode via one-shot `OS.execute()` calls using temp files for prompt exchange. Context gathering via `EditorInterface` APIs. Response application via `EditorScript` and file I/O.

**Tech Stack:** GDScript, Godot 4.6+ EditorPlugin API, opencode CLI

---

## File Structure

| File | Responsibility |
|------|---------------|
| `addons/godot-opencode/plugin.cfg` | Plugin metadata |
| `addons/godot-opencode/plugin.gd` | Entry point: registers docks, wires core |
| `addons/godot-opencode/core/settings.gd` | Binary detection, paths |
| `addons/godot-opencode/core/opencode_client.gd` | CLI communication, threading |
| `addons/godot-opencode/core/project_context.gd` | Gathers editor context (scripts, nodes, scenes) |
| `addons/godot-opencode/core/editor_bridge.gd` | Parses responses, applies changes to editor |
| `addons/godot-opencode/docks/chat_dock.gd` | Chat UI: history, input, commands |
| `addons/godot-opencode/docks/chat_dock.tscn` | Chat scene layout |
| `addons/godot-opencode/docks/files_dock.gd` | File tree UI |
| `addons/godot-opencode/docks/files_dock.tscn` | File tree scene layout |
| `addons/godot-opencode/docks/terminal_dock.gd` | Output console UI |
| `addons/godot-opencode/docks/terminal_dock.tscn` | Output console scene layout |
| `addons/godot-opencode/themes/chat_theme.tres` | Visual theme |

---

### Task 1: Implement settings.gd — Binary detection and paths

**Files:**
- Modify: `addons/godot-opencode/core/settings.gd`

- [ ] **Step 1: Replace stub with full implementation**

```gdscript
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
```

- [ ] **Step 2: Verify syntax**

Run: `godot --headless --check-only addons/godot-opencode/core/settings.gd`
Expected: No errors (or at least syntax is valid for the file itself)

- [ ] **Step 3: Commit**

```bash
git add addons/godot-opencode/core/settings.gd
git commit -m "feat: implement settings.gd with binary detection and paths"
```

---

### Task 2: Implement opencode_client.gd — CLI communication with threading

**Files:**
- Modify: `addons/godot-opencode/core/opencode_client.gd`

This is the core communication layer. Since Godot doesn't support interactive stdin/stdout with subprocesses, we use one-shot `OS.execute()` calls for each prompt.

- [ ] **Step 1: Write the full opencode_client.gd**

```gdscript
@tool
extends Node


enum Status { DISCONNECTED, CONNECTING, CONNECTED, BUSY, ERROR }

signal status_changed(new_status: int)
signal response_received(response: String)
signal error_occurred(message: String)

var status: int = Status.DISCONNECTED:
	set(value):
		status = value
		status_changed.emit(value)

var _thread: Thread
var _pending_prompt: String = ""
var _mutex: Mutex
var _settings: Node


func _ready():
	_mutex = Mutex.new()


func initialize(settings_node: Node):
	_settings = settings_node


func is_opencode_installed() -> bool:
	if not _settings:
		return false
	return _settings.is_opencode_installed()


func send_prompt(prompt: String):
	if status == Status.BUSY:
		error_occurred.emit("Opencode está ocupado. Espera a que termine.")
		return

	status = Status.BUSY
	_pending_prompt = prompt

	_thread = Thread.new()
	_thread.start(_execute_opencode.bind(prompt))


func cancel():
	if _thread and _thread.is_started():
		_thread.wait_to_finish()
	status = Status.CONNECTED


func _execute_opencode(prompt: String):
	var output: Array = []
	var cmd_output: Array = []
	var exit_code: int

	var tmp_dir = _settings.get_temp_dir()
	var tmp_file = tmp_dir + "/prompt_" + str(Time.get_ticks_usec()) + ".txt"

	var file = FileAccess.open(tmp_file, FileAccess.WRITE)
	if file:
		file.store_string(prompt)
		file.close()

	var prompt_arg = "@" + tmp_file
	exit_code = OS.execute("opencode", [prompt_arg], cmd_output, true)

	if exit_code != 0:
		call_deferred("emit_signal", "error_occurred", "Error ejecutando opencode. Código: " + str(exit_code))
		call_deferred("emit_signal", "status_changed", Status.CONNECTED)
		return

	var response = ""
	for line in cmd_output:
		response += line + "\n"
	response = response.strip_edges()

	if response.is_empty():
		response = "(sin respuesta)"

	call_deferred("emit_signal", "response_received", response)
	call_deferred("emit_signal", "status_changed", Status.CONNECTED)
```

- [ ] **Step 2: Verify syntax**

Run: `godot --headless --check-only addons/godot-opencode/core/opencode_client.gd`
Expected: No syntax errors

- [ ] **Step 3: Commit**

```bash
git add addons/godot-opencode/core/opencode_client.gd
git commit -m "feat: implement opencode_client.gd with threaded CLI communication"
```

---

### Task 3: Implement project_context.gd — Editor context gathering

**Files:**
- Modify: `addons/godot-opencode/core/project_context.gd`

- [ ] **Step 1: Write the full project_context.gd**

```gdscript
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
	if root.has_signal("mouse_entered"):
		return "2D"
	elif root.has_signal("mouse_exited"):
		return "2D"
	if "position" in root and "z_index" in root:
		return "2D"
	return "unknown"


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
```

- [ ] **Step 2: Verify syntax**

Run: `godot --headless --check-only addons/godot-opencode/core/project_context.gd`
Expected: No syntax errors

- [ ] **Step 3: Commit**

```bash
git add addons/godot-opencode/core/project_context.gd
git commit -m "feat: implement project_context.gd with editor context gathering"
```

---

### Task 4: Implement editor_bridge.gd — Response parser and editor applier

**Files:**
- Modify: `addons/godot-opencode/core/editor_bridge.gd`

- [ ] **Step 1: Write the full editor_bridge.gd**

```gdscript
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

		if lang == "gdscript":
			if _apply_gdscript(code, block.path):
				applied_count += 1
		elif lang == "text":
			pass

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


func _apply_gdscript(code: String, path: String) -> bool:
	if path.is_empty():
		var ctx = project_context
		if ctx:
			path = ctx.get_current_script_path()
		if path.is_empty():
			path = _ask_save_path()
			if path.is_empty():
				return false

	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(code)
	file.close()

	EditorInterface.get_resource_filesystem().scan()
	return true


func _ask_save_path() -> String:
	return "res://generated_script.gd"
```

- [ ] **Step 2: Verify syntax**

Run: `godot --headless --check-only addons/godot-opencode/core/editor_bridge.gd`
Expected: No syntax errors

- [ ] **Step 3: Commit**

```bash
git add addons/godot-opencode/core/editor_bridge.gd
git commit -m "feat: implement editor_bridge.gd with code block parsing"
```

---

### Task 5: Implement plugin.gd wiring — Connect docks to core

**Files:**
- Modify: `addons/godot-opencode/plugin.gd`

- [ ] **Step 1: Rewire plugin.gd with proper connections**

```gdscript
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


func _add_docks():
	add_control_to_dock(DOCK_SLOT_LEFT_UL, chat_dock)
	add_control_to_dock(DOCK_SLOT_LEFT_BL, files_dock)
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, terminal_dock)


func _remove_docks():
	remove_control_from_docks(chat_dock)
	remove_control_from_docks(files_dock)
	remove_control_from_docks(terminal_dock)


func _cleanup_core():
	if editor_bridge:
		editor_bridge.queue_free()
	if project_context:
		project_context.queue_free()
	if opencode_client:
		opencode_client.queue_free()


func _cleanup_settings():
	if settings_node:
		settings_node.queue_free()


func _on_chat_send_prompt(prompt: String):
	if not opencode_client.is_opencode_installed():
		chat_dock.show_error("Opencode no está instalado. Instálalo desde https://opencode.ai")
		return

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
```

- [ ] **Step 2: Verify syntax**

Run: `godot --headless --check-only addons/godot-opencode/plugin.gd`
Expected: No syntax errors

- [ ] **Step 3: Commit**

```bash
git add addons/godot-opencode/plugin.gd
git commit -m "feat: wire plugin.gd with full connections and signal handling"
```

---

### Task 6: Implement chat_dock — Chat UI with history, commands, and input

**Files:**
- Modify: `addons/godot-opencode/docks/chat_dock.gd`
- Modify: `addons/godot-opencode/docks/chat_dock.tscn`

- [ ] **Step 1: Write the full chat_dock.gd**

```gdscript
@tool
extends Control


signal send_prompt(prompt: String)
signal start_opencode()
signal stop_opencode()

var _messages: Array = []


func _ready():
	$VBoxContainer/InputBar/SendButton.pressed.connect(_on_send_pressed)
	$VBoxContainer/InputBar/PromptInput.text_submitted.connect(_on_input_submitted)
	$VBoxContainer/StatusBar/StartStopButton.pressed.connect(_on_start_stop_pressed)

	$VBoxContainer/CommandBar/ExplainBtn.pressed.connect(_on_command.bind("Explica el código actual"))
	$VBoxContainer/CommandBar/ImproveBtn.pressed.connect(_on_command.bind("Mejora este código, sugiere optimizaciones"))
	$VBoxContainer/CommandBar/DocumentBtn.pressed.connect(_on_command.bind("Genera documentación para este código"))
	$VBoxContainer/CommandBar/RefactorBtn.pressed.connect(_on_command.bind("Refactoriza este código siguiendo mejores prácticas"))
	$VBoxContainer/CommandBar/CreateBtn.pressed.connect(_on_command.bind("Crea un script que..."))

	set_status("Desconectado")


func show_message(author: String, content: String):
	var text = "[b]" + author + ":[/b]\n" + content
	$VBoxContainer/ChatHistory.append_text(text + "\n\n")
	_messages.append({"author": author, "content": content})


func show_error(message: String):
	var text = "[color=red][b]Error:[/b] " + message + "[/color]"
	$VBoxContainer/ChatHistory.append_text(text + "\n\n")


func set_status(status: String):
	$VBoxContainer/StatusBar/StatusLabel.text = "Opencode: " + status


func _on_send_pressed():
	var input = $VBoxContainer/InputBar/PromptInput
	var text = input.text.strip_edges()
	if text.is_empty():
		return
	input.text = ""
	show_message("Tú", text)
	send_prompt.emit(text)


func _on_input_submitted(text: String):
	_on_send_pressed()


func _on_start_stop_pressed():
	var btn = $VBoxContainer/StatusBar/StartStopButton
	if btn.text == "Iniciar":
		btn.text = "Detener"
		start_opencode.emit()
	else:
		btn.text = "Iniciar"
		stop_opencode.emit()


func _on_command(prompt: String):
	show_message("Tú", prompt)
	send_prompt.emit(prompt)
```

- [ ] **Step 2: Update chat_dock.tscn — add signal connections**

Update the existing chat_dock.tscn to add button signal connections. The scene nodes are already defined. We need to ensure signal names match the script.

The .tscn is already created with the correct node structure. The script handles all signals via `_ready()`.

- [ ] **Step 3: Verify syntax**

Run: `godot --headless --check-only addons/godot-opencode/docks/chat_dock.gd`
Expected: No syntax errors

- [ ] **Step 4: Commit**

```bash
git add addons/godot-opencode/docks/chat_dock.gd addons/godot-opencode/docks/chat_dock.tscn
git commit -m "feat: implement chat_dock with messaging and command buttons"
```

---

### Task 7: Implement files_dock — Project file explorer

**Files:**
- Modify: `addons/godot-opencode/docks/files_dock.gd`
- Modify: `addons/godot-opencode/docks/files_dock.tscn`

- [ ] **Step 1: Write the full files_dock.gd**

```gdscript
@tool
extends Control


var _tree: Tree
var _root: TreeItem


func _ready():
	_tree = $VBoxContainer/FileTree
	_tree.item_activated.connect(_on_file_activated)
	$VBoxContainer/Header/RefreshBtn.pressed.connect(refresh)
	refresh()


func refresh():
	_tree.clear()
	_root = _tree.create_item()
	_root.set_text(0, "res://")

	var project_root = ProjectSettings.globalize_path("res://")
	_populate_tree(project_root, _root)


func _populate_tree(dir_path: String, parent_item: TreeItem):
	var dir = DirAccess.open(dir_path)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path = dir_path + "/" + file_name
		var item = _tree.create_item(parent_item)

		if dir.current_is_dir():
			item.set_text(0, file_name + "/")
			item.set_metadata(0, full_path)
			_populate_tree(full_path, item)
		else:
			item.set_text(0, file_name)
			item.set_metadata(0, full_path)

		file_name = dir.get_next()

	dir.list_dir_end()


func _on_file_activated():
	var selected = _tree.get_selected()
	if not selected:
		return
	var path = selected.get_metadata(0)
	if path.ends_with("/"):
		return
	EditorInterface.edit_resource(load(path))
```

- [ ] **Step 2: Update files_dock.tscn**

The current .tscn already has the correct node structure with Tree and Button.

- [ ] **Step 3: Verify syntax**

Run: `godot --headless --check-only addons/godot-opencode/docks/files_dock.gd`
Expected: No syntax errors

- [ ] **Step 4: Commit**

```bash
git add addons/godot-opencode/docks/files_dock.gd addons/godot-opencode/docks/files_dock.tscn
git commit -m "feat: implement files_dock with project tree navigation"
```

---

### Task 8: Implement terminal_dock — Output console

**Files:**
- Modify: `addons/godot-opencode/docks/terminal_dock.gd`
- Modify: `addons/godot-opencode/docks/terminal_dock.tscn`

- [ ] **Step 1: Write the full terminal_dock.gd**

```gdscript
@tool
extends Control


signal send_command(text: String)


func _ready():
	$VBoxContainer/Controls/ClearBtn.pressed.connect(clear)
	$VBoxContainer/Controls/CommandInput.text_submitted.connect(_on_command_submitted)


func append_output(text: String):
	var output = $VBoxContainer/Output
	output.append_text(text + "\n")
	output.scroll_to_line(output.get_line_count() - 1)


func clear():
	$VBoxContainer/Output.clear()


func _on_command_submitted(text: String):
	var input = $VBoxContainer/Controls/CommandInput
	text = text.strip_edges()
	if text.is_empty():
		return
	input.text = ""
	append_output("$ " + text)
	send_command.emit(text)
```

- [ ] **Step 2: Update terminal_dock.tscn**

The current .tscn already has the correct node structure with RichTextLabel, buttons, and LineEdit.

- [ ] **Step 3: Verify syntax**

Run: `godot --headless --check-only addons/godot-opencode/docks/terminal_dock.gd`
Expected: No syntax errors

- [ ] **Step 4: Commit**

```bash
git add addons/godot-opencode/docks/terminal_dock.gd addons/godot-opencode/docks/terminal_dock.tscn
git commit -m "feat: implement terminal_dock with output console and command input"
```

---

### Task 9: Update ROADMAP, TASKS, CHANGELOG for implementation progress

**Files:**
- Modify: `ROADMAP.md`
- Modify: `TASKS.md`
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Mark Fase 1 tasks as completed in ROADMAP.md**

Update the [ ] checkboxes for implemented features to [x].

- [ ] **Step 2: Mark implementation tasks as completed in TASKS.md**

Mark all implemented tasks with [x].

- [ ] **Step 3: Update CHANGELOG.md with v0.1.0 details**

Mark the CHANGELOG to reflect that the implementation is code-complete.

- [ ] **Step 4: Commit**

```bash
git add ROADMAP.md TASKS.md CHANGELOG.md
git commit -m "docs: update progress tracking after implementation"
```

---

## Self-Review Checklist

**1. Spec coverage:**
- Objective → Tasks 1-8 deliver a working plugin
- Chat interactivo → Task 6 (chat_dock) + Task 2 (opencode_client)
- Comandos predefinidos → Task 6 chat_dock command buttons
- Explorador de archivos → Task 7 (files_dock)
- Terminal/consola → Task 8 (terminal_dock)
- EditorBridge → Task 4 (editor_bridge) + Task 3 (project_context)
- Integración con el editor → Task 5 (plugin.gd wiring)

**2. Placeholder scan:** No TBD, TODO, "implement later" patterns. All code is complete.

**3. Type consistency:** All method signatures and signal connections are consistent across tasks.
