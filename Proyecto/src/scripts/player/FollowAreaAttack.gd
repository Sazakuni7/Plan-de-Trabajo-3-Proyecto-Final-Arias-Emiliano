extends Area3D

var damage := 20.0
var affinity := AffinityManager.Affinity.WATER
var duration := 3.0
var tick_interval := 0.35
var owner_body: Node3D = null

var _elapsed := 0.0
var _tick_left := 0.0


func setup(attack_config: PlayerAttackConfig, attack_affinity: int, source: Node3D) -> void:
	damage = attack_config.damage
	affinity = attack_affinity
	duration = attack_config.duration
	tick_interval = attack_config.tick_interval
	owner_body = source
	var collision_shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = attack_config.radius
	collision_shape.shape = sphere
	add_child(collision_shape)
	if attack_config.vfx_scene != null:
		var vfx := attack_config.vfx_scene.instantiate() as Node3D
		if vfx != null:
			add_child(vfx)
			vfx.scale = attack_config.vfx_scale
			vfx.rotation_degrees = attack_config.vfx_rotation_degrees
			_apply_light_settings(vfx, attack_config.vfx_light_energy_multiplier, attack_config.vfx_light_range)
			if vfx.has_method("set_affinity"):
				vfx.set_affinity(affinity)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(owner_body):
		queue_free()
		return
	global_position = owner_body.global_position
	_elapsed += delta
	_tick_left -= delta
	if _tick_left <= 0.0:
		_tick_left = tick_interval
		_damage_overlapping_bodies()
	if _elapsed >= duration:
		queue_free()


func _damage_overlapping_bodies() -> void:
	for body in get_overlapping_bodies():
		if body != owner_body and body.has_method("take_damage"):
			body.take_damage(damage, affinity)


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
