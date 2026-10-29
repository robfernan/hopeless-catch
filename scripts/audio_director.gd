extends Node
## Lake mix for the dock scene. Does not replace AudioGate.
##
## Plays ambience_lake_V4 (day) and ambience_lake_V5 (night) plus the birds
## bed on the Ambience bus. Apartment day/night are cabin beds only: call
## set_cabin_interior(). The lake clock never starts them, and church files
## are not lake beds. set_raining() is unused until a weather state exists.

const LAKE_DAY := "res://audio/sfx/ambience_lake_V4.ogg"
const LAKE_NIGHT := "res://audio/sfx/ambience_lake_V5.ogg"
const BIRDS := "res://audio/sfx/birds/BirdsAmbience.ogg"
const RAIN := "res://audio/sfx/weather/rain_loop.ogg"
const UI_CLICK := "res://audio/sfx/distance_click_1.ogg"
## Cabin / interior only. The lake clock must not start these.
const CABIN_DAY := "res://audio/sfx/ambience_apartment_day_loop.ogg"
const CABIN_NIGHT := "res://audio/sfx/ambience_apartment_night_loop.ogg"

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
var _latch: AudioStreamPlayer
var _chime: AudioStreamPlayer
var _keep: AudioStreamPlayer
var _release: AudioStreamPlayer
var _cabin_day: AudioStreamPlayer
var _cabin_night: AudioStreamPlayer
var _step: AudioStreamPlayer
var _steps: Array[AudioStream] = []
var _step_i: int = 0
var _wrong_splashes: Array[AudioStream] = []

var _night_amount: float = 0.0
var _fighting: bool = false
var _duck_db: float = 0.0
var _duck_target: float = 0.0
var _sfx_lift: float = 0.0
var _sfx_lift_target: float = 0.0
var _ambience_base_db: float = -16.0
var _sfx_base_db: float = -6.0
var _deep_night: bool = false
var _splash_wait: float = 30.0
var raining: bool = false
var interior_active: bool = false
var interior_night: bool = false

func _ready() -> void:
	var ambience := AudioServer.get_bus_index(BUS_AMBIENCE)
	if ambience >= 0:
		_ambience_base_db = AudioServer.get_bus_volume_db(ambience)
	var sfx := AudioServer.get_bus_index(BUS_SFX)
	if sfx >= 0:
		_sfx_base_db = AudioServer.get_bus_volume_db(sfx)
	_day = _add_player(BUS_AMBIENCE, _load_loop(LAKE_DAY), "LakeDay")
	_night = _add_player(BUS_AMBIENCE, _load_loop(LAKE_NIGHT), "LakeNight")
	_birds = _add_player(BUS_AMBIENCE, _load_loop(BIRDS), "LakeBirds")
	_rain = _add_player(BUS_AMBIENCE, _load_loop(RAIN), "Rain")
	_cabin_day = _add_player(BUS_AMBIENCE, _load_loop(CABIN_DAY), "CabinDay")
	_cabin_night = _add_player(BUS_AMBIENCE, _load_loop(CABIN_NIGHT), "CabinNight")
	AudioSynth.ensure()
	_wrong_splashes = AudioSynth.wrong_splashes
	_splash = _add_player(BUS_AMBIENCE, _wrong_splashes[0], "DistantSplash")
	_snap = _add_player(BUS_SFX, AudioSynth.line_snap, "LineSnap")
	_miss = _add_player(BUS_UI, AudioSynth.missed_hook, "MissAway")
	_ui = _add_player(BUS_UI, AudioSynth.resolve(UI_CLICK, AudioSynth.ui_click), "UiClick")
	_latch = _add_player(BUS_UI, AudioSynth.tackle_latch, "TackleLatch")
	_chime = _add_player(BUS_UI, AudioSynth.catch_chime, "CatchChime")
	_keep = _add_player(BUS_UI, AudioSynth.keep_blip, "KeepBlip")
	_release = _add_player(BUS_SFX, AudioSynth.release_slip, "ReleaseSlip")
	_steps = AudioSynth.dock_steps
	_step = _add_player(BUS_SFX, _steps[0], "DockStep")
	_step.volume_db = -8.0
	_ui.volume_db = -2.0
	_miss.volume_db = -8.0
	_chime.volume_db = -8.0
	_keep.volume_db = -10.0
	_release.volume_db = -10.0
	_latch.volume_db = -4.0
	_start(_day)
	_start(_night)
	_start(_birds)
	_apply_bed_volumes()

