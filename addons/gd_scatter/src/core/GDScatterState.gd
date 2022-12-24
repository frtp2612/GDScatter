class_name GDScatterState extends Object

var active_mode : int = GDScatterMode.NONE:
	set(value):
		active_mode = value
		mode_changed.emit()

signal mode_changed

var brush = {
	"node": null,
	"active_mesh": null,
	"size": 1,
	"hardness": 1
}

var drawing : bool = false
var active_area: GDScatterArea
var active_section : GDScatterSection
var spawning_section = false

var multimesh_settings = {
	"max_instances": 100000,
	"current_instances": 200,
	"randomized_amount": 20,
}

func initialize_as_area(scatter_area: GDScatterArea):
	active_area = scatter_area
	active_area.set_state(self)
	if active_area.get_child_count() > 0:
		active_section = active_area.get_child(0)
	active_mode = GDScatterMode.EDIT
	brush.node.visible = true

func initialize_as_sector(scatter_section: GDScatterSection):
	active_section = scatter_section
	active_area = active_section.get_parent()
	active_area.set_state(self)
	active_mode = GDScatterMode.EDIT
	brush.node.visible = true

func initialize_brush(brush_node: GDBrush) -> void:
	brush.node = brush_node

func hide_scatter() -> void:
	brush.node.visible = false

func edit_mode() -> bool:
	return active_mode == GDScatterMode.EDIT

func delete_mode() -> bool:
	return active_mode == GDScatterMode.DELETE

func get_brush_position() -> Vector3:
	return brush.node.position
