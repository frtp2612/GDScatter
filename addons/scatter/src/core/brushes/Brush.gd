@tool
extends Node3D

var brush_area
@export_node_path(MeshInstance3D) var brush_node_path

var multi_mesh
@export_node_path(MultiMeshInstance3D) var multi_mesh_node_path

var edit_material = preload("./EditBrush.tres")
var delete_material = preload("./DeleteBrush.tres")

func _enter_tree():
	brush_area = get_node(brush_node_path)
	multi_mesh = get_node(multi_mesh_node_path)

func change_mode(delete):
	if delete:
		brush_area.material_override = delete_material
	else:
		brush_area.material_override = edit_material
