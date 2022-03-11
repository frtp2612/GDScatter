@tool
extends EditorPlugin

enum scatter_mode {
	LOCKED,
	FREE_EDIT,
	BOUND_EDIT,
	FREE_DELETE,
	BOUND_DELETE
}
var ui_sidebar

var brush = {
	"center": null,
	"mesh": null,
	"size": 1,
	"preview": null
}

var raycast_info = {
	"hit": false,
	"hit_position": null,
	"hit_normal": null
}

var editable_object : bool = true
var drawing : bool = false

var multimesh_settings = {
	"max_instances": 100000,
	"current_instances": 200,
	"randomized_amount": 20,
}

var preview_multimesh

var attraction = 0.1

var active_scatter
var active_multimesh : ScatterMultimesh

var current_mode = scatter_mode.LOCKED:
	set(value):
		current_mode = value

func _handles(object) -> bool:
	if object is Scatter:
		# in this case you can only edit the latest created multimesh
		active_scatter = object
		if !active_scatter.tool:
			active_scatter.set_tool(self)
			if active_scatter.get_child_count() > 0:
				active_multimesh = active_scatter.get_child(0)
		current_mode = scatter_mode.FREE_EDIT
		brush.center.change_mode(false)
		brush.center.visible = true
		return true
	elif object is ScatterMultimesh:
		# in this case you can only edit the selected multimesh
		active_multimesh = object
		current_mode = scatter_mode.BOUND_EDIT
		brush.center.change_mode(false)
		brush.center.visible = true
		return true
	current_mode = scatter_mode.LOCKED
	brush.center.visible = false
	return false

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			if edit_mode():
				current_mode = scatter_mode.BOUND_DELETE if current_mode == scatter_mode.BOUND_EDIT else scatter_mode.FREE_DELETE
				brush.center.change_mode(true)
				brush.preview.multimesh.visible_instance_count = 0
			elif delete_mode():
				current_mode = scatter_mode.BOUND_EDIT if current_mode == scatter_mode.BOUND_DELETE else scatter_mode.FREE_EDIT
				brush.center.change_mode(false)
				brush.preview.multimesh.visible_instance_count = multimesh_settings.current_instances

func _forward_3d_gui_input(viewport_camera, event):
	if !edit_mode() and !delete_mode():
		return false
	
	display_brush()
	raycast(viewport_camera, event)

	if raycast_info.hit:
		return user_input(event) #the returned value blocks or unblocks the default input from godot
	else:
		return false

func display_brush() -> void:
	if brush.mesh:
		if raycast_info.hit:
			brush.center.visible = true
			brush.center.position = raycast_info.hit_position
			brush.mesh.scale = Vector3.ONE * brush.size
		else:
			brush.center.visible = false

func raycast(camera : Camera3D, event : InputEvent) -> void:
	if event is InputEventMouse:
		#RAYCAST FROM CAMERA:
		var ray_origin = camera.project_ray_origin(event.position)
		var ray_dir = camera.project_ray_normal(event.position)
		var ray_distance = camera.far

		var hit = raycast_from_vert(ray_origin, ray_origin + ray_dir * ray_distance)
		
		#IF RAYCAST HITS A DRAWABLE SURFACE:
		if hit:
			if brush.preview and edit_mode():
				place_elements(brush.preview)
			raycast_info.hit = true
			raycast_info.hit_position = hit.position
			raycast_info.hit_normal = hit.normal
		else:
			raycast_info.hit = false

func raycast_from_vert(ray_start, ray_end):
	var space_state = get_viewport().get_world_3d().direct_space_state
	var pars = PhysicsRayQueryParameters3D.new()
	pars.from = ray_start
	pars.to = ray_end
	pars.collision_mask = 1
	return space_state.intersect_ray(pars)

func user_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			drawing = true
			process_drawing()
			return true
		else:
			drawing = false

	if drawing and event is InputEventMouse:
		process_drawing()
		return true
	
	drawing = false
	return false

func process_drawing():
	if active_multimesh:
		if edit_mode():
			add_elements()
		elif delete_mode():
			remove_elements()

func add_elements():
	var visible_instances = active_multimesh.multimesh.visible_instance_count
	
	for instance_index in multimesh_settings.current_instances:
		
		if instance_index + visible_instances < active_multimesh.multimesh.instance_count:
			var instance_transform = brush.preview.multimesh.get_instance_transform(instance_index)
			instance_transform.origin = instance_transform.origin + brush.center.position

			add_instance_to_multimesh(instance_index + visible_instances, instance_transform)
		else:
			active_scatter.spawn_multimesh()
