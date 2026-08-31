extends Node

signal containers_changed
signal level_completed
signal game_state_changed(new_state: int)

enum GameState { PLAYING, WON, LOST }

var state: int = GameState.PLAYING
var player: Node = null
var portal: Node = null
var containers: Array[Node] = []


func _ready() -> void:
	_setup_default_input()


func reset_game() -> void:
	state = GameState.PLAYING
	player = null
	portal = null
	containers.clear()
	game_state_changed.emit(state)


func setup_level(level_player: Node, level_portal: Node) -> void:
	player = level_player
	portal = level_portal
	_update_portal_state()


func register_container(container: Node) -> void:
	if containers.has(container):
		return
	containers.append(container)
	if container.has_signal("fill_changed"):
		container.fill_changed.connect(_on_container_fill_changed)
	containers_changed.emit()
	_update_portal_state()


func unregister_container(container: Node) -> void:
	containers.erase(container)
	containers_changed.emit()
	_update_portal_state()


func enemy_purified(_affinity: int, _energy_amount: float) -> void:
	ScoreManager.add_purification_score()


func complete_level() -> void:
	if state != GameState.PLAYING:
		return
	if not are_all_containers_full():
		return
	state = GameState.WON
	ScoreManager.add_speed_bonus()
	ScoreManager.stop_timer()
	game_state_changed.emit(state)
	level_completed.emit()


func lose_game() -> void:
	if state != GameState.PLAYING:
		return
	state = GameState.LOST
	ScoreManager.stop_timer()
	game_state_changed.emit(state)


func are_all_containers_full() -> bool:
	if containers.size() < 3:
		return false
	for container in containers:
		if not container.is_full():
			return false
	return true


func _on_container_fill_changed(_affinity: int, _fill_percent: float) -> void:
	containers_changed.emit()
	_update_portal_state()


func _update_portal_state() -> void:
	if is_instance_valid(portal) and portal.has_method("set_active"):
		portal.set_active(are_all_containers_full())


func _setup_default_input() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("dash", KEY_SHIFT)
	_add_key_action("ability_special", KEY_Q)
	_add_key_action("affinity_water", KEY_1)
	_add_key_action("affinity_earth", KEY_2)
	_add_key_action("affinity_fire", KEY_3)
	_add_key_action("interact", KEY_E)
	_add_key_action("pause", KEY_ESCAPE)
	_add_key_action("stats", KEY_TAB)
	_add_key_action("unlock_cursor", KEY_ALT)
	_add_mouse_action("attack_primary", MOUSE_BUTTON_LEFT)
	_add_mouse_action("attack_secondary", MOUSE_BUTTON_RIGHT)


func _add_key_action(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.physical_keycode == keycode:
			return
	var input_event := InputEventKey.new()
	input_event.physical_keycode = keycode
	InputMap.action_add_event(action_name, input_event)


func _add_mouse_action(action_name: StringName, button_index: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for event in InputMap.action_get_events(action_name):
		if event is InputEventMouseButton and event.button_index == button_index:
			return
	var input_event := InputEventMouseButton.new()
	input_event.button_index = button_index
	InputMap.action_add_event(action_name, input_event)
