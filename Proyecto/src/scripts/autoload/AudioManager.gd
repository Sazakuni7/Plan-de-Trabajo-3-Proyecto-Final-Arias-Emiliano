extends Node

@export_range(0.0, 0.12, 0.005) var pitch_variation := 0.1

var music_player: AudioStreamPlayer

var level_music := preload("res://src/SFX/levelmusic.mp3")
var dash_sfx := preload("res://src/SFX/dash.wav")
var click_sfx := preload("res://src/SFX/click.wav")
var blip_sfx := preload("res://src/SFX/blip.wav")
var hurt_sfx := preload("res://src/SFX/hurt.wav")
var portal_sfx := preload("res://src/SFX/portal.wav")
var pop_sfx := preload("res://src/SFX/pop.wav")

var cast_sfx := {
	AffinityManager.Affinity.WATER: preload("res://src/SFX/waterCast.wav"),
	AffinityManager.Affinity.EARTH: preload("res://src/SFX/earthCast.wav"),
	AffinityManager.Affinity.FIRE: preload("res://src/SFX/fireCast.wav"),
}

var secondary_cast_sfx := {
	AffinityManager.Affinity.WATER: preload("res://src/SFX/WaterCast2.wav"),
	AffinityManager.Affinity.EARTH: preload("res://src/SFX/EarthCast2.wav"),
	AffinityManager.Affinity.FIRE: preload("res://src/SFX/FireCast2.wav"),
}

var ultimate_cast_sfx := {
	AffinityManager.Affinity.WATER: preload("res://src/SFX/WaterUltimate.wav"),
	AffinityManager.Affinity.EARTH: preload("res://src/SFX/EarthUltimate.wav"),
	AffinityManager.Affinity.FIRE: preload("res://src/SFX/FireUltimate.wav"),
}

var hit_sfx := {
	AffinityManager.Affinity.WATER: preload("res://src/SFX/waterHit.wav"),
	AffinityManager.Affinity.EARTH: preload("res://src/SFX/earthHit.wav"),
	AffinityManager.Affinity.FIRE: preload("res://src/SFX/fireHit.wav"),
}

var swap_sfx := {
	AffinityManager.Affinity.WATER: preload("res://src/SFX/waterSwap.wav"),
	AffinityManager.Affinity.EARTH: preload("res://src/SFX/earthSwap.wav"),
	AffinityManager.Affinity.FIRE: preload("res://src/SFX/fireSwap.wav"),
}

var deposit_sfx := {
	AffinityManager.Affinity.WATER: preload("res://src/SFX/waterDeposit.wav"),
	AffinityManager.Affinity.EARTH: preload("res://src/SFX/earthDeposit.wav"),
	AffinityManager.Affinity.FIRE: preload("res://src/SFX/fireDeposit.wav"),
}


func _ready() -> void:
	randomize()
	music_player = AudioStreamPlayer.new()
	music_player.bus = AudioSettings.MUSIC_BUS
	music_player.stream = level_music
	add_child(music_player)


func play_level_music() -> void:
	if music_player.playing:
		return
	music_player.play()


func stop_level_music() -> void:
	music_player.stop()


func play_cast(affinity: int, position: Vector3) -> void:
	_play_3d(cast_sfx.get(affinity), position, true)


func play_secondary_cast(affinity: int, position: Vector3) -> void:
	_play_3d(secondary_cast_sfx.get(affinity), position, true)


func play_ultimate_cast(affinity: int, position: Vector3) -> void:
	_play_3d(ultimate_cast_sfx.get(affinity), position, false)


func play_hit(affinity: int, position: Vector3) -> void:
	_play_3d(hit_sfx.get(affinity), position, true)


func play_swap(affinity: int, position: Vector3) -> void:
	_play_3d(swap_sfx.get(affinity), position, false)


func play_dash(position: Vector3) -> void:
	_play_3d(dash_sfx, position, false)


func play_hurt(position: Vector3) -> void:
	_play_3d(hurt_sfx, position, false)


func play_blip(position: Vector3) -> void:
	_play_3d(blip_sfx, position, false)


func play_deposit(affinity: int, position: Vector3) -> void:
	_play_3d(deposit_sfx.get(affinity), position, false)


func play_portal(position: Vector3) -> void:
	_play_3d(portal_sfx, position, false)


func play_pop() -> void:
	_play_2d(pop_sfx, false)


func play_click() -> void:
	_play_2d(click_sfx, false)


func _play_2d(stream: AudioStream, vary_pitch: bool) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.bus = AudioSettings.SFX_BUS
	player.stream = stream
	player.pitch_scale = _random_pitch() if vary_pitch else 1.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _play_3d(stream: AudioStream, position: Vector3, vary_pitch: bool) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer3D.new()
	player.bus = AudioSettings.SFX_BUS
	player.stream = stream
	player.pitch_scale = _random_pitch() if vary_pitch else 1.0
	player.max_distance = 45.0
	add_child(player)
	player.global_position = position
	player.finished.connect(player.queue_free)
	player.play()


func _random_pitch() -> float:
	return randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
