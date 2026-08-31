extends Node

const DEFAULT_PREWARM_COUNT := 18

var _available: Dictionary = {}


func prewarm(projectile_scene: PackedScene, count := DEFAULT_PREWARM_COUNT, parent: Node = null) -> void:
	if projectile_scene == null:
		return
	var owner := parent if parent != null else get_tree().current_scene
	if owner == null:
		return
	for i in range(count):
		var projectile := _create_projectile(projectile_scene, owner)
		recycle(projectile)


func spawn(projectile_scene: PackedScene, parent: Node, spawn_transform: Transform3D, direction: Vector3, affinity: int, damage: float, shooter: Node, speed_override := -1.0, vfx_scene: PackedScene = null, vfx_scale := Vector3.ONE, vfx_rotation_degrees := Vector3.ZERO, knockback_force := 0.0, vfx_light_energy_multiplier := 1.0, vfx_light_range := 8.0) -> Area3D:
	if projectile_scene == null or parent == null:
		return null
	var scene_key := projectile_scene.resource_path
	var projectile := _take_available_projectile(scene_key)
	if projectile == null:
		projectile = _create_projectile(projectile_scene, parent)
	elif projectile.get_parent() != parent:
		if projectile.get_parent() != null:
			projectile.get_parent().remove_child(projectile)
		parent.add_child(projectile)
	projectile.global_transform = spawn_transform
	projectile.launch(direction, affinity, damage, shooter, speed_override, vfx_scene, vfx_scale, vfx_rotation_degrees, knockback_force, vfx_light_energy_multiplier, vfx_light_range)
	return projectile


func recycle(projectile: Area3D) -> void:
	if projectile == null:
		return
	var scene_key: String = projectile.get_meta("projectile_scene_key", "")
	if scene_key.is_empty():
		projectile.queue_free()
		return
	if not _available.has(scene_key):
		_available[scene_key] = []
	projectile.deactivate()
	_available[scene_key].append(projectile)


func _create_projectile(projectile_scene: PackedScene, parent: Node) -> Area3D:
	var projectile := projectile_scene.instantiate() as Area3D
	projectile.set_meta("projectile_scene_key", projectile_scene.resource_path)
	parent.add_child(projectile)
	return projectile


func _take_available_projectile(scene_key: String) -> Area3D:
	if not _available.has(scene_key):
		return null
	var pool: Array = _available[scene_key]
	while not pool.is_empty():
		var projectile := pool.pop_back() as Area3D
		if is_instance_valid(projectile):
			return projectile
	return null
