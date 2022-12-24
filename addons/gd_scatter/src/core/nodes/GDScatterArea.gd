@tool
class_name GDScatterArea extends Node3D
@icon("res://addons/gd_scatter/src/icons/scatter-icon.png")

var global_state: GDScatterState

func set_state(state: GDScatterState) -> void:
	global_state = state
	if get_child_count() == 0:
		spawn_section()

func spawn_section():
	var scatter_section : GDScatterSection = GDScatterSection.new()
	add_child(scatter_section)
	scatter_section.set_state(global_state)
	scatter_section.set_owner(get_tree().get_edited_scene_root())
	scatter_section.name = "ScatterSection" + str(global_state.active_area.get_child_count())
	scatter_section.multimesh = MultiMesh.new()
	scatter_section.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	scatter_section.multimesh.mesh = global_state.brush.preview.multimesh.mesh
	scatter_section.multimesh.mesh.set_local_to_scene(true)
	scatter_section.multimesh.mesh.setup_local_to_scene()
	scatter_section.material_override = global_state.brush.preview.material_override
	scatter_section.multimesh.instance_count = global_state.multimesh_settings.max_instances
	scatter_section.multimesh.visible_instance_count = 0
	scatter_section.multimesh.set_local_to_scene(true)
	scatter_section.multimesh.setup_local_to_scene()
	global_state.active_section = scatter_section
	global_state.spawning_section = false
