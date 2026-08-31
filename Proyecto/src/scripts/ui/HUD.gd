extends CanvasLayer

@onready var health_bar: ProgressBar = %HealthBar
@onready var energy_bar: ProgressBar = %EnergyBar
@onready var affinity_label: Label = %AffinityLabel
@onready var score_label: Label = %ScoreLabel
@onready var timer_label: Label = %TimerLabel
@onready var water_bar: ProgressBar = %WaterBar
@onready var earth_bar: ProgressBar = %EarthBar
@onready var fire_bar: ProgressBar = %FireBar
@onready var carried_water_label: Label = %CarriedWaterLabel
@onready var carried_earth_label: Label = %CarriedEarthLabel
@onready var carried_fire_label: Label = %CarriedFireLabel
@onready var message_label: Label = %MessageLabel
@onready var crosshair: Control = %Crosshair
@onready var crosshair_icon_label: Label = %CrosshairIconLabel


func _ready() -> void:
	AffinityManager.affinity_changed.connect(_on_affinity_changed)
	ScoreManager.score_changed.connect(_on_score_changed)
	ScoreManager.timer_changed.connect(_on_timer_changed)
	GameManager.containers_changed.connect(_refresh_containers)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.game_state_changed.connect(_on_game_state_changed)
	_on_affinity_changed(AffinityManager.active_affinity)
	_on_score_changed(ScoreManager.score)
	_on_timer_changed(ScoreManager.level_time)
	_refresh_containers()


func bind_player(player: Node) -> void:
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_health_changed)
	if player.has_signal("energy_changed"):
		player.energy_changed.connect(_on_energy_changed)
	if player.has_signal("carried_energy_changed"):
		player.carried_energy_changed.connect(_on_carried_energy_changed)
	if player.has_signal("aim_feedback_changed"):
		player.aim_feedback_changed.connect(_on_aim_feedback_changed)
	if player.has_signal("found_hud_toggled"):
		player.found_hud_toggled.connect(_on_found_hud_toggled)
	_on_health_changed(player.health, player.max_health)
	_on_energy_changed(player.energy, player.max_energy)
	_on_carried_energy_changed(
		player.carried_energy[AffinityManager.Affinity.WATER],
		player.carried_energy[AffinityManager.Affinity.EARTH],
		player.carried_energy[AffinityManager.Affinity.FIRE]
	)
	_on_aim_feedback_changed(0)


func _on_found_hud_toggled(_is_visible: bool) -> void:
	pass


func _on_health_changed(current_health: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health


func _on_energy_changed(current_energy: float, max_energy: float) -> void:
	energy_bar.max_value = max_energy
	energy_bar.value = current_energy


func _on_affinity_changed(new_affinity: int) -> void:
	affinity_label.text = "Afinidad: %s" % AffinityManager.get_affinity_name(new_affinity)


func _on_score_changed(new_score: int) -> void:
	score_label.text = "Puntaje: %d" % new_score


func _on_timer_changed(level_time: float) -> void:
	var total_seconds := int(level_time)
	var minutes := floori(total_seconds / 60.0)
	var seconds := total_seconds % 60
	timer_label.text = "Tiempo: %02d:%02d" % [minutes, seconds]


func _refresh_containers() -> void:
	for container in GameManager.containers:
		var percent: float = container.get_fill_percent() * 100.0
		match container.affinity:
			AffinityManager.Affinity.WATER:
				water_bar.value = percent
			AffinityManager.Affinity.EARTH:
				earth_bar.value = percent
			AffinityManager.Affinity.FIRE:
				fire_bar.value = percent


func _on_carried_energy_changed(water: float, earth: float, fire: float) -> void:
	carried_water_label.text = "Loot Agua: %d" % int(water)
	carried_earth_label.text = "Loot Tierra: %d" % int(earth)
	carried_fire_label.text = "Loot Fuego/Luz: %d" % int(fire)


func _on_level_completed() -> void:
	message_label.text = "Nivel completado!"
	message_label.visible = true


func _on_game_state_changed(new_state: int) -> void:
	if new_state == GameManager.GameState.LOST:
		message_label.text = "Derrota"
		message_label.visible = true


func _on_aim_feedback_changed(feedback_state: int) -> void:
	match feedback_state:
		0:
			crosshair.modulate = Color.WHITE
			crosshair.scale = Vector2.ONE
			crosshair_icon_label.text = ""
		1:
			crosshair.modulate = Color(0.2, 1.0, 0.35)
			crosshair.scale = Vector2(2.12, 2.12)
			crosshair_icon_label.text = ""
		2:
			crosshair.modulate = Color(1.0, 0.18, 0.12)
			crosshair.scale = Vector2(1.08, 1.08)
			crosshair_icon_label.text = "!"
		3:
			crosshair.modulate = Color(0.45, 0.45, 0.45)
			crosshair.scale = Vector2(0.92, 0.92)
			crosshair_icon_label.text = "X"
