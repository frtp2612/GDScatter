@tool
class_name ScatterMultimesh, "res://addons/scatter/src/icons/scatter-random-icon.png" extends MultiMeshInstance3D

var deleted_instances_data : Array
var existing_instances_data : Dictionary

func _enter_tree():
	var instance_transform
	for instance_index in multimesh.visible_instance_count:
		instance_transform = multimesh.get_instance_transform(instance_index)
		if instance_transform == Transform3D():
			deleted_instances_data.push_back(instance_index)
		else:
			existing_instances_data[instance_transform.origin] = instance_index
