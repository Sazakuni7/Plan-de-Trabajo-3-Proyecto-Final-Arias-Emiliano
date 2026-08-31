extends Node

signal score_changed(new_score: int)
signal timer_changed(level_time: float)

var score: int = 0
var level_time: float = 0.0
var timer_running := false


func _process(delta: float) -> void:
	if not timer_running:
		return
	level_time += delta
	timer_changed.emit(level_time)


func reset_score() -> void:
	score = 0
	level_time = 0.0
	timer_running = true
	score_changed.emit(score)
	timer_changed.emit(level_time)


func stop_timer() -> void:
	timer_running = false


func add_score(amount: int) -> void:
	if amount <= 0:
		return
	score += amount
	score_changed.emit(score)


func add_purification_score(is_empowered := false, is_weak := false) -> void:
	var amount := 100
	if is_empowered:
		amount = 160
	elif is_weak:
		amount = 60
	add_score(amount)


func add_absorb_score() -> void:
	add_score(25)


func add_speed_bonus() -> void:
	var bonus: int = maxi(0, 500 - int(level_time * 5.0))
	add_score(bonus)
