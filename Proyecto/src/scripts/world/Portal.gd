extends Area3D

@export var active := false

@onready var visual: MeshInstance3D = $Visual
@onready var label: Label3D = $Label3D

var player_inside := false
var has_played_activation_sound := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_active(active)


func _process(_delta: float) -> void:
	if active and player_inside and Input.is_action_just_pressed("interact"):
		AudioManager.play_portal(global_position)
		GameManager.complete_level()


func set_active(new_active: bool) -> void:
	var was_active := active
	active = new_active
	if active and not was_active and not has_played_activation_sound:
		AudioManager.play_portal(global_position)
		has_played_activation_sound = true
	elif not active:
		has_played_activation_sound = false
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.25, 1.0, 0.5) if active else Color(0.22, 0.22, 0.22)
	visual.set_surface_override_material(0, material)
	label.text = "Portal activo\nE para completar" if active else "Portal inactivo"


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = false
