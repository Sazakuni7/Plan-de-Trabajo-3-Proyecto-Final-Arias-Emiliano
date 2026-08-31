extends Node3D

@export var spin_speed := 2.8
@export var wobble_speed := 1.7
@export var wobble_amount := 0.08

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	rotation.y += spin_speed * delta
	scale.x = 1.0 + sin(_time * wobble_speed) * wobble_amount
	scale.z = 1.0 + cos(_time * wobble_speed) * wobble_amount
