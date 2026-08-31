extends Area3D

@export var affinity := AffinityManager.Affinity.WATER:
	set(value):
		affinity = value
		if is_inside_tree():
			_apply_affinity_material()
			_apply_affinity_status_effects()
@export var energy_amount := 25.0
@export var pickup_delay := 0.2
@export var counts_for_portal_containers := false

var _can_pickup := false

@onready var visual: MeshInstance3D = $Visual


func _ready() -> void:
	add_to_group("energy_drops")
	body_entered.connect(_on_body_entered)
	_apply_affinity_material()
	_apply_affinity_status_effects()
	await get_tree().create_timer(pickup_delay).timeout
	_can_pickup = true
	for body in get_overlapping_bodies():
		_try_pickup(body)


func _process(delta: float) -> void:
	rotate_y(delta * 2.5)


func _on_body_entered(body: Node) -> void:
	_try_pickup(body)


func _try_pickup(body: Node) -> void:
	if not _can_pickup:
		return
	if not body.has_method("collect_energy"):
		return
	body.collect_energy(affinity, energy_amount, counts_for_portal_containers)
	AudioManager.play_blip(global_position)
	queue_free()


func _apply_affinity_material() -> void:
	var material := StandardMaterial3D.new()
	var color := AffinityManager.get_affinity_color(affinity)
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	visual.set_surface_override_material(0, material)


func _apply_affinity_status_effects() -> void:
	for child in get_children():
		if child.has_method("set_affinity"):
			child.set_affinity(affinity)
		if child.has_method("set_active"):
			child.set_active(true)
