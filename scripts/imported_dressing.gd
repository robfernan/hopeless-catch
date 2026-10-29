extends Node3D
## Shows an imported mesh. Turns off its collision so the dock and the water-height test stay in charge of play.

func _ready() -> void:
	for body in find_children("*", "CollisionObject3D", true, false):
		body.collision_layer = 0
		body.collision_mask = 0
