extends CharacterBody3D
class_name FishingPlayer

enum State {
	IDLE,
	CHARGING_CAST,
	LURE_FLYING,
	FISHING,
	BITING,
	FIGHTING,
	CAUGHT,
	REELING,
	BACKLASH,
	FLY_FALSE_CASTING,
	SNAGGED
}

@export var mouse_sensitivity: float = 0.002
@export var move_speed: float = 4.0

# Current Fishing Discipline & Bait
var current_discipline: FishingTypes.Discipline = FishingTypes.Discipline.SPINNING
var current_state: State = State.IDLE
var current_bait: String = "Worms"
var banner_text: String = ""
var banner_time: float = 0.0
var _bait_index: int = 0
var _hud_panel: TextureRect
var _hud_fill: ColorRect
var _slot_buttons: Array[Button] = []
var _splash_nodes: Array[Sprite3D] = []

const SPLASH_SHEET := "res://assets/vfx/splash_sheet.png"
const HUD_SHEET := "res://assets/ui/hud_fishing.png"
const TACKLE_SHEET := "res://assets/ui/tackle_box.png"
const SLOT_ORIGIN := Vector2(88, 88)
const SLOT_SIZE := 72.0
const SLOT_GAP := 16.0
const HUD_BAR_ORIGIN := Vector2(70, 18)
const HUD_BAR_SIZE := Vector2(240, 12)
const EXPECTED_SFX: PackedStringArray = [
	"res://audio/sfx/whip.ogg",
	"res://audio/sfx/sfx_fish_bite_1.ogg",
	"res://audio/sfx/reel1.ogg",
	"res://audio/sfx/thrash.ogg",
	"res://audio/sfx/fighting_loop.ogg",
	"res://audio/sfx/flapping.ogg",
]

# Fish fight & bite variables
var bite_timer: float = 0.0
var bite_reaction_timer: float = 0.0
var current_fish: Dictionary = {}
var line_tension: float = 0.0
var fish_run_timer: float = 0.0
var next_breach_timer: float = 0.0

# Cast parameters
var cast_power: float = 0.0
var max_cast_power: float = 35.0
var charge_speed: float = 28.0
var is_charging: bool = false

# Baitcaster thumb brake mechanic
var spool_rpm: float = 0.0
var thumb_braking: bool = false
var backlash_severity: float = 0.0

# Fly fishing rhythm mechanic
var fly_whip_forward: bool = true
var fly_line_out: float = 8.0 # meters of line out
var fly_cast_timer: float = 0.0

# Tackle Box & Day/Night Cycle
var tackle_box_open: bool = false
var flashlight_on: bool = false
var time_of_day: float = 0.35 # 0.0 = midnight, 0.25 = sunrise, 0.5 = noon, 0.75 = sunset
var day_cycle_speed: float = 0.006 # cycle speed

# Economy & Stats
var player_money: float = 25.0
var total_fish_caught: int = 0

# Audio reel crank cooldown
var reel_sound_timer: float = 0.0

# Node References
@onready var camera: Camera3D = $Camera3D
@onready var rod_pivot: Node3D = $Camera3D/RodPivot
@onready var rod_tip: Marker3D = $Camera3D/RodPivot/RodMesh/RodTip
@onready var cork_handle: Node3D = $Camera3D/RodPivot/RodMesh/CorkHandle
@onready var trophy_holder: Node3D = $Camera3D.get_node_or_null("TrophyHolder")
@onready var flashlight: SpotLight3D = $Camera3D.get_node_or_null("Flashlight")
@onready var lure: FishingLure = $"../Lure"
@onready var hud: CanvasLayer = $"../HUD"
@onready var sun_light: DirectionalLight3D = $"../DirectionalLight3D"
@onready var world_env: WorldEnvironment = $"../WorldEnvironment"

# Audio Players
var sfx_cast: AudioStreamPlayer
var sfx_bite: AudioStreamPlayer
var sfx_splash: AudioStreamPlayer
var sfx_reel: AudioStreamPlayer
var sfx_fight: AudioStreamPlayer
var sfx_flap: AudioStreamPlayer

var pitch: float = 0.0
var retro_shader_enabled: bool = true
var _water_mat: ShaderMaterial
var _rain_foam_set: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_init_audio_system()
	_create_rod_reel_mesh()

	if lure:
		lure.splashed.connect(_on_lure_splashed)
		lure.breached.connect(_on_lure_breached)
		lure.reached_rod.connect(_on_lure_reached_rod)
		lure.reset_to_tip(rod_tip.global_position)
	
	_setup_tackle_box_ui()
	_wire_hud_sheet()
	_style_catch_card()
	_ensure_buoy_placeholder.call_deferred()
	_build_angler_blockout()
	_style_rod_blockout()
	_ensure_journal_stub()
	update_hud()

func _init_audio_system() -> void:
	sfx_cast = AudioStreamPlayer.new()
	sfx_bite = AudioStreamPlayer.new()
	sfx_splash = AudioStreamPlayer.new()
	sfx_reel = AudioStreamPlayer.new()
	sfx_fight = AudioStreamPlayer.new()
	sfx_flap = AudioStreamPlayer.new()
	var players: Array[AudioStreamPlayer] = [sfx_cast, sfx_bite, sfx_splash, sfx_reel, sfx_fight, sfx_flap]
	for player in players:
		player.bus = "SFX"
		add_child(player)

	var streams := {
		sfx_cast: "res://audio/sfx/whip.ogg",
		sfx_bite: "res://audio/sfx/sfx_fish_bite_1.ogg",
		sfx_reel: "res://audio/sfx/reel1.ogg",
		sfx_splash: "res://audio/sfx/thrash.ogg",
		sfx_fight: "res://audio/sfx/fighting_loop.ogg",
		sfx_flap: "res://audio/sfx/flapping.ogg",
	}
	var missing: PackedStringArray = []
	for player in streams:
		var path: String = streams[player]
		if ResourceLoader.exists(path):
			player.stream = load(path)
		else:
			missing.append(path)
	if not missing.is_empty():
		push_warning("Hopeless Catch SFX missing (left silent for Audio Lead): %s" % ", ".join(missing))

