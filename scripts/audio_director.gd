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
const RAIN := "res://audio/sfx/weather/RainAmbience.ogg"
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
	_wrong_splashes = [_wrong_splash(910.0, 7), _wrong_splash(1340.0, 19), _wrong_splash(1680.0, 31)]
	_splash = _add_player(BUS_AMBIENCE, _wrong_splashes[0], "DistantSplash")
	_snap = _add_player(BUS_SFX, _noise_burst(), "LineSnap")
	_miss = _add_player(BUS_UI, _fail_blip(), "MissAway")
	_ui = _add_player(BUS_UI, _load_one_shot(UI_CLICK), "UiClick")
	_latch = _add_player(BUS_UI, _latch_click(), "TackleLatch")
	_chime = _add_player(BUS_UI, _major_chime(), "CatchChime")
	_keep = _add_player(BUS_UI, _confirm_blip(), "KeepBlip")
	_release = _add_player(BUS_SFX, _water_slip(), "ReleaseSlip")
	_steps = [_wood_step(112.0), _wood_step(148.0), _wood_step(186.0)]
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
	if _ui.stream == null:
		_ui.stream = _tick()
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

func _noise_burst() -> AudioStreamWAV:
	return _render(22050, 0.07, 30000.0, func(i: int, count: int, rate: int) -> float:
		var t := float(i) / float(count)
		var env := exp(-t * 22.0)
		var noise := sin(float(i) * 12.7) * sin(float(i) * 0.37)
		var thump := sin(TAU * 95.0 * float(i) / float(rate)) * exp(-t * 30.0)
		return (noise * 0.75 + thump * 0.8) * env
	)

func _fail_blip() -> AudioStreamWAV:
	return _render(22050, 0.16, 16000.0, func(i: int, count: int, rate: int) -> float:
		var t := float(i) / float(count)
		var hz := lerpf(540.0, 280.0, t)
		return sin(TAU * hz * float(i) / float(rate)) * exp(-t * 7.0) * (1.0 - t)
	)

func _major_chime() -> AudioStreamWAV:
	return _render(22050, 0.42, 14000.0, func(i: int, _count: int, rate: int) -> float:
		var time := float(i) / float(rate)
		var env := exp(-time * 4.2)
		var tone := 0.0
		tone += sin(TAU * 523.25 * time) * 0.45
		if time > 0.04:
			tone += sin(TAU * 659.25 * time) * 0.32
		if time > 0.08:
			tone += sin(TAU * 783.99 * time) * 0.24
		return tone * env
	)

func _confirm_blip() -> AudioStreamWAV:
	return _render(22050, 0.14, 12000.0, func(i: int, _count: int, rate: int) -> float:
		var time := float(i) / float(rate)
		var env := exp(-time * 10.0)
		var hz := 660.0 if time < 0.06 else 880.0
		return sin(TAU * hz * time) * env
	)

func _water_slip() -> AudioStreamWAV:
	return _render(22050, 0.18, 14000.0, func(i: int, count: int, rate: int) -> float:
		var t := float(i) / float(count)
		var env := sin(PI * t) * exp(-t * 3.0)
		var noise := sin(float(i) * 2.1) * sin(float(i) * 0.17)
		var body := sin(TAU * lerpf(420.0, 160.0, t) * float(i) / float(rate))
		return (noise * 0.35 + body * 0.4) * env
	)

func _latch_click() -> AudioStreamWAV:
	return _render(22050, 0.09, 20000.0, func(i: int, count: int, rate: int) -> float:
		var time := float(i) / float(rate)
		var t := float(i) / float(count)
		var first := sin(TAU * 220.0 * time) * exp(-t * 28.0)
		var second := 0.0
		if time > 0.028:
			second = sin(TAU * 160.0 * time) * exp(-(t - 0.3) * 18.0) * 0.7
		return first * 0.8 + second
	)

func _wrong_splash(partial_hz: float, seed: int) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var noise: Array[float] = []
	noise.resize(8)
	for n in noise.size():
		noise[n] = rng.randf_range(-1.0, 1.0)
	return _render(22050, 0.38, 22000.0, func(i: int, count: int, rate: int) -> float:
		var t := float(i) / float(count)
		var env := pow(t, 0.35) * exp(-t * 5.5)
		var bucket := int(t * float(noise.size() - 1))
		var water := noise[bucket]
		var ping := sin(TAU * partial_hz * float(i) / float(rate)) * exp(-t * 2.2) * 0.22
		var thunk := sin(TAU * 70.0 * float(i) / float(rate)) * exp(-t * 14.0)
		return (water * 0.55 + thunk * 0.5 + ping) * env
	)

func _tick() -> AudioStreamWAV:
	return _render(22050, 0.03, 18000.0, func(i: int, count: int, rate: int) -> float:
		var t := float(i) / float(count)
		return sin(TAU * 1400.0 * float(i) / float(rate)) * exp(-t * 18.0)
	)

func _render(rate: int, seconds: float, amp: float, sampler: Callable) -> AudioStreamWAV:
	var count := maxi(int(rate * seconds), 1)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var sample := clampf(float(sampler.call(i, count, rate)), -1.0, 1.0)
		data.encode_s16(i * 2, int(sample * amp))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = data
	return wav
