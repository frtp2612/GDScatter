@tool
extends Control

var tool

@export_node_path(HSlider) var brush_size_slider_path
var brush_size_slider
var brush_size_label


func _enter_tree():
	print("ui creation")
	brush_size_label = get_node("P/V/BrushSize/Size")
	brush_size_slider = get_node(brush_size_slider_path)
	brush_size_slider.value_changed.connect(_set_brush_size)


func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_W:
			brush_size_slider.set_value(brush_size_slider.value + 1)
#			_set_brush_size(tool.brush.size + 1)
		elif event.keycode == KEY_S:
			brush_size_slider.set_value(brush_size_slider.value - 1)
#			_set_brush_size(tool.brush.size - 1)

func _set_brush_size(value):
	tool.brush.size = value
	tool.brush.mesh.scale = Vector3.ONE * value
	brush_size_label.text = str(value)
