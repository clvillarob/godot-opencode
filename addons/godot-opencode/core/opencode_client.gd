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
