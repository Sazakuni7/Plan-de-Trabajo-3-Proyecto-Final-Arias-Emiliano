extends CharacterBody3D

signal health_changed(current_health: float, max_health: float)
signal energy_changed(current_energy: float, max_energy: float)
signal carried_energy_changed(water: float, earth: float, fire: float)
signal aim_feedback_changed(feedback_state: int)
signal found_hud_toggled(is_visible: bool)
signal died

enum AimFeedback { NONE, VULNERABLE, RESISTANT, IMMUNE }

const FOLLOW_AREA_ATTACK_SCRIPT := preload("res://src/scripts/player/FollowAreaAttack.gd")
const ORBIT_ATTACK_SCRIPT := preload("res://src/scripts/player/OrbitAttack.gd")

@export_group("Stats")
@export var max_health := 100.0
@export var max_energy := 100.0
@export var primary_damage := 35.0
@export var secondary_damage := 20.0
@export var special_damage := 55.0
@export var projectile_scene: PackedScene

@export_group("Water Attacks")
@export var water_primary_attack: PlayerAttackConfig
@export var water_secondary_attack: PlayerAttackConfig
@export var water_ultimate_attack: PlayerAttackConfig

@export_group("Earth Attacks")
@export var earth_primary_attack: PlayerAttackConfig
@export var earth_secondary_attack: PlayerAttackConfig
@export var earth_ultimate_attack: PlayerAttackConfig

@export_group("Fire Attacks")
@export var fire_primary_attack: PlayerAttackConfig
@export var fire_secondary_attack: PlayerAttackConfig
@export var fire_ultimate_attack: PlayerAttackConfig

@export_group("Cooldowns")
@export var primary_cooldown := 0.28
@export var secondary_cooldown := 1.2
@export var ultimate_cooldown := 6.0
@export var dash_cooldown := 0.65
@export var affinity_swap_cooldown := 0.35

@export_group("Camera")
@export_range(0.0,1.0) var mouse_sensitivity := 0.10
@export var controller_look_sensitivity := 3.0
@export var tilt_upper_limit := PI / 3.0
@export var tilt_lower_limit := -PI / 3.0
@export var aim_check_distance := 80.0

@export_group("Movement")
@export var move_speed := 8.0
@export var acceleration := 20.0
@export var dash_speed := 18.0
@export var dash_duration := 0.18
@export var rotation_speed := 12.0
@export var jump_impulse := 12.0

var _camera_input_direction := Vector2.ZERO
var _last_movement_direction := Vector3.BACK
var _gravity := -30.0
var health := 100.0
var energy := 100.0
var carried_energy := {
	AffinityManager.Affinity.WATER: 0.0,
	AffinityManager.Affinity.EARTH: 0.0,
	AffinityManager.Affinity.FIRE: 0.0,
}
var carried_portal_energy := {
	AffinityManager.Affinity.WATER: 0.0,
	AffinityManager.Affinity.EARTH: 0.0,
	AffinityManager.Affinity.FIRE: 0.0,
}
var active_affinity := AffinityManager.Affinity.WATER
var barrier_time := 0.0
var dash_time := 0.0
var dash_cooldown_left := 0.0
var primary_cooldown_left := 0.0
var secondary_cooldown_left := 0.0
var ultimate_cooldown_left := 0.0
var affinity_swap_cooldown_left := 0.0
var dash_direction := Vector3.ZERO
var current_aim_feedback := AimFeedback.NONE
var found_hud_visible := false
var _has_initialized_affinity := false
var respawn_position := Vector3.ZERO

@onready var _muzzle: Marker3D = %Muzzle
@onready var visual: MeshInstance3D = $Visual
@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _camera: Camera3D = %Camera3D
@onready var _skin: SophiaSkin = %SophiaSkin


