class_name AudioSynth
extends RefCounted
## Cached mono PCM for gameplay cues. Built once at load.
## A file at the usual path overrides the matching stream. Beds stay files.

static var cast_whoosh: AudioStream
static var bite_tick: AudioStream
static var reel_tick: AudioStream
static var splash: AudioStream
static var fight_loop: AudioStream
static var flap_loop: AudioStream
static var line_snap: AudioStream
static var missed_hook: AudioStream
static var catch_chime: AudioStream
static var keep_blip: AudioStream
static var release_slip: AudioStream
static var ui_click: AudioStream
static var tackle_latch: AudioStream
static var dock_steps: Array[AudioStream] = []
static var wrong_splashes: Array[AudioStream] = []
static var _built: bool = false

static func ensure() -> void:
	if _built:
		return
	cast_whoosh = _whoosh()
	bite_tick = _tick(1800.0, 0.035, 22000.0)
	reel_tick = _tick(920.0, 0.028, 16000.0)
	splash = _plop()
	fight_loop = _fight_loop()
	flap_loop = _flap_loop()
	line_snap = _snap()
	missed_hook = _fail_blip()
	catch_chime = _major_chime()
	keep_blip = _confirm_blip()
	release_slip = _water_slip()
	ui_click = _tick(1400.0, 0.03, 18000.0)
	tackle_latch = _latch_click()
	dock_steps = [_wood_step(112.0), _wood_step(148.0), _wood_step(186.0)]
	wrong_splashes = [_wrong_splash(910.0, 7), _wrong_splash(1340.0, 19), _wrong_splash(1680.0, 31)]
	_built = true

## File wins when it is actually in the project. Otherwise the cached synth stream.
static func resolve(path: String, fallback: AudioStream) -> AudioStream:
	ensure()
	if path != "" and ResourceLoader.exists(path):
		var loaded: AudioStream = load(path)
		if loaded != null:
			return loaded
	return fallback

static func _whoosh() -> AudioStreamWAV:
	return _render(22050, 0.2, 20000.0, false, func(i: int, count: int, rate: int) -> float:
		var t := float(i) / float(count)
		var env := sin(PI * t)
		var hz := lerpf(280.0, 1400.0, t)
		var air := sin(float(i) * hz / 900.0) * sin(float(i) * 0.21)
		return air * env
	)

static func _tick(hz: float, seconds: float, amp: float) -> AudioStreamWAV:
	return _render(22050, seconds, amp, false, func(i: int, count: int, rate: int) -> float:
		var t := float(i) / float(count)
		return sin(TAU * hz * float(i) / float(rate)) * exp(-t * 18.0)
	)

static func _plop() -> AudioStreamWAV:
	return _render(22050, 0.22, 22000.0, false, func(i: int, count: int, rate: int) -> float:
		var t := float(i) / float(count)
		var env := pow(t, 0.25) * exp(-t * 7.0)
		var body := sin(TAU * lerpf(320.0, 90.0, t) * float(i) / float(rate))
		var spray := sin(float(i) * 3.3) * sin(float(i) * 0.19) * exp(-t * 5.0)
		return (body * 0.65 + spray * 0.35) * env
	)

static func _fight_loop() -> AudioStreamWAV:
	# Integer cycles over 1 second so the loop seam stays continuous.
	return _render(22050, 1.0, 16000.0, true, func(i: int, _count: int, rate: int) -> float:
		var time := float(i) / float(rate)
		var pulse := 0.62 + 0.38 * sin(TAU * 2.0 * time)
		var tone := sin(TAU * 82.0 * time) * 0.5
		tone += sin(TAU * 164.0 * time) * 0.22
		var grit := sin(TAU * 37.0 * time) * sin(TAU * 13.0 * time) * 0.28
		return (tone + grit) * pulse
	)

static func _flap_loop() -> AudioStreamWAV:
	return _render(22050, 0.5, 18000.0, true, func(i: int, count: int, _rate: int) -> float:
		var t := float(i) / float(count)
		var env := 0.0
		if t < 0.22:
			env = sin(PI * t / 0.22)
		elif t > 0.28 and t < 0.5:
			env = sin(PI * (t - 0.28) / 0.22) * 0.85
		var rustle := sin(float(i) * 4.7) * sin(float(i) * 0.53)
		return rustle * env
	)

