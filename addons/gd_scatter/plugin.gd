@tool
extends EditorPlugin

var state : GDScatterState

var ui_sidebar

var raycast_info = {
	"hit": false,
	"hit_position": null,
	"hit_normal": null
}

var space_state

func _handles(object) -> bool:
	if object is GDScatterArea:
		# in this case you can only edit the latest created multimesh
		state.initialize_as_area(object as GDScatterArea)
		space_state = get_viewport().get_world_3d().direct_space_state
		return true
	if object is GDScatterSection:
		print("is section")
		state.initialize_as_section(object as GDScatterSection)
		space_state = get_viewport().get_world_3d().direct_space_state
		# in this case you can only edit the selected multimesh
		return true
	return false

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			if state.edit_mode():
				state.active_mode = GDScatterMode.DELETE
				state.brush.node.preview_area.multimesh.visible_instance_count = 0
			elif state.delete_mode():
				state.active_mode = GDScatterMode.EDIT
				state.brush.node.preview_area.multimesh.visible_instance_count = state.multimesh_settings.current_instances

func _forward_3d_gui_input(viewport_camera, event):
	if !state.edit_mode() and !state.delete_mode():
		return false
	
	display_brush()
	raycast(viewport_camera, event)

	if raycast_info.hit:
		return user_input(event) #the returned value blocks or unblocks the default input from godot
	else:
		return false

func display_brush() -> void:
	if raycast_info.hit:
		state.brush.node.visible = true
		state.brush.node.position = raycast_info.hit_position
		if state.brush.active_mesh:
			state.brush.active_mesh.scale = Vector3.ONE * state.brush.size
	else:
		state.brush.node.visible = false

func raycast(camera : Camera3D, event : InputEvent) -> void:
	if event is InputEventMouse:
		#RAYCAST FROM CAMERA:
		var ray_origin = camera.project_ray_origin(event.position)
		var ray_dir = camera.project_ray_normal(event.position)
		var ray_distance = camera.far

		var hit = raycast_from_vert(ray_origin, ray_origin + ray_dir * ray_distance)
		
		#IF RAYCAST HITS A DRAWABLE SURFACE:
		if hit:
			if state.brush.node.preview_area and state.edit_mode():
				place_elements()
			raycast_info.hit = true
			raycast_info.hit_position = hit.position
			raycast_info.hit_normal = hit.normal
		else:
			raycast_info.hit = false

func place_elements():
	if state:
		var position_range_start = 0
		var position_range_end = state.brush.size
		var theta : float = 0.0
		
		var center = state.get_brush_position()
		
		for instance_index in state.multimesh_settings.current_instances:
			randomize()
			theta = randf() * 2.0 * PI
			var point_distance_from_center : float = sqrt(randf()) * state.brush.size
			var x = center.x + point_distance_from_center * cos(theta)
			var z = center.z + point_distance_from_center * sin(theta)
			var start_position = Vector3(x, 10000, z)
			var target_position = get_projected_position(start_position)
			var y = 0

			if target_position != null:
				y = target_position.y
			var random_amount = state.multimesh_settings.randomized_amount
			var vertical_rotation = sqrt(random_amount)
			var horizontal_rotation = sqrt(random_amount * 0.01)

			var transform = Transform3D().\
			rotated(Vector3.UP, randf_range(-vertical_rotation, vertical_rotation)).\
			rotated(Vector3.LEFT, randf_range(-horizontal_rotation, horizontal_rotation)).\
			rotated(Vector3.FORWARD, randf_range(-horizontal_rotation, horizontal_rotation))
			transform.origin = Vector3(x - center.x, y - center.y, z - center.z)
			state.brush.node.preview_area.multimesh.set_instance_transform(instance_index, transform)

func get_projected_position(ray_start):
	var ray_end = Vector3(ray_start.x, ray_start.y-100000, ray_start.z)
	var result = raycast_from_vert(ray_start, ray_end)
	if result:
		return result.position
	return null

func raycast_from_vert(ray_start, ray_end):
	var pars = PhysicsRayQueryParameters3D.new()
	pars.from = ray_start
	pars.to = ray_end
	pars.collision_mask = 1
	return space_state.intersect_ray(pars)

func user_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			state.drawing = true
			process_drawing()
			return true
		else:
			state.drawing = false

	if state.drawing and event is InputEventMouse:
		process_drawing()
		return true
	
	state.drawing = false
	return false

func process_drawing():
	if state.active_section and !state.spawning_section:
		if state.edit_mode():
			state.active_section.add_elements()
		elif state.delete_mode():
			state.active_section.remove_elements()

func _enter_tree():
	state = GDScatterState.new()
	var brush_scene = preload("./src/core/brushes/ScatterBrush.tscn").instantiate()
	add_child(brush_scene)
	state.initialize_brush(brush_scene)
	
	add_ui()

func add_ui():
	if !ui_sidebar:
		ui_sidebar = preload("./src/core/ui/UI.tscn").instantiate()
		add_custom_type("GDScatterArea", "Node3D", preload("./src/core/nodes/GDScatterArea.gd"), preload("./src/icons/scatter-icon.png"))
		add_custom_type("GDScatterSection", "MultimeshInstance3D", preload("./src/core/nodes/GDScatterSection.gd"), preload("./src/icons/scatter-random-icon.png"))
		add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UR, ui_sidebar)
		ui_sidebar.set_tool(self)
		ui_sidebar.set_state(state)
		ui_sidebar.visible = true

func _exit_tree():
	remove_custom_type("GDScatterArea")
	remove_custom_type("GDScatterSection")
	if ui_sidebar:
		remove_control_from_docks(ui_sidebar)
		ui_sidebar.free()

func _hide_tool():
	if ui_sidebar:
		remove_control_from_docks(ui_sidebar)
		ui_sidebar.free()
