@tool
extends PanelContainer

var tool

var file_dialog
var preview_visualizer

@export_node_path(HSlider) var brush_size_slider_path
var brush_size_slider
var brush_size_label

@export_node_path(HSlider) var mesh_instances_slider_path
var mesh_instances_slider
var mesh_instances_label

@export_node_path(HSlider) var brush_hardness_slider_path
var brush_hardness_slider
var brush_hardness_label

@export_node_path(Button) var add_mesh_button_path
var add_mesh_button

@export_node_path(HBoxContainer) var mesh_list_path
var mesh_list : ItemList

func _enter_tree():
	brush_size_label = get_node("V/BrushSize/H/Size")
	brush_size_slider = get_node(brush_size_slider_path)
	brush_size_slider.value_changed.connect(_set_brush_size)
	_set_brush_size(brush_size_slider.value)
	
	mesh_instances_label = get_node("V/MeshInstances/H/Instances")
	mesh_instances_slider = get_node(mesh_instances_slider_path)
	mesh_instances_slider.value_changed.connect(_set_mesh_instances)
	_set_mesh_instances(mesh_instances_slider.value)
	
	brush_hardness_label = get_node("V/BrushHardness/H/Hardness")
	brush_hardness_slider = get_node(brush_hardness_slider_path)
	brush_hardness_slider.value_changed.connect(_set_brush_hardness)
	_set_brush_hardness(brush_hardness_slider.value)
	
	mesh_list = get_node(mesh_list_path)
	mesh_list.item_selected.connect(_on_mesh_changed)
	add_mesh_button = get_node(add_mesh_button_path)
	add_mesh_button.pressed.connect(_show_importer)
	
	file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.add_filter("*.mesh ; MESH files")
	file_dialog.file_selected.connect(_on_FileDialog_file_selected)
	

func _exit_tree():
	if file_dialog != null:
		file_dialog.queue_free()
		file_dialog = null
		
func set_tool(_tool):
	tool = _tool
	preview_visualizer = tool.get_editor_interface().get_resource_previewer()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_W:
			brush_size_slider.set_value(brush_size_slider.value + 1)
			_set_brush_size(brush_size_slider.value)
		elif event.keycode == KEY_S:
			brush_size_slider.set_value(brush_size_slider.value - 1)
			_set_brush_size(brush_size_slider.value)

func _set_brush_size(value):
	brush_size_label.text = str(value)
	if tool:
		tool.brush.size = value
		tool.brush.mesh.scale = Vector3.ONE * value

func _set_mesh_instances(value):
	mesh_instances_label.text = str(value)
	if tool:
		tool.multimesh_settings.current_instances = value

func _set_brush_hardness(value):
	brush_hardness_label.text = str(value)
	if tool:
		tool.brush.hardness = value

func _show_importer():
	file_dialog.show()
	tool.get_editor_interface().get_base_control().add_child(file_dialog)

func _on_FileDialog_file_selected(file_path):
	add_pattern(file_path)

func add_pattern(scene_path):
	# TODO I need scene thumbnails from the editor
	var default_icon = get_theme_icon("PackedScene", "EditorIcons")
	var pattern_name = scene_path.get_file().get_basename()
	var i = mesh_list.get_child_count()
	mesh_list.add_item(pattern_name, default_icon)
	mesh_list.set_item_metadata(i, scene_path)
	
	preview_visualizer.queue_resource_preview(scene_path, self, "_on_EditorResourcePreview_preview_loaded", null)


func _on_EditorResourcePreview_preview_loaded(path, texture, userdata):
	var i = find_mesh(path)
	if i == -1:
		return
	if texture != null:
		mesh_list.set_item_icon(i, texture)

func find_mesh(path):
	for i in mesh_list.get_child_count():
		var scene_path = mesh_list.get_item_metadata(i)
		if scene_path == path:
			return i
	return -1

func _on_mesh_changed(index):
	tool.brush.preview.multimesh.mesh = load(mesh_list.get_item_metadata(index))
	tool.active_multimesh.multimesh.mesh = tool.brush.preview.multimesh.mesh
	tool.active_multimesh.multimesh.mesh.set_local_to_scene(true)
	tool.active_multimesh.multimesh.mesh.setup_local_to_scene()
