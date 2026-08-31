extends Area3D

@export_multiline var tutorial_text := "Texto tutorial"
@export var show_only_once := false
@export var updates_player_respawn := true

var has_shown := false

@onready var label: Label3D = $Label3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	label.text = tutorial_text
	label.visible = false


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if show_only_once and has_shown:
		return
	if body.has_method("clear_carried_energy"):
		body.clear_carried_energy()
	if updates_player_respawn and body.has_method("set_respawn_position"):
		body.set_respawn_position(global_position)
	has_shown = true
	label.text = tutorial_text
	label.visible = true
	AudioManager.play_pop()


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and not show_only_once:
		label.visible = false
