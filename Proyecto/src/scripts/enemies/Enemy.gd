extends CharacterBody3D

signal purified(affinity: int, energy_amount: float)

enum BehaviorMode { STATIONARY, PATROL, CHASE }

@export var affinity := AffinityManager.Affinity.WATER
@export var max_health := 70.0
@export var move_speed := 3.1
@export var attack_damage := 12.0
@export var attack_range := 1.7
@export var attack_cooldown := 1.1
@export var energy_amount := 25.0
@export var behavior_mode := BehaviorMode.CHASE
@export var patrol_offset := Vector3(4.0, 0.0, 0.0)
@export var patrol_arrival_distance := 0.35
@export var patrol_ledge_check_distance := 1.0
@export var energy_drop_scene: PackedScene
@export var energy_counts_for_portal_containers := false
@export_group("Ranged Attack")
@export var can_shoot := false
@export var use_contact_attack := true
@export var projectile_scene: PackedScene
@export var shoot_range := 12.0
@export var projectile_damage := 10.0
@export var aim_height_offset := 0.75
@export_group("Visual Feedback")
@export var tint_fallback_material := true
@export var immune_outline_color := Color(0.85, 0.95, 1.0, 1.0)
@export var immune_outline_thickness := 0.020
@export var normal_outline_color := Color(0.0, 0.0, 0.0, 1)
@export var normal_outline_thickness := 0.008
@export var damage_flash_duration := 0.16
@export var effective_flash_energy := 1.8
@export var resisted_flash_energy := 0.35

var health := 70.0
var target: Node3D = null
var cooldown_left := 0.0
var patrol_origin := Vector3.ZERO
var patrol_target_index := 0
var spawn_position := Vector3.ZERO
var visual_material: Material = null
var knockback_velocity := Vector3.ZERO
var damage_flash_left := 0.0

@onready var visual: MeshInstance3D = $Visual
@onready var energy_drop_spawn: Marker3D = $EnergyDropSpawn
@onready var energy_drop_preview: MeshInstance3D = $EnergyDropSpawn/EnergyDropPreview
@onready var projectile_muzzle: Marker3D = $ProjectileMuzzle
@onready var damage_flash_light: OmniLight3D = get_node_or_null("DamageFlashLight")


func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	energy_drop_preview.visible = false
	patrol_origin = global_position
	spawn_position = global_position
	target = get_tree().get_first_node_in_group("player")
	_ensure_damage_flash_light()
	_setup_visual_material()
	#AffinityManager.affinity_changed.connect(_on_player_affinity_changed)
	_apply_affinity_material()


func _process(delta: float) -> void:
	if damage_flash_left <= 0.0:
		return
	damage_flash_left = max(0.0, damage_flash_left - delta)
	if damage_flash_left <= 0.0:
		damage_flash_light.visible = false
		_apply_affinity_material()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player")
	cooldown_left = max(0.0, cooldown_left - delta)
	var move_direction := _get_behavior_move_direction()
	knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 18.0 * delta)
	var horizontal_velocity := move_direction * move_speed + knockback_velocity
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	_try_attack_if_in_range()
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	else:
		velocity.y = -0.1
	move_and_slide()
	if behavior_mode == BehaviorMode.PATROL and _should_reverse_patrol(move_direction):
		_reverse_patrol()


func take_damage(amount: float, source_affinity: int) -> void:
	var affinity_multiplier := AffinityManager.get_damage_multiplier(source_affinity, affinity)
	if affinity_multiplier <= 0.0:
		return
	health = max(0.0, health - amount * affinity_multiplier)
	_show_damage_flash(source_affinity, affinity_multiplier)
	AudioManager.play_hit(source_affinity, global_position)
	if health <= 0.0:
		_die()


func apply_knockback(knockback: Vector3) -> void:
	knockback.y = 0.0
	knockback_velocity = knockback


func _get_behavior_move_direction() -> Vector3:
	match behavior_mode:
		BehaviorMode.STATIONARY:
			return Vector3.ZERO
		BehaviorMode.PATROL:
			return _get_patrol_direction()
		BehaviorMode.CHASE:
			return _get_chase_direction()
	return Vector3.ZERO


func _get_chase_direction() -> Vector3:
	if not is_instance_valid(target):
		return Vector3.ZERO
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	if to_target.length() <= attack_range:
		return Vector3.ZERO
	return to_target.normalized()


func _get_patrol_direction() -> Vector3:
	var patrol_points := [patrol_origin - patrol_offset, patrol_origin + patrol_offset]
	var patrol_target: Vector3 = patrol_points[patrol_target_index]
	var to_patrol_target := patrol_target - global_position
	to_patrol_target.y = 0.0
	if to_patrol_target.length() <= patrol_arrival_distance:
		patrol_target_index = 1 - patrol_target_index
		return Vector3.ZERO
	return to_patrol_target.normalized()


func _should_reverse_patrol(move_direction: Vector3) -> bool:
	if move_direction.length_squared() <= 0.01:
		return false
	if is_on_wall():
		return true
	if not is_on_floor():
		return false
	var from := global_position + Vector3.UP * 0.25 + move_direction.normalized() * patrol_ledge_check_distance
	var to := from + Vector3.DOWN * 2.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _reverse_patrol() -> void:
	patrol_target_index = 1 - patrol_target_index
	velocity.x = 0.0
	velocity.z = 0.0


