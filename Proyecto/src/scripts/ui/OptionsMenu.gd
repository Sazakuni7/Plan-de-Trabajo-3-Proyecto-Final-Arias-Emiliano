extends PanelContainer

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider


func _ready() -> void:
	music_slider.value = AudioSettings.music_volume
	sfx_slider.value = AudioSettings.sfx_volume
	music_slider.value_changed.connect(_on_music_value_changed)
	sfx_slider.value_changed.connect(_on_sfx_value_changed)


func _on_music_value_changed(value: float) -> void:
	AudioSettings.set_music_volume(value)


func _on_sfx_value_changed(value: float) -> void:
	AudioSettings.set_sfx_volume(value)
