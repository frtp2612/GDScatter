@tool
extends PanelContainer

var tool

@export_node_path(HSlider) var brush_size_slider_path
var brush_size_slider
var brush_size_label

@export_node_path(HSlider) var mesh_instances_slider_path
var mesh_instances_slider
var mesh_instances_label

func _enter_tree():
	brush_size_label = get_node("V/BrushSize/H/Size")
	brush_size_slider = get_node(brush_size_slider_path)
	brush_size_slider.value_changed.connect(_set_brush_size)
	_set_brush_size(brush_size_slider.value)
	
	mesh_instances_label = get_node("V/MeshInstances/H/Size")
	mesh_instances_slider = get_node(mesh_instances_slider_path)
	mesh_instances_slider.value_changed.connect(_set_mesh_instances)
	_set_mesh_instances(mesh_instances_slider.value)

func set_tool(_tool):
	tool = _tool
	mesh_instances_slider.max_value = tool.multimesh_settings.max_instances
	mesh_instances_slider.value = tool.multimesh_settings.current_instances

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
		tool.process_drawing()

func _set_mesh_instances(value):
	mesh_instances_label.text = str(value)
	if tool:
		tool.multimesh_settings.current_instances = value
		tool.process_drawing()
