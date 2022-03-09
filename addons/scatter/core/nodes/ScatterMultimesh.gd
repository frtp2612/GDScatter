@tool
class_name ScatterMultimesh extends MultiMeshInstance3D


var instances_data : Dictionary = {}

func _enter_tree():
#	multimesh.visible_instance_count = -1
	pass

func remove_data():
	pass

func add_data(instance_transform, index):
	multimesh.set_instance_transform(index, transform)
	if multimesh.visible_instance_count < multimesh.instance_count:
		if !instances_data.has(instance_transform.origin):
			instances_data[instance_transform.origin] = index
			multimesh.set_instance_transform(index, transform)
			multimesh.visible_instance_count += 1
		
