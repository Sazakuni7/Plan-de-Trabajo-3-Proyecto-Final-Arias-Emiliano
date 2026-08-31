extends Node3D

@export var visible_tornado_name := "tornado Blue"


func _ready() -> void:
	_apply_selection()


func _apply_selection() -> void:
	for child in get_children():
		if child.name == visible_tornado_name:
			if child is Node3D:
				child.visible = true
		else:
			child.queue_free()
