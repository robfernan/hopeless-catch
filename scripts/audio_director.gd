extends Node
## Lake mix for the dock scene. Does not replace AudioGate.
##
## Plays ambience_lake_V4 (day) and ambience_lake_V5 (night) plus the birds
## bed on the Ambience bus. Apartment and church files stay on disk and are
## never started here. There is no weather state in this scene; set_raining()
## is the hook for a future rain system and it is not called on the lake.

const LAKE_DAY := "res://audio/sfx/ambience_lake_V4.ogg"
const LAKE_NIGHT := "res://audio/sfx/ambience_lake_V5.ogg"
const BIRDS := "res://audio/sfx/birds/BirdsAmbience.ogg"
const RAIN := "res://audio/sfx/weather/RainAmbience.ogg"
const DISTANT_SPLASH := "res://audio/sfx/water/above_water_light_splash_3.ogg"
const LINE_SNAP := "res://audio/sfx/rope/line_snap.ogg"
const MISS_AWAY := "res://audio/sfx/Fish_Swim_Away.wav"
const UI_CLICK := "res://audio/sfx/distance_click_1.ogg"

const BUS_AMBIENCE := "Ambience"
const BUS_SFX := "SFX"
const BUS_UI := "UI"

var _day: AudioStreamPlayer
var _night: AudioStreamPlayer
var _birds: AudioStreamPlayer
var _rain: AudioStreamPlayer
var _splash: AudioStreamPlayer
var _snap: AudioStreamPlayer
var _miss: AudioStreamPlayer
var _ui: AudioStreamPlayer
var _step: AudioStreamPlayer
var _step_a: AudioStream
var _step_b: AudioStream
var _step_right: bool = false

var _night_amount: float = 0.0
var _fighting: bool = false
var _duck_db: float = 0.0
var _duck_target: float = 0.0
var _ambience_base_db: float = -16.0
var _deep_night: bool = false
var _splash_wait: float = 20.0
var raining: bool = false

func _ready() -> void:
	var ambience := AudioServer.get_bus_index(BUS_AMBIENCE)
	if ambience >= 0:
		_ambience_base_db = AudioServer.get_bus_volume_db(ambience)
	_day = _add_player(BUS_AMBIENCE, _load_loop(LAKE_DAY), "LakeDay")
	_night = _add_player(BUS_AMBIENCE, _load_loop(LAKE_NIGHT), "LakeNight")
	_birds = _add_player(BUS_AMBIENCE, _load_loop(BIRDS), "LakeBirds")
	_rain = _add_player(BUS_AMBIENCE, _load_loop(RAIN), "Rain")
	_splash = _add_player(BUS_AMBIENCE, _load_one_shot(DISTANT_SPLASH), "DistantSplash")
	_snap = _add_player(BUS_SFX, _load_one_shot(LINE_SNAP), "LineSnap")
	_miss = _add_player(BUS_SFX, _load_one_shot(MISS_AWAY), "MissAway")
	_ui = _add_player(BUS_UI, _load_one_shot(UI_CLICK), "UiClick")
	_step_a = _wood_step(118.0)
	_step_b = _wood_step(164.0)
	_step = _add_player(BUS_SFX, _step_a, "DockStep")
	_step.volume_db = -8.0
	_ui.volume_db = -2.0
	_start(_day)
	_start(_night)
	_start(_birds)
	_apply_bed_volumes()

func _process(delta: float) -> void:
	_duck_db = lerpf(_duck_db, _duck_target, 1.0 - exp(-6.0 * delta))
	var ambience := AudioServer.get_bus_index(BUS_AMBIENCE)
	if ambience >= 0:
		AudioServer.set_bus_volume_db(ambience, _ambience_base_db + _duck_db)
	var deep := _night_amount >= 0.85 and not _fighting
	if deep and not _deep_night:
		_splash_wait = randf_range(18.0, 36.0)
	_deep_night = deep
	if not deep:
		return
	_splash_wait -= delta
	if _splash_wait > 0.0:
		return
	_splash_wait = randf_range(26.0, 52.0)
	_play_distant_splash()

