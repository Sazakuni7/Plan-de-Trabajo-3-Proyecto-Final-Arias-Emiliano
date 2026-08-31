extends Node3D

const ENEMY_SCENES := {
	AffinityManager.Affinity.WATER: preload("res://src/scenes/enemies/EnemyWater.tscn"),
	AffinityManager.Affinity.EARTH: preload("res://src/scenes/enemies/EnemyEarth.tscn"),
	AffinityManager.Affinity.FIRE: preload("res://src/scenes/enemies/EnemyFire.tscn"),
}
const MAIN_MENU_SCENE := "res://src/scenes/ui/MainMenu.tscn"

@export var max_enemies := 9
@export var spawn_interval := 3.0
@export var enable_runtime_spawns := true

var spawn_index := 0
var spawn_points: Array[Node3D] = []

@onready var player: Node = $Player
@onready var portal: Node = $Portal
@onready var hud: CanvasLayer = $HUD
@onready var pause_menu: CanvasLayer = $PauseMenu
#@onready var enemy_spawn_points: Node = $EnemySpawnPoints
#@onready var enemy_spawn_timer: Timer = $EnemySpawnTimer
@onready var containers_root: Node = $Containers


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameManager.reset_game()
	ScoreManager.reset_score()
	_register_level_containers()
	_bind_existing_enemies()
	if player.has_signal("died"):
		player.died.connect(GameManager.lose_game)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.setup_level(player, portal)
	hud.bind_player(player)
	pause_menu.resume_requested.connect(_resume_game)
	pause_menu.main_menu_requested.connect(_return_to_main_menu)
	if player.projectile_scene != null:
		ProjectilePool.prewarm(player.projectile_scene, 24, self)
	AudioManager.play_level_music()


func _register_level_containers() -> void:
	for container in containers_root.get_children():
		if container.get("counts_for_portal") == true:
			GameManager.register_container(container)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()


func _bind_existing_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		_bind_enemy(enemy)


func _bind_enemy(enemy: Node) -> void:
	if enemy.has_signal("purified") and not enemy.purified.is_connected(GameManager.enemy_purified):
		enemy.purified.connect(GameManager.enemy_purified)


func _on_spawn_timer_timeout() -> void:
	if not enable_runtime_spawns:
		return
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	if spawn_points.is_empty():
		return
	if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return
	_spawn_enemy(spawn_index % 3)


func _spawn_enemy(affinity: int) -> void:
	var enemy_scene: PackedScene = ENEMY_SCENES.get(affinity)
	var enemy := enemy_scene.instantiate()
	var spawn_point := spawn_points[spawn_index % spawn_points.size()]
	spawn_index += 1
	_bind_enemy(enemy)
	add_child(enemy)
	enemy.set_spawn_position(spawn_point.global_position)


func _toggle_pause() -> void:
	if get_tree().paused:
		_resume_game()
	else:
		_pause_game()


func _pause_game() -> void:
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	pause_menu.show_menu()


func _resume_game() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pause_menu.hide_menu()


func _return_to_main_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.stop_level_music()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_level_completed() -> void:
	await get_tree().create_timer(0.75).timeout
	_return_to_main_menu()
