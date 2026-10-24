class_name CombatTuning
extends Resource

@export_category("Movimiento")
@export var move_speed: float = 260.0
@export var acceleration: float = 2200.0
@export var deceleration: float = 2800.0
@export var dash_speed: float = 850.0
@export var dash_frames: int = 10
@export var dash_cooldown_frames: int = 48
@export_category("Arma")
@export var shot_cooldown_frames: int = 12
@export var projectile_speed: float = 900.0
@export var projectile_damage: int = 1
@export_category("Resonancia")
@export var parry_frames: int = 6
@export var parry_cooldown_frames: int = 36
@export var parry_radius: float = 72.0
@export var stun_frames: int = 90
@export var hope_reward: float = 18.0
@export_category("Frecuencia (postura)")
@export var frequency_max: float = 100.0
@export var frequency_per_shot: float = 12.0
@export var frequency_per_parry: float = 40.0
@export var frequency_decay_delay_frames: int = 180
@export var frequency_decay_per_second: float = 12.0
@export var frequency_break_frames: int = 180
@export var broken_damage_multiplier: int = 2
@export_category("Enemigo")
@export var enemy_health: int = 8
@export var dummy_health: int = 5
@export var enemy_speed: float = 100.0
@export var enemy_prepare_frames: int = 42
@export var enemy_telegraph_frames: int = 3
@export var enemy_recovery_frames: int = 60
@export var enemy_attack_range: float = 62.0
@export var enemy_repath_frames: int = 12
@export_category("Integridad")
@export var player_max_health: int = 3
@export var damage_invulnerability_frames: int = 48
@export var hope_drain_per_second: float = 2.0