func _create_rod_reel_mesh() -> void:
	if not cork_handle or cork_handle.get_node_or_null("ReelPivot"):
		return
	
	var reel_pivot = Node3D.new()
	reel_pivot.name = "ReelPivot"
	reel_pivot.position = Vector3(0.0, 0.15, -0.05)
	
	var reel_body = MeshInstance3D.new()
	reel_body.name = "ReelBody"
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.055
	cyl.bottom_radius = 0.055
	cyl.height = 0.075
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.22, 0.25)
	mat.metallic = 0.85
	mat.roughness = 0.25
	reel_body.mesh = cyl
	reel_body.rotation_degrees = Vector3(0, 0, 90)
	reel_pivot.add_child(reel_body)

	var crank_arm = Node3D.new()
	crank_arm.name = "CrankArm"
	crank_arm.position = Vector3(0.045, 0.0, 0.0)
	
	var handle_knob = MeshInstance3D.new()
	var knob_mesh = SphereMesh.new()
	knob_mesh.radius = 0.02
	knob_mesh.height = 0.04
	handle_knob.mesh = knob_mesh
	handle_knob.position = Vector3(0.0, 0.055, 0.0)
	crank_arm.add_child(handle_knob)
	
	reel_pivot.add_child(crank_arm)
	cork_handle.add_child(reel_pivot)
	_tint_reel_for_discipline()

func _setup_tackle_box_ui() -> void:
	if not hud:
		return
	var panel := hud.get_node_or_null("TackleBoxUI") as Panel
	var container: HBoxContainer = hud.get_node_or_null("TackleBoxUI/BaitContainer")
	if not panel:
		return
	_slot_buttons.clear()
	if container:
		for child in container.get_children():
			child.queue_free()
		container.visible = false

	var sheet: Texture2D = null
	if ResourceLoader.exists(TACKLE_SHEET):
		sheet = load(TACKLE_SHEET)
		panel.offset_left = -240
		panel.offset_right = 240
		panel.offset_top = -160
		panel.offset_bottom = 160
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		var bg := TextureRect.new()
		bg.name = "TackleSheet"
		bg.texture = sheet
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		panel.add_child(bg)
		panel.move_child(bg, 0)
		for label_name in ["Title", "CloseHelp"]:
			var old := panel.get_node_or_null(label_name)
			if old:
				old.visible = false

	for i in TackleBox.available_baits.size():
		var bait: TackleBox.BaitData = TackleBox.available_baits[i]
		var btn := Button.new()
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		btn.expand_icon = true
		if sheet:
			btn.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
			btn.offset_left = SLOT_ORIGIN.x + i * (SLOT_SIZE + SLOT_GAP)
			btn.offset_top = SLOT_ORIGIN.y
			btn.offset_right = btn.offset_left + SLOT_SIZE
			btn.offset_bottom = btn.offset_top + SLOT_SIZE
			panel.add_child(btn)
		elif container:
			btn.custom_minimum_size = Vector2(85, 95)
			btn.text = bait.name
			container.visible = true
			container.add_child(btn)
		if ResourceLoader.exists(bait.icon_path):
			btn.icon = load(bait.icon_path)
		btn.pressed.connect(_on_bait_selected.bind(bait.name))
		_slot_buttons.append(btn)

func _on_bait_selected(bait_name: String) -> void:
	var chosen := TackleBox.get_bait_by_id(bait_name)
	if chosen.id == "rotten_meat" and not _is_after_dark():
		_flash("Rotten offal unlocks after dark.")
		return
	for i in TackleBox.available_baits.size():
		if TackleBox.available_baits[i].name == bait_name:
			_bait_index = i
			break
	current_bait = bait_name
	var desc_lbl: Label = hud.get_node_or_null("TackleBoxUI/BaitDesc")
	var b_info = TackleBox.get_bait_by_id(bait_name)
	if desc_lbl:
		desc_lbl.text = "Selected: %s | Attracts: %s\n%s" % [b_info.name, b_info.target_species, b_info.description]
	update_hud()

func toggle_tackle_box() -> void:
	tackle_box_open = !tackle_box_open
	var box_ui: Panel = hud.get_node_or_null("TackleBoxUI")
	if box_ui:
		box_ui.visible = tackle_box_open
	
	if tackle_box_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var desc_lbl: Label = hud.get_node_or_null("TackleBoxUI/BaitDesc")
		var b_info = TackleBox.get_bait_by_id(current_bait)
		if desc_lbl:
			desc_lbl.text = "Active Bait: %s | Target Species: %s\n%s" % [b_info.name, b_info.target_species, b_info.description]
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func toggle_flashlight() -> void:
	flashlight_on = !flashlight_on
	if flashlight:
		flashlight.visible = flashlight_on

func _input(event: InputEvent) -> void:
	if tackle_box_open:
		if event is InputEventKey and event.pressed:
			if event.keycode in [KEY_B, KEY_TAB, KEY_ESCAPE]:
				toggle_tackle_box()
				get_viewport().set_input_as_handled()
			elif event.keycode in [KEY_LEFT, KEY_A]:
				_cycle_bait(-1)
			elif event.keycode in [KEY_RIGHT, KEY_D]:
				_cycle_bait(1)
			elif event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
				_confirm_bait_index()
		elif event is InputEventJoypadButton and event.pressed:
			if event.button_index == JOY_BUTTON_Y:
				toggle_tackle_box()
			elif event.button_index == JOY_BUTTON_DPAD_LEFT:
				_cycle_bait(-1)
			elif event.button_index == JOY_BUTTON_DPAD_RIGHT:
				_cycle_bait(1)
			elif event.button_index == JOY_BUTTON_A:
				_confirm_bait_index()
		return

	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		pitch = clampf(pitch - event.relative.y * mouse_sensitivity, -deg_to_rad(75), deg_to_rad(75))
		camera.rotation.x = pitch

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Controls: 1-4 disciplines, B/Tab tacklebox, F flashlight, P retro shader
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: set_discipline(FishingTypes.Discipline.SPINNING)
			KEY_2: set_discipline(FishingTypes.Discipline.BAITCASTING)
			KEY_3: set_discipline(FishingTypes.Discipline.SPINCAST)
			KEY_4: set_discipline(FishingTypes.Discipline.FLY_FISHING)
			KEY_B, KEY_TAB:
				if current_state == State.IDLE or current_state == State.FISHING:
					toggle_tackle_box()
			KEY_F: toggle_flashlight()
			KEY_J: _toggle_journal()
			KEY_P: toggle_retro_shader()
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y:
		if current_state == State.IDLE or current_state == State.FISHING:
			toggle_tackle_box()

