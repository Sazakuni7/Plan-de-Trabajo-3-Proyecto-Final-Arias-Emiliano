extends StaticBody3D

signal fill_changed(affinity: int, fill_percent: float)

@export var affinity := AffinityManager.Affinity.WATER
@export var max_energy := 100.0
@export var deposit_per_touch := 999.0
@export var counts_for_portal := true
@export_group("Fill Visual")
@export var fill_bottom_y := 0.1
@export var fill_full_height := 1.8
@export var fill_min_visible_scale := 0.001

var current_energy := 0.0

@onready var visual: MeshInstance3D = $Visual
@onready var fill_visual: MeshInstance3D = $FillVisual
@onready var label: Label3D = $Label3D
@onready var deposit_area: Area3D = $DepositArea


func _ready() -> void:
	if counts_for_portal:
		GameManager.register_container(self)
	deposit_area.body_entered.connect(_on_deposit_area_body_entered)
	_apply_materials()
	_update_visuals()


func _exit_tree() -> void:
	if counts_for_portal and GameManager != null:
		GameManager.unregister_container(self)


func _physics_process(_delta: float) -> void:
	if is_full():
		return
	for body in deposit_area.get_overlapping_bodies():
		_try_deposit_from(body)


func add_energy(amount: float) -> void:
	if is_full():
		return
	current_energy = clamp(current_energy + amount, 0.0, max_energy)
	_update_visuals()
	fill_changed.emit(affinity, get_fill_percent())


func _on_deposit_area_body_entered(body: Node) -> void:
	_try_deposit_from(body)


func _try_deposit_from(body: Node) -> void:
	if is_full():
		return
	if not body.has_method("deposit_energy"):
		return
	var needed := max_energy - current_energy
	var deposited: float = body.deposit_energy(affinity, minf(deposit_per_touch, needed), counts_for_portal)
	if deposited > 0.0:
		add_energy(deposited)
		AudioManager.play_deposit(affinity, global_position)


func is_full() -> bool:
	return current_energy >= max_energy


func get_fill_percent() -> float:
	if max_energy <= 0.0:
		return 1.0
	return current_energy / max_energy


func _apply_materials() -> void:
	var shell_material := StandardMaterial3D.new()
	shell_material.albedo_color = Color(0.12, 0.12, 0.12, 0.35)
	shell_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	visual.set_surface_override_material(0, shell_material)
	var fill_material := StandardMaterial3D.new()
	fill_material.albedo_color = AffinityManager.get_affinity_color(affinity)
	fill_visual.set_surface_override_material(0, fill_material)


func _update_visuals() -> void:
	var percent: float = get_fill_percent()
	fill_visual.visible = percent > 0.0
	fill_visual.scale.y = max(fill_min_visible_scale, percent)
	fill_visual.position.y = fill_bottom_y + (fill_full_height * percent * 0.5)
	label.text = "%s\n%d%%" % [AffinityManager.get_affinity_name(affinity), int(percent * 100.0)]
