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
var _settings: Node


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

	if _thread and _thread.is_started():
		_thread.wait_to_finish()

	status = Status.BUSY

	_thread = Thread.new()
	_thread.start(_execute_opencode.bind(prompt))


func cancel():
	if _thread and _thread.is_started():
		_thread.wait_to_finish()
	_thread = null
	status = Status.CONNECTED


func _execute_opencode(prompt: String):
	if not _settings:
		call_deferred("set", "status", Status.DISCONNECTED)
		return

	var cmd_output: Array = []
	var exit_code: int

	var tmp_dir = _settings.get_temp_dir()
	var tmp_file = tmp_dir + "/prompt_" + str(Time.get_ticks_usec()) + ".txt"

	var file = FileAccess.open(tmp_file, FileAccess.WRITE)
	if not file:
		call_deferred("emit_signal", "error_occurred", "No se pudo crear archivo temporal para el prompt")
		call_deferred("set", "status", Status.CONNECTED)
		return

	file.store_string(prompt)
	file.close()

	var binary = _settings.get_opencode_path()
	var prompt_arg = "@" + tmp_file
	if OS.get_name() == "Windows":
		exit_code = OS.execute("cmd.exe", ["/c", binary, prompt_arg], cmd_output, true)
	else:
		exit_code = OS.execute(binary, [prompt_arg], cmd_output, true)

	DirAccess.remove_absolute(tmp_file)

	if exit_code != 0:
		call_deferred("emit_signal", "error_occurred", "Error ejecutando opencode. Código: " + str(exit_code))
		call_deferred("set", "status", Status.CONNECTED)
		return

	var response = ""
	for line in cmd_output:
		response += line + "\n"
	response = response.strip_edges()

	if response.is_empty():
		response = "(sin respuesta)"

	call_deferred("emit_signal", "response_received", response)
	call_deferred("set", "status", Status.CONNECTED)