func toggle_retro_shader() -> void:
	retro_shader_enabled = !retro_shader_enabled
	var post_proc: CanvasItem = hud.get_node_or_null("RetroPostProcess")
	if post_proc:
		post_proc.visible = retro_shader_enabled

func set_discipline(new_discipline: FishingTypes.Discipline) -> void:
	if current_state != State.IDLE:
		return
	current_discipline = new_discipline
	fly_line_out = 8.0
	_tint_reel_for_discipline()
	update_hud()

func _physics_process(delta: float) -> void:
	if banner_time > 0.0:
		banner_time = maxf(banner_time - delta, 0.0)
	_advance_splashes(delta)
	_handle_day_night_cycle(delta)
	_handle_movement(delta)
	_handle_fishing_logic(delta)
	_update_rod_animation(delta)
	_update_dangling_fish_physics(delta)
	update_hud()

func _handle_day_night_cycle(delta: float) -> void:
	time_of_day = fmod(time_of_day + day_cycle_speed * delta, 1.0)
	
	if sun_light:
		# Rotate sun around X-axis
		var sun_angle: float = (time_of_day - 0.25) * TAU
		sun_light.rotation.x = -sin(sun_angle)
		sun_light.rotation.y = cos(sun_angle) * 0.5
		
		# Day vs Sunset vs Night color and energy
		if time_of_day > 0.2 and time_of_day < 0.7:
			# Daytime
			sun_light.light_energy = 1.15
			sun_light.light_color = Color(1.0, 0.96, 0.88, 1.0)
		elif (time_of_day >= 0.7 and time_of_day < 0.8) or (time_of_day >= 0.15 and time_of_day <= 0.2):
			# Golden Hour / Sunset / Dawn
			sun_light.light_energy = 0.85
			sun_light.light_color = Color(1.0, 0.55, 0.28, 1.0)
		else:
			# Night
			sun_light.light_energy = 0.08
			sun_light.light_color = Color(0.2, 0.3, 0.5, 1.0)
	_apply_lake_water_tint()

func _handle_movement(delta: float) -> void:
	if global_position.y < -1.0:
		global_position = Vector3(0.0, 1.9, -8.0)
		velocity = Vector3.ZERO

	if not is_on_floor():
		velocity.y -= 9.8 * delta
	
	# Allow walking while IDLE, waiting for bite, reeling empty lure, fighting fish, and holding trophy
	var can_walk: bool = current_state in [State.IDLE, State.FISHING, State.REELING, State.FIGHTING, State.CAUGHT, State.SNAGGED] and not tackle_box_open
	if can_walk:
		var speed_mult: float = 1.0
		if current_state == State.FIGHTING:
			speed_mult = 0.65 # Slower, deliberate footwork while fighting heavy fish
		elif current_state == State.REELING:
			speed_mult = 0.8
		var current_speed: float = move_speed * speed_mult
		var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction != Vector3.ZERO:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
	
	move_and_slide()