#			active_multimesh.multimesh.set_instance_transform(instance_index, transform)
#			active_multimesh.add_data(transform, instance_index)

func remove_elements():
	var updated_multimesh = MultiMesh.new()
	updated_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	updated_multimesh.mesh = active_multimesh.multimesh.mesh
	updated_multimesh.instance_count = active_multimesh.multimesh.instance_count

	var index = 0
	for instance_index in active_multimesh.multimesh.visible_instance_count:
		var transform = active_multimesh.multimesh.get_instance_transform(instance_index)
		if Vector2(transform.origin.x, transform.origin.z).distance_to(Vector2(brush.center.position.x, brush.center.position.z)) > brush.size:
			updated_multimesh.set_instance_transform(index, transform)
			index += 1
	updated_multimesh.visible_instance_count = index
	updated_multimesh.set_local_to_scene(true)
	updated_multimesh.setup_local_to_scene()
	active_multimesh.multimesh = updated_multimesh

func add_instance_to_multimesh(instance_index, instance_transform):
	if !active_multimesh.instances_data.has(instance_transform.origin):
		active_multimesh.instances_data[instance_transform.origin] = instance_index
		active_multimesh.multimesh.set_instance_transform(instance_index, instance_transform)
		active_multimesh.multimesh.visible_instance_count += 1

func place_elements(multimesh_instance):
	var position_range_start = 0
	var position_range_end = brush.size
	var theta : float = 0.0
	
	multimesh_instance.multimesh.instance_count = multimesh_settings.current_instances
	
	var center = brush.center.position
	
	for instance_index in multimesh_settings.current_instances:
		randomize()
		# angle of the point around the circle
		
		theta = randf() * 2.0 * PI
		var point_distance_from_center : float = sqrt(randf()) * brush.size
		var x = center.x + point_distance_from_center * cos(theta)
		var z = center.z + point_distance_from_center * sin(theta)
		var start_position = Vector3(x, 1000, z)
		var target_position = get_projected_position(start_position)
		var y = 0

		if target_position != null:
			y = target_position.y

		var vertical_rotation = sqrt(multimesh_settings.randomized_amount)
		var horizontal_rotation = sqrt(multimesh_settings.randomized_amount * 0.01)

		var transform = Transform3D().\
		rotated(Vector3.UP, randf_range(-vertical_rotation, vertical_rotation)).\
		rotated(Vector3.LEFT, randf_range(-horizontal_rotation, horizontal_rotation)).\
		rotated(Vector3.FORWARD, randf_range(-horizontal_rotation, horizontal_rotation))
		transform.origin = Vector3(x - center.x, y - center.y, z - center.z)
		multimesh_instance.multimesh.set_instance_transform(instance_index, transform)
	

func get_projected_position(ray_start):
	var ray_end = Vector3(ray_start.x, ray_start.y-10000, ray_start.z)
	var result = raycast_from_vert(ray_start, ray_end)
	if result:
		return result.position
	return null

func _enter_tree():
	add_ui()
	var brush_scene = preload("./src/core/brushes/Brush.tscn").instantiate()
	brush.center = brush_scene
	add_child(brush.center)
	brush.mesh = brush.center.brush_area
	brush.preview = brush.center.multi_mesh

func add_ui():
	if !ui_sidebar:
		ui_sidebar = preload("./src/core/ui/UI.tscn").instantiate()
#		add_control_to_bottom_panel(ui_sidebar, "sidebar")
		add_control_to_dock(DOCK_SLOT_LEFT_UL, ui_sidebar)
#		add_control_to_container(EditorPlugin.CONTAINER_PROPERTY_EDITOR_BOTTOM, ui_sidebar)
		ui_sidebar.set_tool(self)
		ui_sidebar.visible = true

func _exit_tree():
#	remove_custom_type("Scatter")
	remove_control_from_docks(ui_sidebar)
#	remove_control_from_container(EditorPlugin.CONTAINER_PROPERTY_EDITOR_BOTTOM, ui_sidebar)
	if ui_sidebar:
		ui_sidebar.free()

func edit_mode():
	return current_mode == scatter_mode.FREE_EDIT or current_mode == scatter_mode.BOUND_EDIT

func delete_mode():
	return current_mode == scatter_mode.FREE_DELETE or current_mode == scatter_mode.BOUND_DELETE
