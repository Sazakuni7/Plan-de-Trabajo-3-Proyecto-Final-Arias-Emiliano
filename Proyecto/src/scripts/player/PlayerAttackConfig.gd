class_name PlayerAttackConfig
extends Resource

enum AttackMode { PROJECTILE, MULTI_PROJECTILE, FOLLOW_AREA, ORBIT_PROJECTILE }
enum CastSound { PRIMARY, SECONDARY, ULTIMATE }

@export var attack_mode := AttackMode.PROJECTILE
@export var cast_sound := CastSound.PRIMARY
@export var damage := 30.0
@export var knockback_force := 0.0
@export var cooldown := 0.35
@export var vfx_scene: PackedScene
@export var vfx_scale := Vector3.ONE
@export var vfx_rotation_degrees := Vector3.ZERO
@export var vfx_light_energy_multiplier := 1.0
@export var vfx_light_range := 8.0
@export var projectile_speed := 22.0
@export_range(1, 15, 1) var projectile_count := 1
@export_range(0.0, 360.0, 1.0) var spread_arc_degrees := 16.0
@export var duration := 3.0
@export var radius := 2.5
@export var tick_interval := 0.35
@export var orbit_radius := 1.4
@export var orbit_speed := 4.0