func _handle_fishing_logic(delta: float) -> void:
	if tackle_box_open:
		return

	# Audio reel cranking loop
	if Input.is_action_pressed("reel_in") and (current_state in [State.REELING, State.FIGHTING, State.SNAGGED]):
		reel_sound_timer -= delta
		if reel_sound_timer <= 0.0:
			reel_sound_timer = 0.14
			if sfx_reel:
				sfx_reel.pitch_scale = randf_range(0.9, 1.2)
				sfx_reel.play()
		_animate_reel_crank(delta * 22.0)

	match current_state:
		State.IDLE:
			if Input.is_action_just_pressed("cast_line"):
				if current_discipline == FishingTypes.Discipline.FLY_FISHING:
					current_state = State.FLY_FALSE_CASTING
					fly_cast_timer = 0.0
					fly_whip_forward = true
					if sfx_cast: sfx_cast.play()
				else:
					current_state = State.CHARGING_CAST
					cast_power = 8.0
		
		State.CHARGING_CAST:
			cast_power += charge_speed * delta
			if cast_power > max_cast_power:
				cast_power = max_cast_power
			
			if Input.is_action_just_released("cast_line"):
				_execute_cast()
		
		State.FLY_FALSE_CASTING:
			fly_cast_timer += delta
			if fly_cast_timer > 0.65:
				fly_cast_timer = 0.0
				fly_whip_forward = !fly_whip_forward
				fly_line_out = minf(fly_line_out + 2.5, 30.0)
				if sfx_cast:
					sfx_cast.pitch_scale = randf_range(0.95, 1.15)
					sfx_cast.play()
			
			if Input.is_action_just_released("cast_line"):
				if fly_whip_forward:
					_execute_fly_presentation()
				else:
					current_state = State.IDLE
		
		State.LURE_FLYING:
			if current_discipline == FishingTypes.Discipline.BAITCASTING:
				thumb_braking = Input.is_action_pressed("thumb_brake")
				if thumb_braking:
					lure.velocity.x *= (1.0 - 2.5 * delta)
					lure.velocity.z *= (1.0 - 2.5 * delta)
					spool_rpm = move_toward(spool_rpm, 0.0, 800.0 * delta)
				else:
					spool_rpm += 120.0 * delta
			if lure and lure.consume_cast_failed():
				current_state = State.IDLE
				lure.reset_to_tip(rod_tip.global_position)
				_flash("The cast never found water.")
			elif lure and lure.snagged:
				current_state = State.SNAGGED
				_flash("Snagged. Hold reel to bring it back.")
		
		State.FISHING:
			bite_timer -= delta
			if bite_timer <= 0.0:
				current_state = State.BITING
				bite_reaction_timer = 1.55
				if sfx_bite: sfx_bite.play()
				if lure:
					lure.play_bite_dip()
			
			if Input.is_action_pressed("reel_in"):
				current_state = State.REELING
		
		State.BITING:
			bite_reaction_timer -= delta
			if Input.is_action_just_pressed("cast_line"):
				current_fish = FishDatabase.roll_random_fish(current_bait)
				current_state = State.FIGHTING
				line_tension = 30.0
				next_breach_timer = randf_range(3.0, 6.0)
				if sfx_fight: sfx_fight.play()
				if lure:
					lure.start_fish_fight(global_position, current_fish.get("difficulty", 2))
				_attach_fish_to_hook(current_fish.get("model_path", ""))
			elif bite_reaction_timer <= 0.0:
				_flash("Too late. It left the bait.")
				current_state = State.FISHING
				var b_info = TackleBox.get_bait_by_id(current_bait)
				bite_timer = randf_range(3.0, 6.0) / b_info.bite_speed_multiplier

		State.FIGHTING:
			var fish_diff: int = current_fish.get("difficulty", 2)
			fish_run_timer += delta
			var stamina_factor := 1.0
			if lure:
				stamina_factor = clampf(lure.fish_stamina / 100.0, 0.0, 1.0)
				lure.update_fish_fight_movement(global_position, delta)
			var fish_pull: float = ((8.0 + fish_diff * 3.2) + sin(fish_run_timer * 3.5) * 6.0) * lerpf(0.35, 1.0, stamina_factor)

			# Jump breach mechanic (Sega Bass Fishing style)
			next_breach_timer -= delta
			if next_breach_timer <= 0.0 and lure:
				next_breach_timer = randf_range(5.0, 9.0)
				lure.trigger_jump_breach()

			if Input.is_action_pressed("reel_in"):
				line_tension += fish_pull * delta
				var reel_spd: float = lerpf(8.5, 3.8, stamina_factor)
				lure.reel_toward(global_position, reel_spd, delta)
			else:
				line_tension = maxf(line_tension - lerpf(52.0, 34.0, stamina_factor) * delta, 8.0)
			
			if line_tension >= 100.0:
				_flash("Line snapped. The fish is gone.")
				current_state = State.IDLE
				current_fish = {}
				_detach_fish_from_hook()
				lure.reset_to_tip(rod_tip.global_position)
				if sfx_fight and sfx_fight.playing: sfx_fight.stop()

		State.SNAGGED:
			if Input.is_action_pressed("reel_in") and lure:
				lure.reel_toward(global_position, 8.0, delta)

		State.CAUGHT:
			# Choice: Keep (Left-Click or Spacebar) vs Release (Right-Click)
			if Input.is_action_just_pressed("cast_line") or Input.is_action_just_pressed("thumb_brake"):
				# Keep fish: add cash reward based on weight
				var reward: float = current_fish.get("weight", 1.0) * 2.5
				player_money += reward
				total_fish_caught += 1
				_finish_catch()
			elif Input.is_action_just_pressed("reel_in"):
				# Release fish: moral bonus
				_finish_catch()

		State.REELING:
			if Input.is_action_pressed("reel_in"):
				var reel_speed: float = 6.0
				if current_discipline == FishingTypes.Discipline.FLY_FISHING:
					reel_speed = 4.5
				lure.reel_toward(global_position, reel_speed, delta)
			else:
				current_state = State.FISHING
		
		State.BACKLASH:
			if Input.is_action_just_pressed("thumb_brake"):
				backlash_severity -= 0.35
				if backlash_severity <= 0.0:
					backlash_severity = 0.0
					current_state = State.IDLE
					lure.reset_to_tip(rod_tip.global_position)

func _finish_catch() -> void:
	current_state = State.IDLE
	current_fish = {}
	_detach_fish_from_hook()
	lure.reset_to_tip(rod_tip.global_position)
	if sfx_fight and sfx_fight.playing: sfx_fight.stop()
	if sfx_flap and sfx_flap.playing: sfx_flap.stop()

func _execute_cast() -> void:
	current_state = State.LURE_FLYING
	spool_rpm = 1000.0
	thumb_braking = false
	if sfx_cast: sfx_cast.play()
	
	var forward: Vector3 = -camera.global_transform.basis.z
	var launch_dir: Vector3 = (forward + Vector3.UP * 0.45).normalized()
	var launch_velocity: Vector3 = launch_dir * cast_power
	lure.launch(rod_tip.global_position, launch_velocity)

func _execute_fly_presentation() -> void:
	current_state = State.LURE_FLYING
	if sfx_cast: sfx_cast.play()
	var forward: Vector3 = -camera.global_transform.basis.z
	var launch_dir: Vector3 = (forward + Vector3.UP * 0.15).normalized()
	var launch_velocity: Vector3 = launch_dir * (fly_line_out * 1.3)
	lure.launch(rod_tip.global_position, launch_velocity)

func _on_lure_splashed(splash_pos: Vector3) -> void:
	_spawn_splash(splash_pos)
	if sfx_splash:
		sfx_splash.pitch_scale = randf_range(0.9, 1.2)
		sfx_splash.play()

	if current_state == State.LURE_FLYING:
		if current_discipline == FishingTypes.Discipline.BAITCASTING and not thumb_braking and spool_rpm > 450.0:
			current_state = State.BACKLASH
			backlash_severity = 1.0
			return
		
		current_state = State.FISHING
		var b_info = TackleBox.get_bait_by_id(current_bait)
		bite_timer = randf_range(2.0, 4.5) / b_info.bite_speed_multiplier

