@tool
class_name GDScatterSection extends MultiMeshInstance3D
@icon("res://addons/gd_scatter/src/icons/scatter-random-icon.png")

var deleted_instances_data : Array
var existing_instances_data : Dictionary

var global_state: GDScatterState

func set_state(state: GDScatterState) -> void:
	global_state = state

func _enter_tree():
	var instance_transform
	if multimesh:
		print("redrawing")
		for instance_index in multimesh.visible_instance_count:
			instance_transform = multimesh.get_instance_transform(instance_index)
			if instance_transform == Transform3D():
				deleted_instances_data.push_back(instance_index)
			else:
				existing_instances_data[instance_transform.origin] = instance_index

func add_elements():
	var visible_instances = multimesh.visible_instance_count
	for instance_index in global_state.multimesh_settings.current_instances * global_state.brush.hardness:
		var instance_transform = global_state.brush.node.preview_area.multimesh.get_instance_transform(instance_index)
		if !existing_instances_data.has(instance_transform.origin):
			instance_transform.origin = instance_transform.origin + global_state.get_brush_position()
			if instance_index + visible_instances < multimesh.instance_count:
				add_instance_to_multimesh(instance_index + visible_instances, instance_transform)
			elif !deleted_instances_data.is_empty():
				var available_index = deleted_instances_data.pop_front()
				add_instance_to_multimesh(available_index, instance_transform)
			else:
				break

	if visible_instances == multimesh.instance_count:
		global_state.spawning_section = true
		global_state.active_area.spawn_section()
		# this break is necessary to allow the engine to process the change of active multimesh
		# otherwise it will still detect that the visible instances are exceeding the max instance count
		# and will add n new multimesh nodes
	

func remove_elements():
	for instance_origin in existing_instances_data.keys():
		var instance_index = existing_instances_data[instance_origin]
		if Vector2(instance_origin.x, instance_origin.z).distance_to(Vector2(global_state.get_brush_position().x, global_state.get_brush_position().z)) <= global_state.brush.size:
			multimesh.set_instance_transform(instance_index, Transform3D())
			deleted_instances_data.push_back(instance_index)
			existing_instances_data.erase(instance_origin)
	if existing_instances_data.is_empty() and global_state.active_area.get_child_count() > 1:
		global_state.active_section = null
		free()

func add_instance_to_multimesh(instance_index, instance_transform):
	existing_instances_data[instance_transform.origin] = instance_index
	multimesh.set_instance_transform(instance_index, instance_transform)
	if multimesh.visible_instance_count < multimesh.instance_count:
		multimesh.visible_instance_count += 1
