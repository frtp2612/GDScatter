@tool
class_name Scatter extends Node3D

var tool
var active_multimesh : MultiMeshInstance3D

func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func spawn_multimesh():
	active_multimesh = MultiMeshInstance3D.new()
	add_child(active_multimesh)
	active_multimesh.multimesh = MultiMesh.new()
	active_multimesh.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	active_multimesh.multimesh.mesh = tool.brush.preview.multimesh.mesh
	active_multimesh.multimesh.instance_count = tool.brush.preview.multimesh.instance_count
	tool.active_multimesh = active_multimesh

func set_tool(_tool):
	tool = _tool
	spawn_multimesh()
	tool.active_multimesh = active_multimesh
	print(tool.active_multimesh)