func _on_lure_breached(_pos: Vector3) -> void:
	if sfx_splash:
		sfx_splash.pitch_scale = 1.4
		sfx_splash.play()

func _on_lure_reached_rod() -> void:
	if current_state == State.FIGHTING:
		current_state = State.CAUGHT
		if sfx_flap: sfx_flap.play()
		# Pose 3D trophy fish directly in front of camera / hands
		_spawn_trophy_3d_pose(current_fish.get("model_path", ""))
	else:
		current_state = State.IDLE
		lure.reset_to_tip(rod_tip.global_position)

func _spawn_trophy_3d_pose(model_path: String) -> void:
	if not trophy_holder:
		return
	for child in trophy_holder.get_children():
		child.queue_free()
	
	if model_path != "" and ResourceLoader.exists(model_path):
		var fish_scene = load(model_path)
		if fish_scene:
			var inst = fish_scene.instantiate()
			inst.name = "TrophyPoseFish"
			# Scale and position prominently in front of player
			inst.scale = Vector3(0.65, 0.65, 0.65)
			inst.position = Vector3(0.0, 0.0, 0.0)
			inst.rotation_degrees = Vector3(10.0, -35.0, 5.0)
			trophy_holder.add_child(inst)

func _attach_fish_to_hook(model_path: String) -> void:
	_detach_fish_from_hook()
	if model_path != "" and ResourceLoader.exists(model_path):
		var fish_scene = load(model_path)
		if fish_scene and lure:
			var inst = fish_scene.instantiate()
			inst.name = "HookedFish"
			# Position fish hanging mouth-first from the lure
			inst.position = Vector3(0.0, -0.4, 0.0)
			inst.scale = Vector3(0.45, 0.45, 0.45)
			lure.add_child(inst)

func _detach_fish_from_hook() -> void:
	if lure:
		var hooked = lure.get_node_or_null("HookedFish")
		if hooked:
			hooked.queue_free()
	if trophy_holder:
		for child in trophy_holder.get_children():
			child.queue_free()

func _update_dangling_fish_physics(delta: float) -> void:
	if lure:
		var hooked = lure.get_node_or_null("HookedFish")
		if hooked and is_instance_valid(hooked):
			var thrash_speed: float = 16.0 if current_state == State.CAUGHT else 8.0
			var wriggle: float = sin(Time.get_ticks_msec() * 0.001 * thrash_speed) * 0.35
			hooked.rotation.z = wriggle
			hooked.rotation.y = sin(Time.get_ticks_msec() * 0.002) * 0.5
	
	if trophy_holder:
		if current_state == State.CAUGHT:
			trophy_holder.visible = true
			# Interactive catch pose sway with gentle swimming tail flaps
			var pose_fish = trophy_holder.get_node_or_null("TrophyPoseFish")
			if pose_fish and is_instance_valid(pose_fish):
				pose_fish.rotation.y = deg_to_rad(-35.0) + sin(Time.get_ticks_msec() * 0.003) * 0.25
				pose_fish.rotation.z = deg_to_rad(5.0) + sin(Time.get_ticks_msec() * 0.006) * 0.12
		else:
			trophy_holder.visible = false

func _animate_reel_crank(rot_delta: float) -> void:
	if cork_handle:
		var crank = cork_handle.get_node_or_null("ReelPivot/CrankArm")
		if crank:
			crank.rotate_x(rot_delta)

func _update_rod_animation(delta: float) -> void:
	var target_rot: Vector3 = Vector3.ZERO
	
	match current_state:
		State.CHARGING_CAST:
			var pull_factor: float = cast_power / max_cast_power
			target_rot = Vector3(deg_to_rad(35.0 * pull_factor), deg_to_rad(-15.0), 0.0)
		State.FLY_FALSE_CASTING:
			if fly_whip_forward:
				target_rot = Vector3(deg_to_rad(-25.0), deg_to_rad(5.0), 0.0)
			else:
				target_rot = Vector3(deg_to_rad(40.0), deg_to_rad(-20.0), 0.0)
		State.BITING:
			target_rot = Vector3(deg_to_rad(-16.0), deg_to_rad(sin(Time.get_ticks_msec() * 0.04) * 3.0), 0.0)
		State.FIGHTING:
			var shake: float = sin(Time.get_ticks_msec() * 0.035) * 4.0
			target_rot = Vector3(deg_to_rad(-14.0), deg_to_rad(shake), deg_to_rad(shake * 0.4))
		State.CAUGHT:
			# Rod held high with fish dangling right in view
			target_rot = Vector3(deg_to_rad(28.0), deg_to_rad(-12.0), 0.0)
		State.REELING:
			target_rot = Vector3(deg_to_rad(-8.0), deg_to_rad(5.0), deg_to_rad(sin(Time.get_ticks_msec() * 0.015) * 2.0))
		State.BACKLASH:
			target_rot = Vector3(deg_to_rad(-20.0), 0.0, 0.0)
		_:
			var bob: float = sin(Time.get_ticks_msec() * 0.002) * 0.02
			target_rot = Vector3(bob, 0.0, 0.0)
	
	rod_pivot.rotation.x = lerp_angle(rod_pivot.rotation.x, target_rot.x, 14.0 * delta)
	rod_pivot.rotation.y = lerp_angle(rod_pivot.rotation.y, target_rot.y, 14.0 * delta)
	rod_pivot.rotation.z = lerp_angle(rod_pivot.rotation.z, target_rot.z, 14.0 * delta)

