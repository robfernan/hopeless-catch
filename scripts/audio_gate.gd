extends Node
## Master mute gate. Does not load or synthesize sounds.
## Web stays silent until the first click or key. Any platform mutes when the window loses focus.

var unlocked: bool = false
var focused: bool = true

func _ready() -> void:
	if OS.has_feature("web"):
		_apply_mute()

func _input(event: InputEvent) -> void:
	if unlocked:
		return
	var pressed := false
	if event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventJoypadButton or event is InputEventKey:
		pressed = event.pressed
	if not pressed:
		return
	unlocked = true
	_apply_mute()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		focused = false
		_apply_mute()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		focused = true
		_apply_mute()

func _apply_mute() -> void:
	var master := AudioServer.get_bus_index("Master")
	if master < 0:
		return
	var mute := not focused or (OS.has_feature("web") and not unlocked)
	AudioServer.set_bus_mute(master, mute)
