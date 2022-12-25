@tool
class_name GDScatterArea extends Node3D
@icon("res://addons/gd_scatter/src/icons/scatter-icon.png")

var plugin

@export_range(0, 5, 1)
var zones = 0 :
	set(value):
		zones = value
		on_zones_changed()

@export_node_path(MeshInstance3D)
var scattering_area :
	set(value):
		scattering_area = value
		on_scattering_area_changed()

var zones_size = Vector3.ZERO

var area_objects : Dictionary

func activate(_plugin):
	plugin = _plugin
	plugin.active_scatter = self
	plugin.current_mode = GDScatterMode.FREE_EDIT
	plugin.brush.center.change_mode(false)
	plugin.brush.center.visible = true
	if get_child_count() == 0:
		spawn_multimesh()
		plugin.spawning_multimesh = false

func on_zones_changed():
	if scattering_area:
		var area_size = get_node(scattering_area).get_aabb().size * get_node(scattering_area).scale
		print(area_size / pow(4, zones))
		var divisions = pow(2, zones)
		zones_size = area_size / pow(2, zones)
		
		for child in get_children():
			child.free()
		var total_zones = pow(4, zones)
		for zone_index in total_zones:
			var new_zone = spawn_multimesh()
			var row_index = posmod(zone_index, divisions)
			var column_index = int(zone_index / divisions)
			new_zone.position.z = zones_size.z * row_index - area_size.z * 0.5 + zones_size.z * 0.5
			new_zone.position.x = zones_size.x * column_index - area_size.x * 0.5 + zones_size.x * 0.5
			
func on_scattering_area_changed():
	on_zones_changed()

func spawn_multimesh():
	var multimesh = GDScatterMultimesh.new()
	add_child(multimesh)
	if zones_size != Vector3.ZERO:
		multimesh.set_custom_aabb(AABB(multimesh.get_aabb().position, zones_size))
	multimesh.set_owner(get_tree().get_edited_scene_root())
	multimesh.name = "ScatterMultimesh" + str(plugin.active_scatter.get_child_count())
	multimesh.multimesh = MultiMesh.new()
	multimesh.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.multimesh.mesh = plugin.brush.preview.multimesh.mesh
	multimesh.multimesh.mesh.set_local_to_scene(true)
	multimesh.multimesh.mesh.setup_local_to_scene()
	multimesh.material_override = plugin.brush.preview.material_override
	multimesh.multimesh.instance_count = plugin.multimesh_settings.max_instances
	multimesh.multimesh.visible_instance_count = 0
	multimesh.multimesh.set_local_to_scene(true)
	multimesh.multimesh.setup_local_to_scene()
	plugin.active_multimesh = multimesh
	return multimesh
