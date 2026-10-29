extends CharacterBody3D
class_name FishingLure

signal splashed(pos: Vector3)
signal reached_rod()
signal breached(pos: Vector3)

@export var gravity: float = 18.0
@export var water_level: float = 0.0
@export var float_depth: float = -0.15

var in_water: bool = false
var is_active: bool = false
var water_bob_time: float = 0.0
var current_water_type: String = "Saltwater Ocean"

# Fish fighting dynamics: lateral struggle & stamina
var is_breaching: bool = false
var breach_velocity_y: float = 0.0
var is_fighting_fish: bool = false
var fight_side_dir: Vector3 = Vector3.ZERO
var fish_stamina: float = 100.0 # Fish tires out as you fight!
var hook_initial_dist: float = 20.0

func launch(start_pos: Vector3, launch_velocity: Vector3) -> void:
	global_position = start_pos
	velocity = launch_velocity
	is_active = true
	in_water = false
	is_breaching = false
	is_fighting_fish = false
	visible = true

func reset_to_tip(tip_pos: Vector3) -> void:
	is_active = false
	in_water = false
	is_breaching = false
	is_fighting_fish = false
	velocity = Vector3.ZERO
	global_position = tip_pos
	visible = false

func start_fish_fight(player_pos: Vector3, fish_difficulty: int) -> void:
	is_fighting_fish = true
	fish_stamina = 70.0 + fish_difficulty * 15.0
	hook_initial_dist = Vector2(global_position.x - player_pos.x, global_position.z - player_pos.z).length()
	
	# Initial fight angle: mostly side-to-side thrash rather than running to infinity
	var away = (global_position - player_pos)
	away.y = 0.0
	away = away.normalized()
	fight_side_dir = Vector3(-away.z, 0.0, away.x)

func update_fish_fight_movement(player_pos: Vector3, delta: float) -> void:
	if not is_fighting_fish or not in_water:
		return
	
	# Fish stamina slowly drains as you fight
	fish_stamina = maxf(fish_stamina - 12.0 * delta, 0.0)
	var stamina_factor: float = fish_stamina / 100.0
	
	# Thrashing side-to-side across player's view cone (Sega Bass Fishing style)
	var away = (global_position - player_pos)
	away.y = 0.0
	var current_dist: float = away.length()
	away = away.normalized()
	var side = Vector3(-away.z, 0.0, away.x)
	
	# Lateral side sway
	var sway = side * sin(Time.get_ticks_msec() * 0.0035) * (3.0 * stamina_factor)
	
	# Tether limit: prevent fish from swimming beyond its hooked distance + 3m
	var max_leash: float = hook_initial_dist + 3.0
	var pull_away: float = 0.0
	if current_dist < max_leash:
		pull_away = (1.2 * stamina_factor) # Only slight outward push when energetic
	else:
		pull_away = -0.5 # Leash snaps fish back inward
	
	global_position += (sway + away * pull_away) * delta

func trigger_jump_breach() -> void:
	if in_water and not is_breaching:
		is_breaching = true
		breach_velocity_y = randf_range(4.0, 5.5)
		breached.emit(global_position)

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	
	if is_breaching:
		breach_velocity_y -= gravity * delta
		global_position.y += breach_velocity_y * delta
		if global_position.y <= water_level + float_depth:
			global_position.y = water_level + float_depth
			is_breaching = false
			splashed.emit(global_position)
		return

	if not in_water:
		velocity.y -= gravity * delta
		move_and_slide()
		
		var is_in_pond: bool = (global_position.x >= 7.0 and global_position.x <= 25.0 and global_position.z >= 13.0 and global_position.z <= 31.0)
		var target_water_y: float = 0.7 if is_in_pond else 0.0
		
		if global_position.y <= target_water_y:
			in_water = true
			water_level = target_water_y
			current_water_type = "Inland Freshwater Pond" if is_in_pond else "Saltwater Ocean"
			global_position.y = water_level + float_depth
			velocity.y = 0.0
			velocity.x *= 0.3
			velocity.z *= 0.3
			splashed.emit(global_position)
	else:
		water_bob_time += delta * 3.0
		var bobbing: float = sin(water_bob_time) * 0.04
		global_position.y = water_level + float_depth + bobbing
		
		velocity.x = move_toward(velocity.x, 0.0, 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 4.0 * delta)
		move_and_slide()

func reel_toward(target_pos: Vector3, speed: float, delta: float) -> void:
	if not is_active:
		return
	
	var dir: Vector3 = (target_pos - global_position).normalized()
	dir.y = 0.0
	dir = dir.normalized()
	
	# Player reel speed always clearly overcomes the fish (steady progress toward you!)
	var effective_speed: float = speed * 1.35
	global_position += dir * effective_speed * delta
	
	var flat_dist: float = Vector2(global_position.x - target_pos.x, global_position.z - target_pos.z).length()
	if flat_dist < 2.5:
		reached_rod.emit()
