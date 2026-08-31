extends Area3D

signal waves_completed

const ENEMY_SCENES := {
	AffinityManager.Affinity.WATER: preload("res://src/scenes/enemies/EnemyWater.tscn"),
	AffinityManager.Affinity.EARTH: preload("res://src/scenes/enemies/EnemyEarth.tscn"),
	AffinityManager.Affinity.FIRE: preload("res://src/scenes/enemies/EnemyFire.tscn"),
}

@export var waves: Array[Vector3i] = [
	Vector3i(1, 1, 1),
	Vector3i(2, 2, 2),
	Vector3i(3, 3, 3),
]
@export var reset_player_energy_on_first_wave := true
@export var spawn_spacing := 0.8
@export var chaser_patrol_offset := Vector3(0.0, 0.0, 0.0)
@export var patrol_offset := Vector3(3.5, 0.0, 0.0)
@export var shooter_patrol_offset := Vector3(4.0, 0.0, 0.0)

var current_wave_index := 0
var player_inside := false
var did_reset_player_energy := false
var active_wave_enemies: Array[Node] = []
var affinity_bag: Array[int] = []

@onready var label: Label3D = $Label3D
@onready var spawn_points_root: Node3D = $SpawnPoints


func _ready() -> void:
	randomize()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_label()


func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact"):
		_try_start_next_wave()


func _try_start_next_wave() -> void:
	_refresh_active_wave_enemies()
	if not active_wave_enemies.is_empty():
		return
	if current_wave_index >= waves.size():
		return
	AudioManager.play_click()
	if reset_player_energy_on_first_wave and not did_reset_player_energy:
		_clear_overlapping_player_energy()
		did_reset_player_energy = true
	_spawn_wave(current_wave_index)
	current_wave_index += 1
	_update_label()


func _refresh_active_wave_enemies() -> void:
	var alive_enemies: Array[Node] = []
	for enemy in active_wave_enemies:
		if is_instance_valid(enemy):
			alive_enemies.append(enemy)
	active_wave_enemies = alive_enemies


func _spawn_wave(wave_index: int) -> void:
	var spawn_points := _get_spawn_points()
	var spawn_index := 0
	match wave_index:
		0:
			spawn_index = _spawn_enemy_group(3, 2, false, true, chaser_patrol_offset, spawn_points, spawn_index)
			_spawn_enemy_group(3, 1, false, true, patrol_offset, spawn_points, spawn_index)
		1:
			spawn_index = _spawn_enemy_group(4, 1, false, true, patrol_offset, spawn_points, spawn_index)
			spawn_index = _spawn_enemy_group(2, 2, false, true, chaser_patrol_offset, spawn_points, spawn_index)
			_spawn_enemy_group(2, 2, true, false, shooter_patrol_offset, spawn_points, spawn_index)
		_:
			spawn_index = _spawn_enemy_group(5, 1, false, true, patrol_offset, spawn_points, spawn_index)
			_spawn_enemy_group(5, 2, true, false, shooter_patrol_offset, spawn_points, spawn_index)


func _spawn_enemy_group(count: int, behavior_mode: int, can_shoot: bool, use_contact_attack: bool, group_patrol_offset: Vector3, spawn_points: Array[Node3D], start_index: int) -> int:
	var spawn_index := start_index
	for i in range(count):
		var affinity := _get_random_affinity()
		var enemy_scene: PackedScene = ENEMY_SCENES.get(affinity)
		var enemy := enemy_scene.instantiate()
		enemy.behavior_mode = behavior_mode
		enemy.can_shoot = can_shoot
		enemy.use_contact_attack = use_contact_attack
		enemy.patrol_offset = group_patrol_offset
		enemy.energy_counts_for_portal_containers = true
		var spawn_point := spawn_points[spawn_index % spawn_points.size()]
		enemy.purified.connect(GameManager.enemy_purified)
		get_tree().current_scene.add_child(enemy)
		enemy.set_spawn_position(spawn_point.global_position + _get_spawn_jitter(i))
		active_wave_enemies.append(enemy)
		spawn_index += 1
	return spawn_index


func _get_random_affinity() -> int:
	if affinity_bag.is_empty():
		affinity_bag = [
			AffinityManager.Affinity.WATER,
			AffinityManager.Affinity.EARTH,
			AffinityManager.Affinity.FIRE,
		]
		affinity_bag.shuffle()
	return affinity_bag.pop_back()


func _get_spawn_jitter(index: int) -> Vector3:
	var column := float(index % 3) - 1.0
	var row := floorf(float(index) / 3.0)
	return Vector3(column * spawn_spacing, 0.0, row * spawn_spacing)


func _clear_overlapping_player_energy() -> void:
	for body in get_overlapping_bodies():
		if body.has_method("clear_carried_energy"):
			body.clear_carried_energy()
			return


func _get_spawn_points() -> Array[Node3D]:
	var spawn_points: Array[Node3D] = []
	for child in spawn_points_root.get_children():
		if child is Node3D:
			spawn_points.append(child)
	if spawn_points.is_empty():
		spawn_points.append(self)
	return spawn_points


func _update_label() -> void:
	if current_wave_index >= waves.size():
		label.text = "Oleadas completas"
	else:
		label.text = "Interactuar: oleada %d/%d" % [current_wave_index + 1, waves.size()]


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = false
