extends MultiMeshInstance3D


@export_node_path(MeshInstance3D) var terrain_path:
	set(value):
		terrain_path = value
		terrain = get_node(value)
		scatter()
@export_node_path(Path3D) var path_path:
	set(value):
		path_path = value
		path = get_node(value)
		scatter()
@export_range(0.0, 100.0, 1) var radius = 10.0:
	set(value):
		radius = value
		scatter()
@export_range(0, 100) var random_amount = 10:
	set(value):
		random_amount = value
		scatter()
@export_range(0, 10000, 10) var instances = 100:
	set(value):
		instances = value
		scatter()
@export var randomize_vertical_rotation = false:
	set(value):
		randomize_vertical_rotation = value
		scatter()
@export var randomize_horizontal_rotation = false:
	set(value):
		randomize_horizontal_rotation = value
		scatter()
@export var follow_path = false:
	set(value):
		follow_path = value
		scatter()

var terrain
var terrain_center
var path_center

var path

var position_range_start = 0

var scatter_center

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	if terrain != null:
		terrain_center = terrain.global_transform.origin
		scatter()
	if path != null:
		path_center = path.global_transform.origin
		scatter()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global_transform.origin != scatter_center:
		scatter_center = global_transform.origin
		scatter()
	if terrain != null && terrain.global_transform.origin != terrain_center:
		terrain_center = terrain.global_transform.origin
		scatter()
	if path != null && path.global_transform.origin != path_center:
		path_center = path.global_transform.origin
		scatter()

func scatter():
	if terrain != null:
		scatter_center = global_transform.origin
		multimesh.instance_count = instances
		
		if path and follow_path:
			draw_along_path()
		else:
			draw_in_radius(scatter_center, instances, 0)

func draw_along_path():
	var points_array = path.get_curve().get_baked_points()
	var points = points_array.size()
	
	var instances_per_point = instances / points
	var batch_index = 0
	for point in points_array:
		var position_range_end = radius * 0.2
		var theta := 0
		var batch = batch_index * instances_per_point
		
		for instance_index in instances_per_point:
			randomize()
			var x: float
			var z: float
			var theta_x = theta
			var theta_z = theta
			x = point.x + randf_range(position_range_start, position_range_end) * cos(theta_x)
			z = point.z + randf_range(position_range_start, position_range_end) * sin(theta_z)
			theta += 1
			var start_position = Vector3(x, 100, z)
			var target_position = get_projected_position(start_position)
			var y = 0
			
			if target_position != null:
				y = target_position.y
			
			var vertical_rotation = sqrt(random_amount) if randomize_vertical_rotation else 0
			var horizontal_rotation = sqrt(random_amount * 0.01) if randomize_horizontal_rotation else 0
			
			var transform = Transform3D().\
			rotated(Vector3.UP, randf_range(-vertical_rotation, vertical_rotation)).\
			rotated(Vector3.LEFT, randf_range(-horizontal_rotation, horizontal_rotation)).\
			rotated(Vector3.FORWARD, randf_range(-horizontal_rotation, horizontal_rotation))
			transform.origin = Vector3(x, y, z)
			multimesh.set_instance_transform(instance_index + batch, transform)
		batch_index += 1

func draw_in_radius(center : Vector3, instances : int, batch_index : int):
	var position_range_end = radius * 0.2
	var theta := 0
	var batch = batch_index * instances
	
	for instance_index in instances:
		randomize()
		var x: float
		var z: float
		var theta_x = theta
		var theta_z = theta
		x = center.x + randf_range(position_range_start, position_range_end) * cos(theta_x)
		z = center.z + randf_range(position_range_start, position_range_end) * sin(theta_z)
		theta += 1
		var start_position = Vector3(x, 100, z)
		var target_position = get_projected_position(start_position)
		var y = 0
		
		if target_position != null:
			y = target_position.y
		
		var vertical_rotation = sqrt(random_amount) if randomize_vertical_rotation else 0
		var horizontal_rotation = sqrt(random_amount * 0.01) if randomize_horizontal_rotation else 0
		
		var transform = Transform3D().\
		rotated(Vector3.UP, randf_range(-vertical_rotation, vertical_rotation)).\
		rotated(Vector3.LEFT, randf_range(-horizontal_rotation, horizontal_rotation)).\
		rotated(Vector3.FORWARD, randf_range(-horizontal_rotation, horizontal_rotation))
		transform.origin = Vector3(x - center.x, y, z - center.z)
		multimesh.set_instance_transform(instance_index + batch, transform)

func raycast_from_vert(start_pos):
	var ray_start = start_pos
	var ray_end = Vector3(start_pos.x, start_pos.y-1000, start_pos.z)
	var space_state = get_world_3d().direct_space_state
	var pars = PhysicsRayQueryParameters3D.new()
	pars.from = ray_start
	pars.to = ray_end
	pars.collision_mask = 1
	return space_state.intersect_ray(pars)

func get_projected_position(_position):
	var result = raycast_from_vert(_position)
	if result:
		return result.position
	return null
