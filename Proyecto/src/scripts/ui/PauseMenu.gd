extends CanvasLayer

signal resume_requested
signal main_menu_requested

@onready var root: Control = %Root
@onready var pause_buttons: VBoxContainer = %PauseButtons
@onready var options_wrapper: VBoxContainer = %OptionsWrapper
@onready var resume_button: Button = %ResumeButton
@onready var options_button: Button = %OptionsButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var options_back_button: Button = %OptionsBackButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(func() -> void:
		AudioManager.play_click()
		resume_requested.emit()
	)
	options_button.pressed.connect(_show_options)
	main_menu_button.pressed.connect(func() -> void:
		AudioManager.play_click()
		main_menu_requested.emit()
	)
	options_back_button.pressed.connect(_show_pause_buttons)
	hide_menu()


func show_menu() -> void:
	root.visible = true
	_show_pause_buttons()


func hide_menu() -> void:
	root.visible = false


func _show_options() -> void:
	AudioManager.play_click()
	pause_buttons.visible = false
	options_wrapper.visible = true


func _show_pause_buttons() -> void:
	AudioManager.play_click()
	pause_buttons.visible = true
	options_wrapper.visible = false