func _ready() -> void:
	health = max_health
	energy = max_energy
	respawn_position = global_position
	add_to_group("player")
	AffinityManager.affinity_changed.connect(_on_affinity_changed)
	_on_affinity_changed(AffinityManager.active_affinity)
	health_changed.emit(health, max_health)
	energy_changed.emit(energy, max_energy)
	_emit_carried_energy_changed()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("toggle_cursor"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		_camera_input_direction = event.screen_relative * mouse_sensitivity
		

func _process(delta: float) -> void:
	barrier_time = max(0.0, barrier_time - delta)
	_update_cooldowns(delta)
	_handle_affinity_input()
	_handle_combat_input()
	_handle_found_hud_input()
	_update_aim_feedback()

func _physics_process(delta: float) -> void:
	var controller_look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	_camera_pivot.rotation.x -= _camera_input_direction.y * delta
	_camera_pivot.rotation.x -= controller_look.y * controller_look_sensitivity * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit) #-30° y 30°
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta
	_camera_pivot.rotation.y -= controller_look.x * controller_look_sensitivity * delta
	
	_camera_input_direction = Vector2.ZERO
	
	var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()
	
	if Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0.0:
		_start_dash(move_direction)
	
	var y_velocity := velocity.y
	velocity.y = 0.0
	if dash_time > 0.0:
		dash_time -= delta
		velocity.x = dash_direction.x * dash_speed
		velocity.z = dash_direction.z * dash_speed
	else:
		velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	velocity.y = y_velocity + _gravity * delta
	
	var is_starting_jump := Input.is_action_just_pressed("jump") and is_on_floor()
	if is_starting_jump:
		velocity.y += jump_impulse
	
	move_and_slide()
	
	if move_direction.length() > 0.2:
		_last_movement_direction = move_direction
	var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
	_skin.rotation.y = lerp_angle(_skin.rotation.y, target_angle, rotation_speed * delta)
	
	if is_starting_jump:
		_skin.jump()
	elif not is_on_floor()	and velocity.y < 0:
		_skin.fall()
	elif is_on_floor():
		var ground_speed := velocity.length()
		if ground_speed > 0.0:
			_skin.move()
		else:
			_skin.idle()


func take_damage(amount: float, source_affinity: int) -> void:
	var affinity_multiplier := AffinityManager.get_damage_multiplier(source_affinity, active_affinity)
	if affinity_multiplier <= 0.0:
		ScoreManager.add_absorb_score()
		return
	var final_amount := amount * affinity_multiplier
	if barrier_time > 0.0:
		final_amount *= 0.35
	health = max(0.0, health - final_amount)
	AudioManager.play_hurt(global_position)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		died.emit()


func _handle_affinity_input() -> void:
	if affinity_swap_cooldown_left > 0.0:
		return
	if Input.is_action_just_pressed("select_water"):
		AffinityManager.set_affinity(AffinityManager.Affinity.WATER)
		affinity_swap_cooldown_left = affinity_swap_cooldown
	elif Input.is_action_just_pressed("select_earth"):
		AffinityManager.set_affinity(AffinityManager.Affinity.EARTH)
		affinity_swap_cooldown_left = affinity_swap_cooldown
	elif Input.is_action_just_pressed("select_fire"):
		AffinityManager.set_affinity(AffinityManager.Affinity.FIRE)
		affinity_swap_cooldown_left = affinity_swap_cooldown
	elif Input.is_action_just_pressed("cycle_elements"):
		_cycle_affinity(1)
		affinity_swap_cooldown_left = affinity_swap_cooldown


func _cycle_affinity(direction: int) -> void:
	var next_affinity := (active_affinity + direction) % 3
	if next_affinity < 0:
		next_affinity = 2
	AffinityManager.set_affinity(next_affinity)


func _handle_combat_input() -> void:
	var primary_attack := _get_attack_config("primary")
	if Input.is_action_pressed("shoot") and primary_cooldown_left <= 0.0:
		_perform_attack(primary_attack)
		primary_cooldown_left = primary_attack.cooldown

	var secondary_attack := _get_attack_config("secondary")
	if Input.is_action_just_pressed("shoot_alt") and secondary_cooldown_left <= 0.0:
		_perform_attack(secondary_attack)
		secondary_cooldown_left = secondary_attack.cooldown

	var ultimate_attack := _get_attack_config("ultimate")
	if Input.is_action_just_pressed("ultimate") and ultimate_cooldown_left <= 0.0:
		_perform_attack(ultimate_attack)
		ultimate_cooldown_left = ultimate_attack.cooldown


func _handle_found_hud_input() -> void:
	if not Input.is_action_just_pressed("found_hud"):
		return
	found_hud_visible = not found_hud_visible
	found_hud_toggled.emit(found_hud_visible)


func _update_cooldowns(delta: float) -> void:
	dash_cooldown_left = max(0.0, dash_cooldown_left - delta)
	primary_cooldown_left = max(0.0, primary_cooldown_left - delta)
	secondary_cooldown_left = max(0.0, secondary_cooldown_left - delta)
	ultimate_cooldown_left = max(0.0, ultimate_cooldown_left - delta)
	affinity_swap_cooldown_left = max(0.0, affinity_swap_cooldown_left - delta)


func _start_dash(move_direction: Vector3) -> void:
	if move_direction.length_squared() <= 0.01:
		move_direction = _last_movement_direction
	if move_direction.length_squared() <= 0.01:
		move_direction = -_camera.global_basis.z
	move_direction.y = 0.0
	move_direction = move_direction.normalized()
	dash_direction = move_direction
	dash_time = dash_duration
	dash_cooldown_left = dash_cooldown
	AudioManager.play_dash(global_position)


