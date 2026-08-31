@tool
extends Node3D

enum ProjectilePalette { WATER, EARTH, FIRE, CUSTOM }

@export var palette := ProjectilePalette.FIRE:
	set(value):
		palette = value
		_apply_palette()

@export var custom_primary_color := Color.WHITE:
	set(value):
		custom_primary_color = value
		_apply_palette()

@export var custom_secondary_color := Color(0.8, 0.8, 0.8):
	set(value):
		custom_secondary_color = value
		_apply_palette()

@export var custom_tertiary_color := Color(0.5, 0.5, 0.5):
	set(value):
		custom_tertiary_color = value
		_apply_palette()

@export var emission := 2.0:
	set(value):
		emission = value
		_apply_palette()

@onready var effect: Node3D = $VFXFireProjectile_01


func _ready() -> void:
	_make_effect_materials_unique()
	_apply_palette()
	_force_visible_projectile()


func set_affinity(affinity: int) -> void:
	match affinity:
		AffinityManager.Affinity.WATER:
			palette = ProjectilePalette.WATER
		AffinityManager.Affinity.EARTH:
			palette = ProjectilePalette.EARTH
		AffinityManager.Affinity.FIRE:
			palette = ProjectilePalette.FIRE
		_:
			palette = ProjectilePalette.FIRE


func _apply_palette() -> void:
	if not is_inside_tree() or effect == null:
		return
	var colors := _get_palette_colors()
	_set_effect_property("primary_color", colors[0])
	_set_effect_property("secondary_color", colors[1])
	_set_effect_property("tertiary_color", colors[2])
	_set_effect_property("light_color", colors[0])
	_set_effect_property("emission", emission)
	_apply_palette_to_child_materials(colors)
	_force_visible_projectile()


func _get_palette_colors() -> Array[Color]:
	match palette:
		ProjectilePalette.WATER:
			return [Color(0.45, 0.92, 1.0), Color(0.04, 0.42, 1.0), Color(0.02, 0.12, 0.8)]
		ProjectilePalette.EARTH:
			return [Color(0.56, 0.423, 0.011, 1.0), Color(0.674, 0.91, 0.237, 1.0), Color(0.48, 0.33, 0.18)]
		ProjectilePalette.FIRE:
			return [Color(1.0, 0.71, 0.3), Color(1.0, 0.4, 0.1), Color(0.51, 0.08, 0.04)]
		ProjectilePalette.CUSTOM:
			return [custom_primary_color, custom_secondary_color, custom_tertiary_color]
	return [Color.WHITE, Color(0.8, 0.8, 0.8), Color(0.5, 0.5, 0.5)]


func _set_effect_property(property_name: StringName, value: Variant) -> void:
	if effect == null:
		return
	effect.set(property_name, value)


func _make_effect_materials_unique() -> void:
	if effect == null:
		return
	for node in effect.find_children("*", "", true, false):
		if node is MeshInstance3D and node.material_override != null:
			node.material_override = node.material_override.duplicate(true)
		elif node is GPUParticles3D:
			if node.material_override != null:
				node.material_override = node.material_override.duplicate(true)
			if node.process_material != null:
				node.process_material = node.process_material.duplicate(true)


func _force_visible_projectile() -> void:
	if effect == null:
		return
	var animation_player := effect.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player != null:
		animation_player.stop()
	for node in effect.find_children("*", "", true, false):
		if node is MeshInstance3D:
			node.visible = true
			var material := node.material_override as ShaderMaterial
			if material != null:
				_set_shader_parameter_if_present(material, "grow_amount", 1.0)
				_set_shader_parameter_if_present(material, "emission", emission)
		elif node is GPUParticles3D:
			node.visible = true
			node.emitting = true
			node.restart()


func _apply_palette_to_child_materials(colors: Array[Color]) -> void:
	if effect == null:
		return
	for node in effect.find_children("*", "", true, false):
		if node is MeshInstance3D:
			_apply_palette_to_material(node.material_override as ShaderMaterial, colors)
		elif node is GPUParticles3D:
			_apply_palette_to_material(node.material_override as ShaderMaterial, colors)
			var particle_material := node.process_material as ParticleProcessMaterial
			if particle_material != null:
				particle_material.color = colors[0]
		elif node is OmniLight3D:
			node.light_color = colors[0]


func _apply_palette_to_material(material: ShaderMaterial, colors: Array[Color]) -> void:
	if material == null:
		return
	_set_shader_parameter_if_present(material, "primary_color", colors[0])
	_set_shader_parameter_if_present(material, "secondary_color", colors[1])
	_set_shader_parameter_if_present(material, "tertiary_color", colors[2])
	_set_shader_parameter_if_present(material, "emission", emission)


func _set_shader_parameter_if_present(material: ShaderMaterial, parameter_name: StringName, value: Variant) -> void:
	for property in material.get_property_list():
		if property.get("name") == "shader_parameter/%s" % parameter_name:
			material.set_shader_parameter(parameter_name, value)
			return
