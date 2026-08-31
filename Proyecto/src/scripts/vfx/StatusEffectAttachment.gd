@tool
extends Node3D

enum StatusPalette { WATER, EARTH, FIRE, NEUTRAL, CUSTOM }

@export var palette := StatusPalette.NEUTRAL:
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

@export var emission := 6.0:
	set(value):
		emission = value
		_apply_palette()

@export var emitting := true:
	set(value):
		emitting = value
		_set_effect_emitting(emitting)

@onready var effect: Node3D = $VFXStatusShatter


func _ready() -> void:
	_make_effect_materials_unique()
	_apply_palette()
	_set_effect_emitting(emitting)


func set_affinity(affinity: int) -> void:
	match affinity:
		AffinityManager.Affinity.WATER:
			palette = StatusPalette.WATER
		AffinityManager.Affinity.EARTH:
			palette = StatusPalette.EARTH
		AffinityManager.Affinity.FIRE:
			palette = StatusPalette.FIRE
		_:
			palette = StatusPalette.NEUTRAL


func set_active(is_active: bool) -> void:
	emitting = is_active


func _apply_palette() -> void:
	if not is_inside_tree() or effect == null:
		return
	var colors := _get_palette_colors()
	_set_effect_property("primary_color", colors[0])
	_set_effect_property("secondary_color", colors[1])
	_set_effect_property("tertiary_color", colors[2])
	_set_effect_property("emission", emission)
	_apply_palette_to_child_materials(colors)


func _get_palette_colors() -> Array[Color]:
	match palette:
		StatusPalette.WATER:
			return [Color(0.01, 0.901, 1.0, 1.0), Color(0.21, 0.21, 1.0, 1.0), Color(0.222, 0.405, 0.962, 1.0)]
		StatusPalette.EARTH:
			return [Color(0.635, 0.7, 0.049, 1.0), Color(0.493, 0.96, 0.259, 1.0), Color(0.473, 0.97, 0.349, 1.0)]
		StatusPalette.FIRE:
			return [Color(1.0, 0.26, 0.08), Color(1.0, 0.48, 0.22, 1.0), Color(0.71, 0.051, 0.028, 1.0)]
		StatusPalette.CUSTOM:
			return [custom_primary_color, custom_secondary_color, custom_tertiary_color]
	return [Color.WHITE, Color(0.8, 0.8, 0.8), Color(0.5, 0.5, 0.5)]


func _set_effect_emitting(is_emitting: bool) -> void:
	if not is_inside_tree() or effect == null:
		return
	_set_effect_property("emitting", is_emitting)
	for child in effect.get_children():
		if child is GPUParticles3D:
			child.emitting = is_emitting


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