func _perform_attack(attack_config: PlayerAttackConfig) -> void:
	match attack_config.attack_mode:
		PlayerAttackConfig.AttackMode.MULTI_PROJECTILE:
			_shoot_projectile_spread(attack_config)
		PlayerAttackConfig.AttackMode.FOLLOW_AREA:
			_spawn_follow_area_attack(attack_config)
		PlayerAttackConfig.AttackMode.ORBIT_PROJECTILE:
			_spawn_orbit_attack(attack_config)
		_:
			_shoot_projectile_spread(attack_config, 1, 0.0)


func _get_attack_config(attack_slot: StringName) -> PlayerAttackConfig:
	var config: PlayerAttackConfig = null
	match active_affinity:
		AffinityManager.Affinity.WATER:
			config = _get_water_attack_config(attack_slot)
		AffinityManager.Affinity.EARTH:
			config = _get_earth_attack_config(attack_slot)
		AffinityManager.Affinity.FIRE:
			config = _get_fire_attack_config(attack_slot)
	return config if config != null else _create_fallback_attack_config(attack_slot)


func _get_water_attack_config(attack_slot: StringName) -> PlayerAttackConfig:
	match attack_slot:
		&"primary":
			return water_primary_attack
		&"secondary":
			return water_secondary_attack
		&"ultimate":
			return water_ultimate_attack
	return null


func _get_earth_attack_config(attack_slot: StringName) -> PlayerAttackConfig:
	match attack_slot:
		&"primary":
			return earth_primary_attack
		&"secondary":
			return earth_secondary_attack
		&"ultimate":
			return earth_ultimate_attack
	return null


func _get_fire_attack_config(attack_slot: StringName) -> PlayerAttackConfig:
	match attack_slot:
		&"primary":
			return fire_primary_attack
		&"secondary":
			return fire_secondary_attack
		&"ultimate":
			return fire_ultimate_attack
	return null


func _create_fallback_attack_config(attack_slot: StringName) -> PlayerAttackConfig:
	var config := PlayerAttackConfig.new()
	match attack_slot:
		&"secondary":
			config.damage = secondary_damage
			config.cooldown = secondary_cooldown
			config.projectile_speed = 18.0
			config.projectile_count = 3
			config.spread_arc_degrees = 28.0
		&"ultimate":
			config.attack_mode = PlayerAttackConfig.AttackMode.MULTI_PROJECTILE
			config.damage = special_damage
			config.cooldown = ultimate_cooldown
			config.projectile_speed = 24.0
			config.projectile_count = 5
			config.spread_arc_degrees = 55.0
		_:
			config.damage = primary_damage
			config.cooldown = primary_cooldown
			config.projectile_speed = 22.0
			config.projectile_count = 1
			config.spread_arc_degrees = 16.0
	return config


func _shoot_projectile_spread(attack_config: PlayerAttackConfig, count_override := -1, arc_override := -1.0) -> void:
	if projectile_scene == null:
		return
	var count: int = max(1, count_override if count_override > 0 else attack_config.projectile_count)
	var arc_degrees := arc_override if arc_override >= 0.0 else attack_config.spread_arc_degrees
	var arc := deg_to_rad(arc_degrees)
	for index in range(count):
		var t := 0.5 if count == 1 else float(index) / float(count - 1)
		var angle := lerpf(-arc * 0.5, arc * 0.5, t)
		var direction := (-_muzzle.global_basis.z).rotated(Vector3.UP, angle).normalized()
		var spawn_transform := _muzzle.global_transform
		spawn_transform.basis = Basis.looking_at(direction, Vector3.UP)
		ProjectilePool.spawn(projectile_scene, get_tree().current_scene, spawn_transform, direction, active_affinity, attack_config.damage, self, attack_config.projectile_speed, attack_config.vfx_scene, attack_config.vfx_scale, attack_config.vfx_rotation_degrees, attack_config.knockback_force, attack_config.vfx_light_energy_multiplier, attack_config.vfx_light_range)
	_play_attack_cast_sound(attack_config, _muzzle.global_position)


func _spawn_follow_area_attack(attack_config: PlayerAttackConfig) -> void:
	var attack := Area3D.new()
	attack.name = "FollowAreaAttack"
	attack.set_script(FOLLOW_AREA_ATTACK_SCRIPT)
	get_tree().current_scene.add_child(attack)
	attack.call("setup", attack_config, active_affinity, self)
	_play_attack_cast_sound(attack_config, global_position)


