@tool
extends Control


signal send_prompt(prompt: String)
signal start_opencode()
signal stop_opencode()


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
	var safe_content = content.replace("[", "[lb]")
	var text = "[b]" + author + ":[/b]\n" + safe_content
	$VBoxContainer/ChatHistory.append_text(text + "\n\n")


func show_error(message: String):
	var safe_message = message.replace("[", "[lb]")
	var text = "[color=red][b]Error:[/b] " + safe_message + "[/color]"
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