func update_hud() -> void:
	if not hud:
		return
	var label_discipline: Label = hud.get_node_or_null("DisciplineLabel")
	var label_status: Label = hud.get_node_or_null("StatusLabel")
	var power_bar: ProgressBar = hud.get_node_or_null("CastPowerBar")
	var warning_label: Label = hud.get_node_or_null("WarningLabel")
	
	if label_discipline:
		var time_str: String = "Day" if (time_of_day > 0.2 and time_of_day < 0.7) else ("Sunset" if time_of_day < 0.8 and time_of_day >= 0.7 else "Night")
		label_discipline.text = "[$%.2f] | Setup: [%s] (1-4) | Bait: [%s] (B) | [%s] (F: Flashlight) | [P] PS1: %s" % [
			player_money,
			FishingTypes.get_discipline_name(current_discipline),
			current_bait,
			time_str,
			"ON" if retro_shader_enabled else "OFF"
		]
	
	if power_bar:
		if current_state == State.CHARGING_CAST:
			power_bar.visible = true
			power_bar.value = (cast_power / max_cast_power) * 100.0
		else:
			power_bar.visible = false
			
	if label_status:
		match current_state:
			State.IDLE:
				label_status.text = "Left-Click: Cast | WASD: Move | B: Tackle Box | F: Flashlight"
			State.CHARGING_CAST:
				label_status.text = "Charging Power... Release to Cast!"
			State.FLY_FALSE_CASTING:
				label_status.text = "False Casting! Line out: %.1fm | Release on FORWARD whip!" % fly_line_out
			State.LURE_FLYING:
				if current_discipline == FishingTypes.Discipline.BAITCASTING:
					label_status.text = "Lure flying! HOLD SPACE TO THUMB BRAKE!"
				else:
					label_status.text = "Lure in the air..."
			State.FISHING:
				label_status.text = "Bait: %s | Resting in [%s]. Hold Right-Click to Reel." % [current_bait, lure.current_water_type if lure else "Water"]
			State.BITING:
				label_status.text = "⚡ FISH BITE! CLICK LEFT-MOUSE TO SET THE HOOK!"
			State.FIGHTING:
				var stamina := lure.fish_stamina if lure else 0.0
				label_status.text = "FIGHTING %s. Tension %d%%. Fish stamina %.0f. Reel, then let go when it climbs." % [current_fish.get("name", "Fish"), int(line_tension), stamina]
			State.SNAGGED:
				label_status.text = "The lure is on shore. Hold right-click or the right trigger to retrieve it."
			State.CAUGHT:
				var val: float = current_fish.get("weight", 1.0) * 2.5
				label_status.text = "CAUGHT %s! Left-Click: KEEP (+$%.2f) | Right-Click: RELEASE" % [current_fish.get("name", "Fish").to_upper(), val]
			State.REELING:
				label_status.text = "Reeling in..."
			State.BACKLASH:
				label_status.text = "BIRD'S-NEST / BACKLASH! TAP SPACEBAR RAPIDLY TO UNTANGLE!"
				
	if warning_label:
		if banner_time > 0.0:
			warning_label.visible = true
			warning_label.text = banner_text
		elif current_state == State.BACKLASH:
			warning_label.visible = true
			warning_label.text = "⚠️ SPOOL BACKLASH! Untangle: %d%%" % int(backlash_severity * 100.0)
		elif current_state == State.BITING:
			warning_label.visible = true
			warning_label.text = "⚡ STRIKE! CLICK LEFT-MOUSE NOW!"
		elif current_state == State.FIGHTING and line_tension > 75.0:
			warning_label.visible = true
			warning_label.text = "⚠️ HIGH LINE TENSION! RELEASE REEL TO AVOID SNAP!"
		elif current_state == State.LURE_FLYING and current_discipline == FishingTypes.Discipline.BAITCASTING and not thumb_braking:
			warning_label.visible = true
			warning_label.text = "⚠️ THUMB BRAKE (SPACEBAR) OR YOU WILL BIRDS-NEST!"
		else:
			warning_label.visible = false

	var meter := 0.0
	var show_meter := false
	if current_state == State.FIGHTING:
		meter = line_tension / 100.0
		show_meter = true
	elif current_state == State.CHARGING_CAST:
		meter = cast_power / max_cast_power
		show_meter = true
	_update_hud_fill(meter, show_meter, current_state == State.FIGHTING)

	var tension_bar: ProgressBar = hud.get_node_or_null("TensionBar")
	if tension_bar:
		if _hud_panel:
			tension_bar.visible = false
		elif current_state == State.FIGHTING:
			tension_bar.visible = true
			tension_bar.value = line_tension
		else:
			tension_bar.visible = false

	var power_bar_art: ProgressBar = hud.get_node_or_null("CastPowerBar")
	if power_bar_art and _hud_panel and current_state == State.CHARGING_CAST:
		power_bar_art.visible = false

	_refresh_slot_locks()

	var catch_card: Control = hud.get_node_or_null("CatchCard")
	if catch_card:
		if current_state == State.CAUGHT and not current_fish.is_empty():
			catch_card.visible = true
			var fish_img: TextureRect = catch_card.get_node_or_null("FishImage")
			var name_lbl: Label = catch_card.get_node_or_null("FishName")
			var desc_lbl: Label = catch_card.get_node_or_null("FishDesc")
			var stat_lbl: Label = catch_card.get_node_or_null("FishStats")
			var prompt_lbl: Label = catch_card.get_node_or_null("PromptLabel")
			if name_lbl: name_lbl.text = current_fish.get("name", "Unknown Fish")
			if desc_lbl: desc_lbl.text = current_fish.get("description", "")
			var val: float = current_fish.get("weight", 1.0) * 2.5
			if stat_lbl: stat_lbl.text = "Weight: %.1f lbs | Value: $%.2f | Rarity: %s" % [current_fish.get("weight", 1.0), val, current_fish.get("rarity", "Common")]
			if prompt_lbl: prompt_lbl.text = "[ Left-Click: KEEP (+$%.2f)  |  Right-Click: RELEASE ]" % val
			if fish_img and ResourceLoader.exists(current_fish.get("texture_path", "")):
				fish_img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				fish_img.texture = load(current_fish.get("texture_path"))
		else:
			catch_card.visible = false

