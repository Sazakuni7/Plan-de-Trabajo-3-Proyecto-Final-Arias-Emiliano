extends Control

const TEST_LEVEL_SCENE := "res://src/scenes/main/TestLevel.tscn"

@onready var main_buttons: VBoxContainer = %MainButtons
@onready var options_wrapper: VBoxContainer = %OptionsWrapper
@onready var how_to_play_panel: PanelContainer = %HowToPlayPanel
@onready var controls_panel: PanelContainer = %ControlsPanel
@onready var joypad_panel: PanelContainer = %JoypadPanel
@onready var play_button: Button = %PlayButton
@onready var options_button: Button = %OptionsButton
@onready var how_to_play_button: Button = %HowToPlayButton
@onready var controls_button: Button = %ControlsButton
@onready var joypad_button: Button = %JoypadButton
@onready var exit_button: Button = %ExitButton
@onready var options_back_button: Button = %OptionsBackButton
@onready var how_to_play_back_button: Button = %HowToPlayBackButton
@onready var controls_back_button: Button = %ControlsBackButton
@onready var joypad_back_button: Button = %JoypadBackButton


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_show_options)
	how_to_play_button.pressed.connect(_show_how_to_play)
	controls_button.pressed.connect(_show_controls)
	joypad_button.pressed.connect(_show_joypad)
	exit_button.pressed.connect(_on_exit_pressed)
	options_back_button.pressed.connect(_show_main_buttons)
	how_to_play_back_button.pressed.connect(_show_main_buttons)
	controls_back_button.pressed.connect(_show_main_buttons)
	joypad_back_button.pressed.connect(_show_controls)
	_show_main_buttons(false)


func _on_play_pressed() -> void:
	AudioManager.play_click()
	get_tree().change_scene_to_file(TEST_LEVEL_SCENE)


func _show_options() -> void:
	AudioManager.play_click()
	main_buttons.visible = false
	options_wrapper.visible = true
	how_to_play_panel.visible = false
	controls_panel.visible = false
	joypad_panel.visible = false


func _show_how_to_play() -> void:
	AudioManager.play_click()
	main_buttons.visible = false
	options_wrapper.visible = false
	how_to_play_panel.visible = true
	controls_panel.visible = false
	joypad_panel.visible = false

func _show_controls() -> void:
	AudioManager.play_click()
	main_buttons.visible = false
	options_wrapper.visible = false
	controls_panel.visible = true
	joypad_panel.visible = false
	
func _show_joypad() -> void:
	AudioManager.play_click()
	main_buttons.visible = false
	options_wrapper.visible = false
	controls_panel.visible = false
	joypad_panel.visible = true

func _show_main_buttons(play_sound := true) -> void:
	if play_sound:
		AudioManager.play_click()
	main_buttons.visible = true
	options_wrapper.visible = false
	how_to_play_panel.visible = false
	controls_panel.visible = false
	joypad_panel.visible = false


func _on_exit_pressed() -> void:
	AudioManager.play_click()
	get_tree().quit()
