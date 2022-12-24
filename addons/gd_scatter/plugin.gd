@tool
extends EditorPlugin

var state : GDScatterState

var ui_sidebar

var raycast_info = {
	"hit": false,
	"hit_position": null,
	"hit_normal": null
}

func _handles(object) -> bool:
	if object is GDScatterArea:
		# in this case you can only edit the latest created multimesh
		state.initialize_as_area(object as GDScatterArea)
		return true
	elif object is GDScatterSection:
		state.initialize_as_sector(object as GDScatterSection)
		# in this case you can only edit the selected multimesh
		return true
	state.hide_scatter()
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
	if state.brush.active_mesh:
		if raycast_info.hit:
			state.brush.node.visible = true
			state.brush.node.position = raycast_info.hit_position
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
				state.active_section.place_elements()
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
	remove_custom_type("GDScatter")
	remove_custom_type("GDScatterMultimesh")
	if ui_sidebar:
		remove_control_from_docks(ui_sidebar)
		ui_sidebar.free()

func _hide_tool():
	if ui_sidebar:
		remove_control_from_docks(ui_sidebar)
		ui_sidebar.free()
