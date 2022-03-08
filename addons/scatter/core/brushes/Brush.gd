@tool
extends Node3D

var brush_area
@export_node_path(MeshInstance3D) var brush_node_path

var multi_mesh
@export_node_path(MultiMeshInstance3D) var multi_mesh_node_path

func _enter_tree():
	brush_area = get_node(brush_node_path)
	multi_mesh = get_node(multi_mesh_node_path)
