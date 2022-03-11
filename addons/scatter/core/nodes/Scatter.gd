@tool
class_name Scatter extends Node3D

var tool
var active_multimesh : ScatterMultimesh
var scatter_multimesh

func _enter_tree():
	scatter_multimesh = preload("res://addons/scatter/core/nodes/ScatterMultimesh.tscn")

func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func spawn_multimesh():
	active_multimesh = scatter_multimesh.instantiate()
	add_child(active_multimesh)
	active_multimesh.set_owner(get_tree().get_edited_scene_root())
	active_multimesh.multimesh = MultiMesh.new()
	active_multimesh.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	active_multimesh.multimesh.mesh = tool.brush.preview.multimesh.mesh
	active_multimesh.material_override = tool.brush.preview.material_override
	active_multimesh.multimesh.instance_count = tool.multimesh_settings.max_instances
	active_multimesh.multimesh.visible_instance_count = -1
	tool.active_multimesh = active_multimesh

func set_tool(_tool):
	tool = _tool
	spawn_multimesh()
