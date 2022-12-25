@tool
class_name GDScatter extends Node3D
@icon("res://addons/gd_scatter/src/icons/scatter-icon.png")

var tool
var active_multimesh : GDScatterMultimesh

func _enter_tree():
	pass

func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func spawn_multimesh():
	active_multimesh = GDScatterMultimesh.new()
	add_child(active_multimesh)
	active_multimesh.set_owner(get_tree().get_edited_scene_root())
	active_multimesh.name = "ScatterMultimesh" + str(tool.active_scatter.get_child_count())
	active_multimesh.multimesh = MultiMesh.new()
	active_multimesh.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	active_multimesh.multimesh.mesh = tool.brush.preview.multimesh.mesh
	active_multimesh.multimesh.mesh.set_local_to_scene(true)
	active_multimesh.multimesh.mesh.setup_local_to_scene()
	active_multimesh.material_override = tool.brush.preview.material_override
	active_multimesh.multimesh.instance_count = tool.multimesh_settings.max_instances
	active_multimesh.multimesh.visible_instance_count = 0
	active_multimesh.multimesh.set_local_to_scene(true)
	active_multimesh.multimesh.setup_local_to_scene()
	tool.active_multimesh = active_multimesh
	tool.spawning_multimesh = false

func set_tool(_tool):
	tool = _tool
	if get_child_count() == 0:
		spawn_multimesh()
