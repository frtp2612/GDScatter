@tool
extends EditorPlugin


var ui_sidebar

var brush = {
	"center": null,
	"mesh": null,
	"size": 1,
	"preview": null
}

var edit_mode = true
var raycast_info = {
	"hit": false,
	"hit_position": null,
	"hit_normal": null
}

var editable_object : bool = true
var drawing : bool = false

var multimesh_settings = {
	"max_instances": 10000,
	"current_instances": 200,
	"randomized_amount": 20,
}

var preview_multimesh

func _handles(object) -> bool:
	return editable_object

func _forward_3d_gui_input(viewport_camera, event) -> bool:
	if !edit_mode:
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
			if brush.preview:
				place_elements(brush.preview)
			raycast_info.hit = true
			raycast_info.hit_position = hit.position
#			print(raycast_info)
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
	print("adding elements")
	pass
#	add instances to first multimesh
#	if multimesh max instances is reached, create a new multimesh
#	use current multimesh instance to add object to

func place_elements(multimesh_instance):
	var position_range_start = 0
	var position_range_end = brush.size
	var theta := 0
	
	multimesh_instance.multimesh.instance_count = multimesh_settings.current_instances
	var center = brush.center.position

	for instance_index in multimesh_settings.current_instances:
		randomize()
		var x: float
		var z: float
		var theta_x = theta
		var theta_z = theta
		x = center.x + randf_range(position_range_start, position_range_end) * cos(theta_x)
		z = center.z + randf_range(position_range_start, position_range_end) * sin(theta_z)
		theta += 1
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
	var brush_scene = preload("./core/brushes/Brush.tscn").instantiate()
	brush.center = brush_scene
	add_child(brush.center)
	brush.mesh = brush.center.brush_area
	brush.preview = brush.center.multi_mesh

func add_ui():
	if !ui_sidebar:
		ui_sidebar = preload("./core/ui/UI.tscn").instantiate()
#		add_control_to_bottom_panel(ui_sidebar, "sidebar")
		add_control_to_container(EditorPlugin.CONTAINER_PROPERTY_EDITOR_BOTTOM, ui_sidebar)
		ui_sidebar.set_tool(self)
		ui_sidebar.visible = true

func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_PROPERTY_EDITOR_BOTTOM, ui_sidebar)
	if ui_sidebar:
		ui_sidebar.free()