func _process(delta: float) -> void:
	var glide := 1.0 - exp(-6.0 * delta)
	_duck_db = lerpf(_duck_db, _duck_target, glide)
	_sfx_lift = lerpf(_sfx_lift, _sfx_lift_target, glide)
	var ambience := AudioServer.get_bus_index(BUS_AMBIENCE)
	if ambience >= 0:
		var night_floor := lerpf(0.0, -2.0, _night_amount)
		AudioServer.set_bus_volume_db(ambience, _ambience_base_db + _duck_db + night_floor)
	var sfx := AudioServer.get_bus_index(BUS_SFX)
	if sfx >= 0:
		AudioServer.set_bus_volume_db(sfx, _sfx_base_db + _sfx_lift)
	var deep := _night_amount >= 0.85 and not _fighting and not interior_active
	if deep and not _deep_night:
		_splash_wait = randf_range(25.0, 60.0)
	_deep_night = deep
	if not deep:
		return
	_splash_wait -= delta
	if _splash_wait > 0.0:
		return
	_splash_wait = randf_range(25.0, 60.0)
	_play_distant_splash()

## Clock from the dock scene. 0 is midnight, 0.5 is noon.
func notify_clock(time_of_day: float) -> void:
	_night_amount = _night_weight(time_of_day)
	_apply_bed_volumes()

## Tension mixer. Fighting ducks Ambience 4 dB and lifts SFX 1–2 dB with tension.
func notify_tension(fighting: bool, tension: float) -> void:
	_fighting = fighting
	if not fighting:
		_duck_target = 0.0
		_sfx_lift_target = 0.0
		return
	var amount := clampf(tension / 100.0, 0.0, 1.0)
	_duck_target = -4.0
	_sfx_lift_target = lerpf(1.0, 2.0, amount)

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

## Cabin or apartment interior. Not a lake bed. The dock scene does not call this.
func set_cabin_interior(active: bool, is_night: bool = false) -> void:
	interior_active = active
	interior_night = is_night
	if not active:
		_stop(_cabin_day)
		_stop(_cabin_night)
		_start(_day)
		_start(_night)
		_start(_birds)
		_apply_bed_volumes()
		return
	_stop(_day)
	_stop(_night)
	_stop(_birds)
	_stop(_rain)
	if is_night:
		_stop(_cabin_day)
		_start(_cabin_night)
		if _cabin_night:
			_cabin_night.volume_db = 0.0
	else:
		_stop(_cabin_night)
		_start(_cabin_day)
		if _cabin_day:
			_cabin_day.volume_db = 0.0

func play_line_snap() -> void:
	_play(_snap, randf_range(0.92, 1.08))

func play_miss() -> void:
	_play(_miss, randf_range(0.94, 1.06))

func play_catch_chime() -> void:
	_play(_chime, randf_range(0.98, 1.02))

func play_keep() -> void:
	_play(_keep, randf_range(0.98, 1.04))

func play_release() -> void:
	_play(_release, randf_range(0.9, 1.08))

func play_ui_click() -> void:
	_play(_ui, randf_range(0.97, 1.05))

func play_tackle_latch() -> void:
	_play(_latch, randf_range(0.94, 1.06))

func play_dock_step() -> void:
	if _steps.is_empty():
		return
	_step_i = (_step_i + 1) % _steps.size()
	_step.stream = _steps[_step_i]
	_play(_step, randf_range(0.92, 1.1))

func _play_distant_splash() -> void:
	if _wrong_splashes.is_empty():
		return
	_splash.stream = _wrong_splashes[randi() % _wrong_splashes.size()]
	# AudioStreamPlayer has no pan. Pitch and level carry the distance.
	_splash.volume_db = randf_range(-24.0, -18.0)
	_play(_splash, randf_range(0.72, 1.18))

func _apply_bed_volumes() -> void:
	if interior_active:
		return
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

func _stop(player: AudioStreamPlayer) -> void:
	if player != null and player.playing:
		player.stop()

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
		push_warning("AudioDirector: missing bed %s" % path)
		return null
	var loaded: AudioStream = load(path)
	if loaded == null:
		return null
	return loaded.duplicate() as AudioStream