static func _snap() -> AudioStreamWAV:
	return _render(22050, 0.07, 30000.0, false, func(i: int, count: int, rate: int) -> float:
		var t := float(i) / float(count)
		var env := exp(-t * 22.0)
		var noise := sin(float(i) * 12.7) * sin(float(i) * 0.37)
		var thump := sin(TAU * 95.0 * float(i) / float(rate)) * exp(-t * 30.0)
		return (noise * 0.75 + thump * 0.8) * env
	)

static func _fail_blip() -> AudioStreamWAV:
	return _render(22050, 0.16, 16000.0, false, func(i: int, count: int, rate: int) -> float:
		var t := float(i) / float(count)
		var hz := lerpf(540.0, 280.0, t)
		return sin(TAU * hz * float(i) / float(rate)) * exp(-t * 7.0) * (1.0 - t)
	)

static func _major_chime() -> AudioStreamWAV:
	return _render(22050, 0.42, 14000.0, false, func(i: int, _count: int, rate: int) -> float:
		var time := float(i) / float(rate)
		var env := exp(-time * 4.2)
		var tone := sin(TAU * 523.25 * time) * 0.45
		if time > 0.04:
			tone += sin(TAU * 659.25 * time) * 0.32
		if time > 0.08:
			tone += sin(TAU * 783.99 * time) * 0.24
		return tone * env
	)

static func _confirm_blip() -> AudioStreamWAV:
	return _render(22050, 0.14, 12000.0, false, func(i: int, _count: int, rate: int) -> float:
		var time := float(i) / float(rate)
		var env := exp(-time * 10.0)
		var hz := 660.0 if time < 0.06 else 880.0
		return sin(TAU * hz * time) * env
	)

static func _water_slip() -> AudioStreamWAV:
	return _render(22050, 0.18, 14000.0, false, func(i: int, count: int, rate: int) -> float:
		var t := float(i) / float(count)
		var env := sin(PI * t) * exp(-t * 3.0)
		var noise := sin(float(i) * 2.1) * sin(float(i) * 0.17)
		var body := sin(TAU * lerpf(420.0, 160.0, t) * float(i) / float(rate))
		return (noise * 0.35 + body * 0.4) * env
	)

static func _latch_click() -> AudioStreamWAV:
	return _render(22050, 0.09, 20000.0, false, func(i: int, count: int, rate: int) -> float:
		var time := float(i) / float(rate)
		var t := float(i) / float(count)
		var first := sin(TAU * 220.0 * time) * exp(-t * 28.0)
		var second := 0.0
		if time > 0.028:
			second = sin(TAU * 160.0 * time) * exp(-(t - 0.3) * 18.0) * 0.7
		return first * 0.8 + second
	)

static func _wood_step(body_hz: float) -> AudioStreamWAV:
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
	return _wav(rate, data, false)

static func _wrong_splash(partial_hz: float, seed: int) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var noise: Array[float] = []
	noise.resize(8)
	for n in noise.size():
		noise[n] = rng.randf_range(-1.0, 1.0)
	return _render(22050, 0.38, 22000.0, false, func(i: int, count: int, rate: int) -> float:
		var t := float(i) / float(count)
		var env := pow(t, 0.35) * exp(-t * 5.5)
		var bucket := int(t * float(noise.size() - 1))
		var water := noise[bucket]
		var ping := sin(TAU * partial_hz * float(i) / float(rate)) * exp(-t * 2.2) * 0.22
		var thunk := sin(TAU * 70.0 * float(i) / float(rate)) * exp(-t * 14.0)
		return (water * 0.55 + thunk * 0.5 + ping) * env
	)

static func _render(rate: int, seconds: float, amp: float, looping: bool, sampler: Callable) -> AudioStreamWAV:
	var count := maxi(int(rate * seconds), 1)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var sample := clampf(float(sampler.call(i, count, rate)), -1.0, 1.0)
		data.encode_s16(i * 2, int(sample * amp))
	return _wav(rate, data, looping)

static func _wav(rate: int, data: PackedByteArray, looping: bool) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if looping else AudioStreamWAV.LOOP_DISABLED
	wav.data = data
	return wav