func _spawn_orbit_attack(attack_config: PlayerAttackConfig) -> void:
	var attack := Node3D.new()
	attack.name = "OrbitAttack"
	attack.set_script(ORBIT_ATTACK_SCRIPT)
	get_tree().current_scene.add_child(attack)
	attack.call("setup", attack_config, active_affinity, self)
	_play_attack_cast_sound(attack_config, global_position)


func _play_attack_cast_sound(attack_config: PlayerAttackConfig, position: Vector3) -> void:
	match attack_config.cast_sound:
		PlayerAttackConfig.CastSound.SECONDARY:
			AudioManager.play_secondary_cast(active_affinity, position)
		PlayerAttackConfig.CastSound.ULTIMATE:
			AudioManager.play_ultimate_cast(active_affinity, position)
		_:
			AudioManager.play_cast(active_affinity, position)


func collect_energy(pickup_affinity: int, amount: float, counts_for_portal_containers := false) -> void:
	if not carried_energy.has(pickup_affinity):
		return
	carried_energy[pickup_affinity] += amount
	if counts_for_portal_containers:
		carried_portal_energy[pickup_affinity] += amount
	_emit_carried_energy_changed()


func deposit_energy(deposit_affinity: int, max_amount: float, requires_portal_energy := false) -> float:
	if not carried_energy.has(deposit_affinity):
		return 0.0
	var source := carried_portal_energy if requires_portal_energy else carried_energy
	var available: float = source[deposit_affinity]
	var deposited: float = minf(available, max_amount)
	if deposited <= 0.0:
		return 0.0
	source[deposit_affinity] -= deposited
	if requires_portal_energy:
		carried_energy[deposit_affinity] = max(0.0, carried_energy[deposit_affinity] - deposited)
	else:
		carried_portal_energy[deposit_affinity] = max(0.0, carried_portal_energy[deposit_affinity] - deposited)
	_emit_carried_energy_changed()
	return deposited


func clear_carried_energy() -> void:
	for affinity_key in carried_energy.keys():
		carried_energy[affinity_key] = 0.0
		carried_portal_energy[affinity_key] = 0.0
	_emit_carried_energy_changed()


func set_respawn_position(new_position: Vector3) -> void:
	respawn_position = new_position


func teleport_to_respawn() -> void:
	global_position = respawn_position
	velocity = Vector3.ZERO
	dash_time = 0.0


func _emit_carried_energy_changed() -> void:
	carried_energy_changed.emit(
		carried_energy[AffinityManager.Affinity.WATER],
		carried_energy[AffinityManager.Affinity.EARTH],
		carried_energy[AffinityManager.Affinity.FIRE]
	)


func _primary_range() -> float:
	match active_affinity:
		AffinityManager.Affinity.WATER:
			return 4.0
		AffinityManager.Affinity.EARTH:
			return 2.3
		AffinityManager.Affinity.FIRE:
			return 7.0
	return 3.0


func _primary_radius() -> float:
	match active_affinity:
		AffinityManager.Affinity.WATER:
			return 1.0
		AffinityManager.Affinity.EARTH:
			return 1.45
		AffinityManager.Affinity.FIRE:
			return 1.75
	return 1.0


func _on_affinity_changed(new_affinity: int) -> void:
	active_affinity = new_affinity
	var material := StandardMaterial3D.new()
	material.albedo_color = AffinityManager.get_affinity_color(active_affinity)
	visual.set_surface_override_material(0, material)
	_update_affinity_visual_effects()
	if _has_initialized_affinity:
		AudioManager.play_swap(active_affinity, global_position)
	_has_initialized_affinity = true


func _update_affinity_visual_effects() -> void:
	for node in find_children("*", "", true, false):
		if node.has_method("set_affinity") and not node.is_in_group("energy_drops"):
			node.set_affinity(active_affinity)


func _update_aim_feedback() -> void:
	var feedback_state := AimFeedback.NONE
	var aimed_enemy := _get_aimed_enemy()
	if aimed_enemy != null:
		var multiplier := AffinityManager.get_damage_multiplier(active_affinity, aimed_enemy.affinity)
		if multiplier <= 0.0:
			feedback_state = AimFeedback.IMMUNE
		elif multiplier < 1.0:
			feedback_state = AimFeedback.RESISTANT
		else:
			feedback_state = AimFeedback.VULNERABLE
	if feedback_state == current_aim_feedback:
		return
	current_aim_feedback = feedback_state
	aim_feedback_changed.emit(current_aim_feedback)


func _get_aimed_enemy() -> Node:
	var origin := _camera.global_position
	var end := origin + (-_camera.global_basis.z * aim_check_distance)
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	var collider: Node = hit.get("collider")
	if collider != null and collider.is_in_group("enemies") and collider.get("affinity") != null:
		return collider
	return null