func _build_angler_blockout() -> void:
	if camera == null or camera.get_node_or_null("Angler"):
		return
	var angler := Node3D.new()
	angler.name = "Angler"
	camera.add_child(angler)
	var torso := BoxMesh.new()
	torso.size = Vector3(0.46, 0.42, 0.22)
	torso.material = _flat_mat("2A2018")
	var torso_inst := MeshInstance3D.new()
	torso_inst.name = "Torso"
	torso_inst.mesh = torso
	torso_inst.position = Vector3(0.0, -0.55, 0.05)
	angler.add_child(torso_inst)
	var arm := BoxMesh.new()
	arm.size = Vector3(0.12, 0.34, 0.12)
	arm.material = _flat_mat("B8A090")
	for side in [-1.0, 1.0]:
		var arm_inst := MeshInstance3D.new()
		arm_inst.name = "Arm"
		arm_inst.mesh = arm
		arm_inst.position = Vector3(0.28 * side, -0.42, -0.12)
		angler.add_child(arm_inst)
	if flashlight:
		var lamp := BoxMesh.new()
		lamp.size = Vector3(0.08, 0.1, 0.08)
		var glow := _flat_mat("E07828")
		glow.emission_enabled = true
		glow.emission = Color("E07828")
		glow.emission_energy_multiplier = 0.4
		lamp.material = glow
		var lamp_inst := MeshInstance3D.new()
		lamp_inst.name = "Lantern"
		lamp_inst.mesh = lamp
		flashlight.add_child(lamp_inst)

func _style_rod_blockout() -> void:
	var rod := get_node_or_null("Camera3D/RodPivot/RodMesh") as MeshInstance3D
	if rod:
		rod.material_override = _flat_mat("2A2018")
	var cork := get_node_or_null("Camera3D/RodPivot/RodMesh/CorkHandle") as MeshInstance3D
	if cork:
		cork.material_override = _flat_mat("B8A090")

func _tint_reel_for_discipline() -> void:
	if cork_handle == null:
		return
	var reel := cork_handle.get_node_or_null("ReelPivot/ReelBody") as MeshInstance3D
	if reel == null:
		return
	var hex := "B8A090"
	match current_discipline:
		FishingTypes.Discipline.BAITCASTING:
			hex = "2A2018"
		FishingTypes.Discipline.SPINCAST:
			hex = "D4C8B0"
		FishingTypes.Discipline.FLY_FISHING:
			hex = "E07828"
		_:
			hex = "B8A090"
	reel.material_override = _flat_mat(hex)

func _flat_mat(hex: String) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(hex)
	mat.roughness = 1.0
	mat.metallic = 0.0
	return mat

func _ensure_journal_stub() -> void:
	if hud == null or hud.get_node_or_null("JournalStub"):
		return
	var panel := Panel.new()
	panel.name = "JournalStub"
	panel.visible = false
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -210.0
	panel.offset_right = 210.0
	panel.offset_top = -260.0
	panel.offset_bottom = 260.0
	var box := StyleBoxFlat.new()
	box.bg_color = Color("D4C8B0")
	box.border_color = Color("2A2018")
	box.set_border_width_all(4)
	panel.add_theme_stylebox_override("panel", box)
	var title := Label.new()
	title.text = "Field journal"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(24, 28)
	title.size = Vector2(372, 32)
	title.add_theme_color_override("font_color", Color("2A2018"))
	panel.add_child(title)
	var body := Label.new()
	body.text = "Paper stub. Catch notes land here when Art delivers the journal sheet."
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.position = Vector2(28, 78)
	body.size = Vector2(364, 120)
	body.add_theme_color_override("font_color", Color("2A2018"))
	panel.add_child(body)
	var hint := Label.new()
	hint.text = "J closes"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(24, 470)
	hint.size = Vector2(372, 28)
	hint.add_theme_color_override("font_color", Color("B8A090"))
	panel.add_child(hint)
	hud.add_child(panel)

func _toggle_journal() -> void:
	var panel := hud.get_node_or_null("JournalStub") if hud else null
	if panel:
		panel.visible = not panel.visible

func _apply_lake_water_tint() -> void:
	var day_amount := 0.0
	if time_of_day > 0.2 and time_of_day < 0.7:
		day_amount = 1.0
	elif time_of_day >= 0.7 and time_of_day < 0.8:
		day_amount = 1.0 - (time_of_day - 0.7) / 0.1
	elif time_of_day >= 0.15 and time_of_day <= 0.2:
		day_amount = (time_of_day - 0.15) / 0.05
	var day_col := Color("65ACB2")
	var night_col := Color("122E36")
	if _water_mat == null:
		var water := get_node_or_null("../WaterPlane") as MeshInstance3D
		if water == null:
			return
		var source := water.get_active_material(0) as ShaderMaterial
		if source == null:
			return
		_water_mat = source.duplicate() as ShaderMaterial
		water.set_surface_override_material(0, _water_mat)
	_water_mat.set_shader_parameter("surface_color", night_col.lerp(day_col, day_amount))
	_water_mat.set_shader_parameter("depth_color", night_col)
	const rain_path := "res://assets/vfx/rain_ripples.png"
	if not _rain_foam_set and ResourceLoader.exists(rain_path):
		_water_mat.set_shader_parameter("_foam", load(rain_path))
		_rain_foam_set = true

