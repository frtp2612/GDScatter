@tool
class_name GDBrush extends Node3D

var influence_area
@export_node_path(MeshInstance3D) var brush_node_path

var preview_area
@export_node_path(MultiMeshInstance3D) var preview_node_path

var edit_material = preload("./EditBrush.tres")
var delete_material = preload("./DeleteBrush.tres")

var global_state : GDScatterState

func _enter_tree():
	influence_area = get_node(brush_node_path)
	preview_area = get_node(preview_node_path)

func set_state(state: GDScatterState) -> void:
	global_state = state
	global_state.mode_changed.connect(change_mode)
	print(global_state.multimesh_settings.current_instances)
	preview_area.multimesh.instance_count = global_state.multimesh_settings.current_instances

func change_mode() -> void:
	pass
