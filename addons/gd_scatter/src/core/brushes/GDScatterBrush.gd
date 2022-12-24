@tool
extends GDBrush

func change_mode() -> void:
	if global_state.edit_mode():
		influence_area.material_override = edit_material
	elif global_state.delete_mode():
		influence_area.material_override = delete_material
	else:
		influence_area.material_override = null
