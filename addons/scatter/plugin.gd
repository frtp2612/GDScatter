@tool
extends EditorPlugin


var ui_sidebar

var brush = {
	"mesh": null,
	"size": 1
}

var edit_mode = true
var raycast_info = {
	"hit": false,
	"hit_position": null,
	"hit_normal": null
}

var editable_object : bool = true
var drawing : bool = false

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
			brush.mesh.visible = true
			brush.mesh.position = raycast_info.hit_position
			brush.mesh.scale = Vector3.ONE * brush.size
		else:
			brush.mesh.visible = false

func raycast(camera : Camera3D, event : InputEvent) -> void:
	if event is InputEventMouse:
		#RAYCAST FROM CAMERA:
		var ray_origin = camera.project_ray_origin(event.position)
		var ray_dir = camera.project_ray_normal(event.position)
		var ray_distance = camera.far

		var hit = raycast_from_vert(ray_origin, ray_origin + ray_dir * ray_distance)
		
		#IF RAYCAST HITS A DRAWABLE SURFACE:
		if hit:
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
#	var position_range_end = radius * 0.2
#	var theta := 0
#	var batch = batch_index * instances
#
#	for instance_index in instances:
#		randomize()
#		var x: float
#		var z: float
#		var theta_x = theta
#		var theta_z = theta
#		x = center.x + randf_range(position_range_start, position_range_end) * cos(theta_x)
#		z = center.z + randf_range(position_range_start, position_range_end) * sin(theta_z)
#		theta += 1
#		var start_position = Vector3(x, 100, z)
#		var target_position = get_projected_position(start_position)
#		var y = 0
#
#		if target_position != null:
#			y = target_position.y
#
#		var vertical_rotation = sqrt(random_amount) if randomize_vertical_rotation else 0
#		var horizontal_rotation = sqrt(random_amount * 0.01) if randomize_horizontal_rotation else 0
#
#		var transform = Transform3D().\
#		rotated(Vector3.UP, randf_range(-vertical_rotation, vertical_rotation)).\
#		rotated(Vector3.LEFT, randf_range(-horizontal_rotation, horizontal_rotation)).\
#		rotated(Vector3.FORWARD, randf_range(-horizontal_rotation, horizontal_rotation))
#		transform.origin = Vector3(x - center.x, y, z - center.z)
#		multimesh.set_instance_transform(instance_index + batch, transform)


func _enter_tree():
	add_ui()
	brush.mesh = preload("./core/brushes/Brush.tscn").instantiate()
	add_child(brush.mesh)

func add_ui():
	ui_sidebar = preload("./core/ui/UI.tscn").instantiate()
	add_control_to_bottom_panel(ui_sidebar, "sidebar")
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, ui_sidebar)
	ui_sidebar.visible = true
	ui_sidebar.tool = self

func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, ui_sidebar)
	if ui_sidebar:
		ui_sidebar.free()
