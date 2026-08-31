# Projectile.gd
extends Area3D

@export var speed := 22.0
@export var lifetime := 2.5
@export var damage := 20.0
@export var knockback_force := 0.0
@export var affinity := AffinityManager.Affinity.WATER

var _velocity := Vector3.ZERO
var _time_alive := 0.0
var _shooter: Node = null
var _is_active := false
var _active_vfx: Node3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_affinity_material()

func launch(direction: Vector3, shooter_affinity: int, dmg: float, shooter: Node, speed_override := -1.0, vfx_scene: PackedScene = null, vfx_scale := Vector3.ONE, vfx_rotation_degrees := Vector3.ZERO, attack_knockback := 0.0, vfx_light_energy_multiplier := 1.0, vfx_light_range := 8.0) -> void:
	var launch_direction := direction.normalized()
	_is_active = true
	_time_alive = 0.0
	var travel_speed := speed_override if speed_override > 0.0 else speed
	_velocity = launch_direction * travel_speed
	affinity = shooter_affinity
	damage = dmg
	knockback_force = attack_knockback
	_shooter = shooter
	visible = true
	monitoring = true
	monitorable = true
	process_mode = Node.PROCESS_MODE_INHERIT
	_set_collision_disabled(false)
	if launch_direction.length_squared() > 0.0:
		look_at(global_position + launch_direction, Vector3.UP)
	_set_vfx_scene(vfx_scene, vfx_scale, vfx_rotation_degrees, vfx_light_energy_multiplier, vfx_light_range)
	_apply_affinity_material()

func _physics_process(delta: float) -> void:
	if not _is_active:
		return
	_time_alive += delta
	if _time_alive >= lifetime:
		_finish()
		return
	global_position += _velocity * delta

func _on_body_entered(body: Node) -> void:
	if not _is_active:
		return
	if body == _shooter:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, affinity)
	if knockback_force > 0.0 and body.has_method("apply_knockback"):
		body.apply_knockback(_velocity.normalized() * knockback_force)
	_finish()

func deactivate() -> void:
	_is_active = false
	_velocity = Vector3.ZERO
	_time_alive = 0.0
	_shooter = null
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_disabled(true)

func _finish() -> void:
	if not _is_active:
		return
	_is_active = false
	_velocity = Vector3.ZERO
	call_deferred("_recycle_after_physics")


func _recycle_after_physics() -> void:
	ProjectilePool.recycle(self)


func _set_collision_disabled(is_disabled: bool) -> void:
	for child in get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", is_disabled)

func _apply_affinity_material() -> void:
	for child in get_children():
		if child.has_method("set_affinity"):
			child.set_affinity(affinity)

	var mesh := get_node_or_null("Projectile3D/Projectile") as MeshInstance3D
	if mesh == null:
		return
	var material := mesh.material_override as ShaderMaterial
	if material == null:
		return

	material = material.duplicate()
	mesh.material_override = material

	var head_color: Color
	var tail_color: Color

	match affinity:
		AffinityManager.Affinity.WATER:
			head_color = Color(0.55, 0.9, 1.0)
			tail_color = Color(0.05, 0.35, 1.0)
		AffinityManager.Affinity.EARTH:
			head_color = Color(0.749, 0.816, 0.173, 1.0)
			tail_color = Color(0.25, 0.55, 0.16)
		AffinityManager.Affinity.FIRE:
			head_color = Color(1.0, 0.86, 0.25)
			tail_color = Color(1.0, 0.25, 0.02)

	material.set_shader_parameter("head_color", head_color)
	material.set_shader_parameter("tail_color", tail_color)


func _set_vfx_scene(vfx_scene: PackedScene, vfx_scale: Vector3, vfx_rotation_degrees: Vector3, vfx_light_energy_multiplier: float, vfx_light_range: float) -> void:
	if _active_vfx != null and is_instance_valid(_active_vfx):
		_active_vfx.queue_free()
		_active_vfx = null
	if vfx_scene == null:
		var fallback_vfx := get_node_or_null("ElementalProjectileVFX") as Node3D
		if fallback_vfx != null:
			fallback_vfx.visible = true
			fallback_vfx.scale = vfx_scale
			fallback_vfx.rotation_degrees = vfx_rotation_degrees
			_apply_light_settings(fallback_vfx, vfx_light_energy_multiplier, vfx_light_range)
		return
	var fallback := get_node_or_null("ElementalProjectileVFX") as Node3D
	if fallback != null:
		fallback.visible = false
	_active_vfx = vfx_scene.instantiate() as Node3D
	if _active_vfx == null:
		return
	add_child(_active_vfx)
	_active_vfx.position = Vector3.ZERO
	_active_vfx.rotation_degrees = vfx_rotation_degrees
	_active_vfx.scale = vfx_scale
	_apply_light_settings(_active_vfx, vfx_light_energy_multiplier, vfx_light_range)
	if _active_vfx.has_method("set_affinity"):
		_active_vfx.set_affinity(affinity)
	var animation_player := _active_vfx.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player != null and animation_player.has_animation("main"):
		animation_player.play("main")


func _apply_light_settings(root: Node, energy_multiplier: float, light_range: float) -> void:
	_apply_light_settings_recursive(root, energy_multiplier, light_range)


func _apply_light_settings_recursive(node: Node, energy_multiplier: float, light_range: float) -> void:
	if node is Light3D:
		var light := node as Light3D
		light.light_energy *= energy_multiplier
		if light is OmniLight3D:
			(light as OmniLight3D).omni_range = light_range
	for child in node.get_children():
		_apply_light_settings_recursive(child, energy_multiplier, light_range)
