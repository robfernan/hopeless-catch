extends Control
class_name MetroidvaniaMinimap

@export var player: Node3D
@export var lure: Node3D
@export var map_scale: float = 2.2 # Pixels per world meter

# Colors for Metroidvania radar theme
var color_ocean: Color = Color(0.08, 0.22, 0.28, 0.85)
var color_land: Color = Color(0.65, 0.58, 0.44, 0.9)
var color_dock: Color = Color(0.48, 0.35, 0.22, 1.0)
var color_grid: Color = Color(0.2, 0.4, 0.45, 0.35)
var color_player: Color = Color(1.0, 0.9, 0.2, 1.0)
var color_lure: Color = Color(0.95, 0.25, 0.2, 1.0)

var pulse_time: float = 0.0

func _process(delta: float) -> void:
	pulse_time += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.48
	
	# Clip drawing within round or square radar frame
	draw_circle(center, radius, color_ocean)
	
	if not player or not is_instance_valid(player):
		return

	var p_pos: Vector3 = player.global_position
	
	# Helper to convert world coordinate (X, Z) into minimap screen coordinate
	# Player is always centered on the minimap
	var to_map = func(wx: float, wz: float) -> Vector2:
		var offset: Vector2 = Vector2(wx - p_pos.x, wz - p_pos.z)
		# North-up is classic Metroidvania style
		return center + offset * map_scale

	# Draw Mainland Shoreline (everything Z > 2 is land)
	var land_top_left: Vector2 = to_map.call(-100.0, 4.0)
	var land_rect: Rect2 = Rect2(Vector2(0, land_top_left.y), Vector2(size.x, size.y - land_top_left.y))
	draw_rect(land_rect, color_land, true)
	
	# Shoreline foam line
	draw_line(Vector2(0, land_top_left.y), Vector2(size.x, land_top_left.y), Color(0.85, 0.95, 0.9, 0.6), 2.0)

	# Draw Dock (X: -1.6 to 1.6, Z: -11 to 4)
	var d_p1: Vector2 = to_map.call(-1.6, -11.0)
	var d_p2: Vector2 = to_map.call(1.6, 4.0)
	var dock_rect: Rect2 = Rect2(d_p1, d_p2 - d_p1)
	draw_rect(dock_rect, color_dock, true)
	draw_rect(dock_rect, Color(0.25, 0.18, 0.12), false, 1.5)

	# Draw Metroidvania Grid Lines
	var grid_step: float = 10.0 * map_scale
	var ox: float = fmod(center.x - p_pos.x * map_scale, grid_step)
	var oy: float = fmod(center.y - p_pos.z * map_scale, grid_step)
	
	for gx in range(-2, int(size.x / grid_step) + 3):
		var x_pos: float = ox + gx * grid_step
		draw_line(Vector2(x_pos, 0), Vector2(x_pos, size.y), color_grid, 1.0)
	for gy in range(-2, int(size.y / grid_step) + 3):
		var y_pos: float = oy + gy * grid_step
		draw_line(Vector2(0, y_pos), Vector2(size.x, y_pos), color_grid, 1.0)

	# Draw Lure (if active in the water)
	if lure and is_instance_valid(lure) and lure.visible:
		var l_map: Vector2 = to_map.call(lure.global_position.x, lure.global_position.z)
		var pulse_radius: float = 4.0 + sin(pulse_time) * 1.5
		draw_circle(l_map, pulse_radius + 2.0, Color(color_lure.r, color_lure.g, color_lure.b, 0.35))
		draw_circle(l_map, 3.5, color_lure)
		
		# Line between player and lure on radar
		draw_line(center, l_map, Color(0.9, 0.95, 1.0, 0.4), 1.0)

	# Draw Player Blip (Arrowhead pointing in view direction)
	var cam_yaw: float = 0.0
	var cam = player.get_node_or_null("Camera3D")
	if cam:
		cam_yaw = player.rotation.y
	
	var dir: Vector2 = Vector2(sin(-cam_yaw), -cos(-cam_yaw)).normalized()
	var right: Vector2 = Vector2(-dir.y, dir.x)
	var arrow_size: float = 7.0
	
	var p_tip: Vector2 = center + dir * arrow_size
	var p_left: Vector2 = center - dir * (arrow_size * 0.6) - right * (arrow_size * 0.6)
	var p_right: Vector2 = center - dir * (arrow_size * 0.6) + right * (arrow_size * 0.6)
	
	var arrow_points: PackedVector2Array = [p_tip, p_left, center, p_right]
	draw_colored_polygon(arrow_points, color_player)
	
	# Radar Border
	draw_arc(center, radius, 0, TAU, 32, Color(0.7, 0.85, 0.9, 0.8), 2.5)
