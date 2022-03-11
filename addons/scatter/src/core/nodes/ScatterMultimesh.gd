@tool
class_name ScatterMultimesh, "res://addons/scatter/icons/scatter-random-icon.png" extends MultiMeshInstance3D


var instances_data : Dictionary = {}

func _enter_tree():
	for instance_index in multimesh.visible_instance_count:
		var instance_transform = multimesh.get_instance_transform(instance_index)
		if !instances_data.has(instance_transform.origin):
			instances_data[instance_transform.origin] = instance_index

func update_data():
	for instance_index in multimesh.visible_instance_count:
		var instance_transform = multimesh.get_instance_transform(instance_index)
		if !instances_data.has(instance_transform.origin):
			instances_data[instance_transform.origin] = instance_index

func remove_data():
	pass

func add_data(instance_transform, index):
	multimesh.set_instance_transform(index, transform)
	if multimesh.visible_instance_count < multimesh.instance_count:
		if !instances_data.has(instance_transform.origin):
			instances_data[instance_transform.origin] = index
			multimesh.set_instance_transform(index, transform)
			multimesh.visible_instance_count += 1
		
