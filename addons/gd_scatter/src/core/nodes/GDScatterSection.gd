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
		global_state.spawning_multimesh = true
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

func place_elements():
	if global_state:
		var position_range_start = 0
		var position_range_end = global_state.brush.size
		var theta : float = 0.0
		
		global_state.brush.node.preview_area.multimesh.instance_count = global_state.multimesh_settings.current_instances
		
		var center = global_state.brush.position
		
		for instance_index in global_state.multimesh_settings.current_instances:
			randomize()
			theta = randf() * 2.0 * PI
			var point_distance_from_center : float = sqrt(randf()) * global_state.brush.size
			var x = center.x + point_distance_from_center * cos(theta)
			var z = center.z + point_distance_from_center * sin(theta)
			var start_position = Vector3(x, 10000, z)
			var target_position = get_projected_position(start_position)
			var y = 0

			if target_position != null:
				y = target_position.y
			var random_amount = global_state.multimesh_settings.randomized_amount
			var vertical_rotation = sqrt(random_amount)
			var horizontal_rotation = sqrt(random_amount * 0.01)

			var transform = Transform3D().\
			rotated(Vector3.UP, randf_range(-vertical_rotation, vertical_rotation)).\
			rotated(Vector3.LEFT, randf_range(-horizontal_rotation, horizontal_rotation)).\
			rotated(Vector3.FORWARD, randf_range(-horizontal_rotation, horizontal_rotation))
			transform.origin = Vector3(x - center.x, y - center.y, z - center.z)
			global_state.brush.node.preview_area.multimesh.set_instance_transform(instance_index, transform)

func get_projected_position(ray_start):
	var ray_end = Vector3(ray_start.x, ray_start.y-100000, ray_start.z)
	var result = raycast_from_vert(ray_start, ray_end)
	if result:
		return result.position
	return null

func raycast_from_vert(ray_start, ray_end):
	var space_state = get_viewport().get_world_3d().direct_space_state
	var pars = PhysicsRayQueryParameters3D.new()
	pars.from = ray_start
	pars.to = ray_end
	pars.collision_mask = 1
	return space_state.intersect_ray(pars)
