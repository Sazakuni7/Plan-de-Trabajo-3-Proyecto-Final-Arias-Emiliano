extends Node

signal affinity_changed(new_affinity: int)

enum Affinity { WATER, EARTH, FIRE }

const AFFINITY_NAMES := {
	Affinity.WATER: "Agua",
	Affinity.EARTH: "Tierra",
	Affinity.FIRE: "Fuego/Luz",
}

const AFFINITY_COLORS := {
	Affinity.WATER: Color(0.18, 0.55, 1.0),
	Affinity.EARTH: Color(0.42, 0.72, 0.32),
	Affinity.FIRE: Color(1.0, 0.42, 0.08),
}

const RESISTED_DAMAGE_MULTIPLIER := 0.1

var active_affinity: int = Affinity.WATER


func set_affinity(new_affinity: int) -> void:
	if not AFFINITY_NAMES.has(new_affinity):
		return
	if active_affinity == new_affinity:
		return
	active_affinity = new_affinity
	affinity_changed.emit(active_affinity)


func get_affinity_name(affinity: int) -> String:
	return AFFINITY_NAMES.get(affinity, "Unknown")


func get_affinity_color(affinity: int) -> Color:
	return AFFINITY_COLORS.get(affinity, Color.WHITE)


func get_damage_multiplier(attack_affinity: int, defense_affinity: int) -> float:
	if attack_affinity == defense_affinity:
		return 0.0
	if does_affinity_beat(attack_affinity, defense_affinity):
		return 1.0
	return RESISTED_DAMAGE_MULTIPLIER


func does_affinity_beat(attack_affinity: int, defense_affinity: int) -> bool:
	return (
		attack_affinity == Affinity.WATER and defense_affinity == Affinity.FIRE
	) or (
		attack_affinity == Affinity.FIRE and defense_affinity == Affinity.EARTH
	) or (
		attack_affinity == Affinity.EARTH and defense_affinity == Affinity.WATER
	)
