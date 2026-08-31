extends Area3D

@export var target_groups: Array[StringName] = [&"player", &"enemies"]


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	for group_name in target_groups:
		if body.is_in_group(group_name):
			_respawn_body(body)
			return


func _respawn_body(body: Node) -> void:
	if body.has_method("teleport_to_respawn"):
		body.teleport_to_respawn()
	elif body.has_method("teleport_to_spawn"):
		body.teleport_to_spawn()