func _try_attack_if_in_range() -> void:
	if cooldown_left > 0.0:
		return
	if not is_instance_valid(target):
		return

	var to_target := target.global_position - global_position
	to_target.y = 0.0
	if can_shoot and projectile_scene != null and to_target.length() <= shoot_range:
		cooldown_left = attack_cooldown
		_shoot_projectile()
		return

	if not use_contact_attack:
		return
	if target.has_method("take_damage") and to_target.length() <= attack_range:
		cooldown_left = attack_cooldown
		target.take_damage(attack_damage, affinity)


func _shoot_projectile() -> void:
	var target_position := target.global_position + Vector3.UP * aim_height_offset
	var direction := target_position - projectile_muzzle.global_position
	ProjectilePool.spawn(projectile_scene, get_tree().current_scene, projectile_muzzle.global_transform, direction, affinity, projectile_damage, self)
	AudioManager.play_cast(affinity, projectile_muzzle.global_position)


func _die() -> void:
	_drop_energy()
	purified.emit(affinity, energy_amount)
	queue_free()


func _drop_energy() -> void:
	if energy_drop_scene == null:
		return
	var drop := energy_drop_scene.instantiate()
	drop.affinity = affinity
	drop.energy_amount = energy_amount
	drop.counts_for_portal_containers = energy_counts_for_portal_containers
	get_tree().current_scene.add_child(drop)
	drop.global_position = energy_drop_spawn.global_position


func teleport_to_spawn() -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO


func set_spawn_position(new_spawn_position: Vector3) -> void:
	global_position = new_spawn_position
	patrol_origin = new_spawn_position
	spawn_position = new_spawn_position
	patrol_target_index = 0
	velocity = Vector3.ZERO


func _apply_affinity_material() -> void:
	var color := AffinityManager.get_affinity_color(affinity)
	var is_immune := affinity == AffinityManager.active_affinity
	if visual_material is ShaderMaterial:
		_apply_shader_feedback(visual_material, color, is_immune)
	elif visual_material is StandardMaterial3D:
		_apply_standard_material_feedback(visual_material, color, is_immune)


func _setup_visual_material() -> void:
	var source_material := visual.get_surface_override_material(0)
	if source_material == null and visual.mesh != null:
		source_material = visual.mesh.surface_get_material(0)
	if source_material != null:
		visual_material = source_material.duplicate()
	elif tint_fallback_material:
		visual_material = StandardMaterial3D.new()
	if visual_material != null:
		visual.set_surface_override_material(0, visual_material)


func _apply_shader_feedback(material: ShaderMaterial, color: Color, is_immune: bool) -> void:
	_set_shader_parameter_if_present(material, "element_color", color)
	_set_shader_parameter_if_present(material, "albedo_color", color)
	_set_shader_parameter_if_present(material, "tint_color", color)
	#_set_shader_parameter_if_present(material, "rim_color", color.lightened(0.35) if is_immune else Color.TRANSPARENT)
	#_set_shader_parameter_if_present(material, "rim_strength", 0.75 if is_immune else 0.0)
	_set_shader_parameter_if_present(material, "outline_enabled", true)
	_set_shader_parameter_if_present(material, "outline_color", immune_outline_color if is_immune else normal_outline_color)
	_set_shader_parameter_if_present(material, "outline_thickness", immune_outline_thickness if is_immune else normal_outline_thickness)


func _apply_standard_material_feedback(material: StandardMaterial3D, color: Color, is_immune: bool) -> void:
	var uses_texture := material.albedo_texture != null
	if material.albedo_texture == null:
		material.albedo_color = color.darkened(0.18)
	else:
		material.albedo_color = Color.WHITE
	material.emission_enabled = is_immune and not uses_texture
	if is_immune and not uses_texture:
		material.emission = color
		material.emission_energy_multiplier = 0.55
	else:
		material.emission = Color.BLACK
		material.emission_energy_multiplier = 0.0


func _show_damage_flash(source_affinity: int, affinity_multiplier: float) -> void:
	_ensure_damage_flash_light()
	var source_color := AffinityManager.get_affinity_color(source_affinity)
	var energy := effective_flash_energy if affinity_multiplier >= 1.0 else resisted_flash_energy
	damage_flash_left = damage_flash_duration
	damage_flash_light.light_color = source_color
	damage_flash_light.light_energy = energy
	damage_flash_light.visible = true
	if visual_material is ShaderMaterial:
		_set_shader_parameter_if_present(visual_material, "emission", energy)
		_set_shader_parameter_if_present(visual_material, "emission_color", source_color)
	elif visual_material is StandardMaterial3D:
		var standard_material := visual_material as StandardMaterial3D
		standard_material.emission_enabled = true
		standard_material.emission = source_color
		standard_material.emission_energy_multiplier = energy


func _ensure_damage_flash_light() -> void:
	if damage_flash_light != null:
		return
	damage_flash_light = OmniLight3D.new()
	damage_flash_light.name = "DamageFlashLight"
	damage_flash_light.visible = false
	damage_flash_light.position = Vector3(0.0, 0.9, 0.0)
	damage_flash_light.omni_range = 3.0
	damage_flash_light.light_energy = 0.0
	add_child(damage_flash_light)


func _set_shader_parameter_if_present(material: ShaderMaterial, parameter_name: StringName, value: Variant) -> void:
	if _shader_has_parameter(material, parameter_name):
		material.set_shader_parameter(parameter_name, value)


func _shader_has_parameter(material: ShaderMaterial, parameter_name: StringName) -> bool:
	for property in material.get_property_list():
		if property.get("name") == "shader_parameter/%s" % parameter_name:
			return true
	return false


#func _on_player_affinity_changed(_new_affinity: int) -> void:
	#_apply_affinity_material()
