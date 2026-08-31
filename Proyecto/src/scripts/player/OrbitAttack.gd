extends Node3D

var damage := 20.0
var affinity := AffinityManager.Affinity.WATER
var duration := 3.0
var orbit_radius := 1.4
var orbit_speed := 4.0
var owner_body: Node3D = null
var _elapsed := 0.0


func setup(attack_config: PlayerAttackConfig, attack_affinity: int, source: Node3D) -> void:
	damage = attack_config.damage
	affinity = attack_affinity
	duration = attack_config.duration
	orbit_radius = attack_config.orbit_radius
	orbit_speed = attack_config.orbit_speed
	owner_body = source
	var count: int = max(1, attack_config.projectile_count)
	for index in range(count):
		var orb := Area3D.new()
		orb.name = "OrbitProjectile%d" % (index + 1)
		orb.body_entered.connect(_on_orb_body_entered.bind(orb))
		add_child(orb)
		var collision_shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = max(0.25, attack_config.radius * 0.25)
		collision_shape.shape = sphere
		orb.add_child(collision_shape)
		if attack_config.vfx_scene != null:
			var vfx := attack_config.vfx_scene.instantiate() as Node3D
			if vfx != null:
				orb.add_child(vfx)
				vfx.scale = attack_config.vfx_scale
				vfx.rotation_degrees = attack_config.vfx_rotation_degrees
				_apply_light_settings(vfx, attack_config.vfx_light_energy_multiplier, attack_config.vfx_light_range)
				if vfx.has_method("set_affinity"):
					vfx.set_affinity(affinity)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(owner_body):
		queue_free()
		return
	global_position = owner_body.global_position + Vector3.UP * 1.0
	_elapsed += delta
	var children := get_children()
	for index in range(children.size()):
		var orb := children[index] as Area3D
		if orb == null:
			continue
		var angle := _elapsed * orbit_speed + TAU * float(index) / float(max(1, children.size()))
		orb.position = Vector3(cos(angle) * orbit_radius, 0.0, sin(angle) * orbit_radius)
	if _elapsed >= duration:
		queue_free()


func _on_orb_body_entered(body: Node, orb: Area3D) -> void:
	if body == owner_body:
		return
	if body.has_method("take_damage"):
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
