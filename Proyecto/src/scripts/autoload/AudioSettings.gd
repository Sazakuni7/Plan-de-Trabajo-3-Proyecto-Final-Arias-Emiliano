extends Node

signal volume_changed(bus_name: String, linear_value: float)

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const SETTINGS_PATH := "user://audio_settings.cfg"
const DEFAULT_MUSIC_VOLUME := 0.65
const DEFAULT_SFX_VOLUME := 0.75

var music_volume := DEFAULT_MUSIC_VOLUME
var sfx_volume := DEFAULT_SFX_VOLUME


func _ready() -> void:
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)
	_load_settings()
	_apply_volume(MUSIC_BUS, music_volume)
	_apply_volume(SFX_BUS, sfx_volume)


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_volume(MUSIC_BUS, music_volume)
	_save_settings()
	volume_changed.emit(MUSIC_BUS, music_volume)


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_volume(SFX_BUS, sfx_volume)
	_save_settings()
	volume_changed.emit(SFX_BUS, sfx_volume)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var bus_index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, "Master")


func _apply_volume(bus_name: String, linear_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	var clamped_value := clampf(linear_value, 0.0, 1.0)
	var db_value := linear_to_db(clamped_value) if clamped_value > 0.0 else -80.0
	AudioServer.set_bus_volume_db(bus_index, db_value)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	music_volume = float(config.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME))
	sfx_volume = float(config.get_value("audio", "sfx_volume", DEFAULT_SFX_VOLUME))


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.save(SETTINGS_PATH)