func _style_catch_card() -> void:
	var card := hud.get_node_or_null("CatchCard") as Panel
	if card == null:
		return
	const card_path := "res://assets/ui/catch_card.png"
	card.offset_left = -210.0
	card.offset_right = 210.0
	card.offset_top = -260.0
	card.offset_bottom = 260.0
	if ResourceLoader.exists(card_path):
		card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var style := StyleBoxTexture.new()
		style.texture = load(card_path)
		card.add_theme_stylebox_override("panel", style)
	else:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("2A2018")
		box.border_color = Color("B8A090")
		box.set_border_width_all(3)
		card.add_theme_stylebox_override("panel", box)
		for label_name in ["CardTitle", "FishName", "FishStats", "FishDesc", "PromptLabel"]:
			var label := card.get_node_or_null(label_name) as Label
			if label:
				label.add_theme_color_override("font_color", Color("D4C8B0"))
	var fish_img := card.get_node_or_null("FishImage") as TextureRect
	if fish_img:
		fish_img.offset_left = -128.0
		fish_img.offset_right = 128.0
		fish_img.offset_top = -180.0
		fish_img.offset_bottom = -52.0
		fish_img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _ensure_buoy_placeholder() -> void:
	const buoy_path := "res://models/buoy_red.glb"
	var parent := get_parent()
	if parent == null or parent.get_node_or_null("BuoyMarker"):
		return
	if ResourceLoader.exists(buoy_path):
		var packed: PackedScene = load(buoy_path)
		if packed:
			var buoy := packed.instantiate()
			buoy.name = "BuoyMarker"
			if buoy is Node3D:
				(buoy as Node3D).position = Vector3(6.0, 0.2, -16.0)
			parent.add_child(buoy)
			return
	var marker := MeshInstance3D.new()
	marker.name = "BuoyMarker"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.16
	cyl.bottom_radius = 0.16
	cyl.height = 0.7
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("D1453A")
	cyl.material = mat
	marker.mesh = cyl
	marker.position = Vector3(6.0, 0.35, -16.0)
	parent.add_child(marker)

func _flash(message: String, seconds: float = 2.4) -> void:
	banner_text = message
	banner_time = seconds

func _is_after_dark() -> bool:
	return time_of_day < 0.15 or time_of_day >= 0.8

func _cycle_bait(direction: int) -> void:
	if TackleBox.available_baits.is_empty():
		return
	_bait_index = posmod(_bait_index + direction, TackleBox.available_baits.size())
	_highlight_bait_index()

func _confirm_bait_index() -> void:
	if _bait_index < 0 or _bait_index >= TackleBox.available_baits.size():
		return
	_on_bait_selected(TackleBox.available_baits[_bait_index].name)

func _highlight_bait_index() -> void:
	for i in _slot_buttons.size():
		var btn := _slot_buttons[i]
		if not is_instance_valid(btn):
			continue
		btn.modulate = Color("D4C8B0") if i == _bait_index else Color("B8A090")

func _refresh_slot_locks() -> void:
	var dark := _is_after_dark()
	for i in mini(_slot_buttons.size(), TackleBox.available_baits.size()):
		var bait := TackleBox.available_baits[i]
		var btn := _slot_buttons[i]
		if not is_instance_valid(btn):
			continue
		var locked := bait.id == "rotten_meat" and not dark
		btn.disabled = locked
		if locked:
			btn.modulate = Color("2A2018")
		elif i == _bait_index:
			btn.modulate = Color("D4C8B0")
		else:
			btn.modulate = Color("B8A090")

func _wire_hud_sheet() -> void:
	if not hud or not ResourceLoader.exists(HUD_SHEET):
		return
	var tex: Texture2D = load(HUD_SHEET)
	_hud_panel = TextureRect.new()
	_hud_panel.name = "HudFishingSheet"
	_hud_panel.texture = tex
	_hud_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hud_panel.stretch_mode = TextureRect.STRETCH_SCALE
	_hud_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hud_panel.offset_left = -160
	_hud_panel.offset_right = 160
	_hud_panel.offset_top = -128
	_hud_panel.offset_bottom = -80
	_hud_panel.visible = false
	hud.add_child(_hud_panel)
	var track := ColorRect.new()
	track.color = Color("2A2018")
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.position = HUD_BAR_ORIGIN
	track.size = HUD_BAR_SIZE
	_hud_panel.add_child(track)
	_hud_fill = ColorRect.new()
	_hud_fill.color = Color("65ACB2")
	_hud_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_fill.position = HUD_BAR_ORIGIN
	_hud_fill.size = Vector2(0, HUD_BAR_SIZE.y)
	_hud_panel.add_child(_hud_fill)

func _update_hud_fill(ratio: float, show: bool, danger: bool) -> void:
	if not _hud_panel or not _hud_fill:
		return
	_hud_panel.visible = show
	var clamped := clampf(ratio, 0.0, 1.0)
	_hud_fill.size = Vector2(HUD_BAR_SIZE.x * clamped, HUD_BAR_SIZE.y)
	_hud_fill.color = Color("D1453A") if danger and clamped > 0.75 else Color("65ACB2")

func _spawn_splash(pos: Vector3) -> void:
	if not ResourceLoader.exists(SPLASH_SHEET):
		return
	var live: Array[Sprite3D] = []
	for node in _splash_nodes:
		if is_instance_valid(node):
			live.append(node)
	_splash_nodes = live
	if _splash_nodes.size() >= 2:
		return
	var sprite := Sprite3D.new()
	sprite.texture = load(SPLASH_SHEET)
	sprite.hframes = 6
	sprite.vframes = 1
	sprite.frame = 0
	sprite.pixel_size = 0.015
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.shaded = false
	sprite.double_sided = false
	sprite.position = pos + Vector3(0, 0.25, 0)
	sprite.set_meta("age", 0.0)
	get_parent().add_child(sprite)
	_splash_nodes.append(sprite)

func _advance_splashes(delta: float) -> void:
	var live: Array[Sprite3D] = []
	for sprite in _splash_nodes:
		if not is_instance_valid(sprite):
			continue
		var age := float(sprite.get_meta("age")) + delta
		var frame := int(age * 12.0)
		if frame >= 6:
			sprite.queue_free()
			continue
		sprite.set_meta("age", age)
		sprite.frame = frame
		live.append(sprite)
	_splash_nodes = live