## Clock from the dock scene. 0 is midnight, 0.5 is noon.
func notify_clock(time_of_day: float) -> void:
	_night_amount = _night_weight(time_of_day)
	_apply_bed_volumes()

## Duck the Ambience bus while a fish is on, deeper as tension climbs.
func notify_tension(fighting: bool, tension: float) -> void:
	_fighting = fighting
	if not fighting:
		_duck_target = 0.0
		return
	var amount := clampf(tension / 100.0, 0.0, 1.0)
	_duck_target = lerpf(-3.0, -8.0, amount)

## Future weather hook. The lake scene has no rain state and does not call this.
## Do not point it at apartment or church loops.
func set_raining(active: bool) -> void:
	raining = active
	if _rain == null or _rain.stream == null:
		if active:
			push_warning("AudioDirector: rain bed missing at %s" % RAIN)
		return
	if active:
		_start(_rain)
	else:
		_rain.stop()

func play_line_snap() -> void:
	_play(_snap, randf_range(0.96, 1.04))

func play_miss() -> void:
	_play(_miss, randf_range(0.94, 1.02))

func play_ui_click() -> void:
	if _ui.stream == null:
		_ui.stream = _tick()
	_play(_ui, randf_range(0.97, 1.05))

func play_dock_step() -> void:
	_step_right = not _step_right
	_step.stream = _step_b if _step_right else _step_a
	_play(_step, randf_range(0.94, 1.08))

func _play_distant_splash() -> void:
	if _splash.stream == null:
		return
	_splash.volume_db = randf_range(-16.0, -11.0)
	_play(_splash, randf_range(0.68, 0.86))

func _apply_bed_volumes() -> void:
	var day := 1.0 - _night_amount
	_set_bed_volume(_day, day)
	_set_bed_volume(_night, _night_amount)
	_set_bed_volume(_birds, day * 0.72)

func _set_bed_volume(player: AudioStreamPlayer, weight: float) -> void:
	if player == null:
		return
	if weight <= 0.001:
		player.volume_db = -80.0
	else:
		player.volume_db = linear_to_db(weight)

func _night_weight(time_of_day: float) -> float:
	var t := fposmod(time_of_day, 1.0)
	if t >= 0.30 and t <= 0.62:
		return 0.0
	if t >= 0.78 or t <= 0.12:
		return 1.0
	if t > 0.62 and t < 0.78:
		return smoothstep(0.62, 0.78, t)
	return 1.0 - smoothstep(0.12, 0.30, t)

func _add_player(bus_name: String, stream: AudioStream, node_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.bus = bus_name
	player.stream = stream
	add_child(player)
	return player

func _start(player: AudioStreamPlayer) -> void:
	if player != null and player.stream != null and not player.playing:
		player.play()

func _play(player: AudioStreamPlayer, pitch: float) -> void:
	if player == null or player.stream == null:
		return
	player.pitch_scale = pitch
	player.play()

func _load_loop(path: String) -> AudioStream:
	var stream := _load_one_shot(path)
	if stream == null:
		return null
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return stream

func _load_one_shot(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning("AudioDirector: missing %s" % path)
		return null
	var loaded: AudioStream = load(path)
	if loaded == null:
		return null
	return loaded.duplicate() as AudioStream

func _wood_step(body_hz: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 0.085)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(body_hz * 1000.0)
	var low := 0.0
	for i in count:
		var t := float(i) / float(count)
		var env := exp(-t * 16.0)
		low = lerpf(low, rng.randf_range(-1.0, 1.0), 0.16)
		var body := sin(TAU * body_hz * float(i) / float(rate)) * exp(-t * 24.0)
		var sample := clampf((low * 0.45 + body * 0.7) * env, -1.0, 1.0)
		data.encode_s16(i * 2, int(sample * 28000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = data
	return wav

func _tick() -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 0.03)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / float(count)
		var sample := sin(TAU * 1400.0 * float(i) / float(rate)) * exp(-t * 18.0)
		data.encode_s16(i * 2, int(sample * 18000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav
