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
	if typeof(path) != TYPE_STRING or path.ends_with("/"):
		return
	EditorInterface.edit_resource(load(path))
