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
