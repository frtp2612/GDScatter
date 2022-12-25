@tool
extends EditorPlugin

var ui_sidebar

var brush = {
	"center": null,
	"mesh": null,
	"size": 1,
	"preview": null,
	"hardness": 1
}

var raycast_info = {
	"hit": false,
	"hit_position": null,
	"hit_normal": null
}

var drawing : bool = false

var multimesh_settings = {
	"max_instances": 100000,
	"current_instances": 200,
	"randomized_amount": 20,
}

var active_scatter
var active_multimesh : GDScatterMultimesh
var spawning_multimesh = false

var current_mode = GDScatterMode.LOCKED:
	set(value):
		current_mode = value

func _handles(object) -> bool:
	if object is GDScatter:
		# in this case you can only edit the latest created multimesh
		active_scatter = object
		if !active_scatter.tool:
			active_scatter.set_tool(self)
			if active_scatter.get_child_count() > 0:
				active_multimesh = active_scatter.get_child(0)
		current_mode = GDScatterMode.FREE_EDIT
		brush.center.change_mode(false)
		brush.center.visible = true
		return true
	elif object is GDScatterArea:
		# in this case you can only edit the selected area
		object.activate(self)
		return true
	elif object is GDScatterMultimesh:
		# in this case you can only edit the selected multimesh
		active_multimesh = object
		active_scatter = active_multimesh.get_parent()
		active_scatter.activate(self)
		current_mode = GDScatterMode.BOUND_EDIT
		brush.center.change_mode(false)
		brush.center.visible = true
		return true
	current_mode = GDScatterMode.LOCKED
	brush.center.visible = false
	active_scatter = null
	return false

func _input(event):
	if active_scatter and event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			if edit_mode():
				current_mode = GDScatterMode.BOUND_DELETE if current_mode == GDScatterMode.BOUND_EDIT else GDScatterMode.FREE_DELETE
				brush.center.change_mode(true)
				brush.preview.multimesh.visible_instance_count = 0
			elif delete_mode():
				current_mode = GDScatterMode.BOUND_EDIT if current_mode == GDScatterMode.BOUND_DELETE else GDScatterMode.FREE_EDIT
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
	if active_multimesh and !spawning_multimesh:
		if edit_mode():
			add_elements()
		elif delete_mode():
			remove_elements()

func add_elements():
	var visible_instances = active_multimesh.multimesh.visible_instance_count
	for instance_index in multimesh_settings.current_instances * brush.hardness:
		var instance_transform = brush.preview.multimesh.get_instance_transform(instance_index)
		if !active_multimesh.existing_instances_data.has(instance_transform.origin):
			instance_transform.origin = instance_transform.origin + brush.center.position
			if instance_index + visible_instances < active_multimesh.multimesh.instance_count:
				add_instance_to_multimesh(instance_index + visible_instances, instance_transform)
			elif !active_multimesh.deleted_instances_data.is_empty():
				var available_index = active_multimesh.deleted_instances_data.pop_front()
				add_instance_to_multimesh(available_index, instance_transform)
			else:
				if !bound_edit():
					spawning_multimesh = true
					active_scatter.spawn_multimesh()
					# this break is necessary to allow the engine to process the change of active multimesh
					# otherwise it will still detect that the visible instances are exceeding the max instance count
					# and will add n new multimesh nodes
					break

func remove_elements():
	for instance_origin in active_multimesh.existing_instances_data.keys():
		var instance_index = active_multimesh.existing_instances_data[instance_origin]
		if Vector2(instance_origin.x, instance_origin.z).distance_to(Vector2(brush.center.position.x, brush.center.position.z)) <= brush.size:
			active_multimesh.multimesh.set_instance_transform(instance_index, Transform3D())
			active_multimesh.deleted_instances_data.push_back(instance_index)
			active_multimesh.existing_instances_data.erase(instance_origin)
	if active_multimesh.existing_instances_data.is_empty() and active_scatter.get_child_count() > 1:
		active_multimesh.free()
		active_multimesh = null

func add_instance_to_multimesh(instance_index, instance_transform):
	active_multimesh.existing_instances_data[instance_transform.origin] = instance_index
	active_multimesh.multimesh.set_instance_transform(instance_index, instance_transform)
	if active_multimesh.multimesh.visible_instance_count < active_multimesh.multimesh.instance_count:
		active_multimesh.multimesh.visible_instance_count += 1

func place_elements(multimesh_instance):
	var position_range_start = 0
	var position_range_end = brush.size
	var theta : float = 0.0
	
	multimesh_instance.multimesh.instance_count = multimesh_settings.current_instances
	
	var center = brush.center.position
	
	for instance_index in multimesh_settings.current_instances:
		randomize()
		theta = randf() * 2.0 * PI
		var point_distance_from_center : float = sqrt(randf()) * brush.size
		var x = center.x + point_distance_from_center * cos(theta)
		var z = center.z + point_distance_from_center * sin(theta)
		var start_position = Vector3(x, 10000, z)
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
	var ray_end = Vector3(ray_start.x, ray_start.y-100000, ray_start.z)
	var result = raycast_from_vert(ray_start, ray_end)
	if result:
		return result.position
	return null

func _enter_tree():
	var brush_scene = preload("./src/core/brushes/Brush.tscn").instantiate()
	brush.center = brush_scene
	add_child(brush.center)
	brush.mesh = brush.center.brush_area
	brush.preview = brush.center.multi_mesh
	
	add_ui()

func add_ui():
	if !ui_sidebar:
		ui_sidebar = preload("./src/core/ui/UI.tscn").instantiate()
		add_custom_type("GDScatter", "Node3D", preload("./src/core/nodes/GDScatter.gd"), preload("./src/icons/scatter-icon.png"))
		add_custom_type("GDScatterMultimesh", "MultimeshInstance3D", preload("./src/core/nodes/GDScatterMultimesh.gd"), preload("./src/icons/scatter-random-icon.png"))
		add_custom_type("GDScatterArea", "Node3D", preload("./src/core/nodes/GDScatterArea.gd"), preload("./src/icons/scatter-icon.png"))
		add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UR, ui_sidebar)
		ui_sidebar.set_tool(self)
		ui_sidebar.visible = true

func _exit_tree():
	remove_custom_type("GDScatter")
	remove_custom_type("GDScatterMultimesh")
	remove_custom_type("GDScatterArea")
	if ui_sidebar:
		remove_control_from_docks(ui_sidebar)
		ui_sidebar.free()

func _hide_tool():
	if ui_sidebar:
		remove_control_from_docks(ui_sidebar)
		ui_sidebar.free()

func edit_mode():
	return current_mode == GDScatterMode.FREE_EDIT or current_mode == GDScatterMode.BOUND_EDIT

func bound_edit():
	return current_mode == GDScatterMode.BOUND_EDIT

func delete_mode():
	return current_mode == GDScatterMode.FREE_DELETE or current_mode == GDScatterMode.BOUND_DELETE
