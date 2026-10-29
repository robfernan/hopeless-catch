extends MeshInstance3D
class_name FishingLine

@export var rod_tip: Node3D
@export var lure: Node3D
@export var segments: int = 16
@export var line_color: Color = Color(0.85, 0.9, 0.95, 0.7)

var immediate_mesh: ImmediateMesh
var material: StandardMaterial3D

func _ready() -> void:
	immediate_mesh = ImmediateMesh.new()
	mesh = immediate_mesh
	
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = line_color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material_override = material

func _process(_delta: float) -> void:
	immediate_mesh.clear_surfaces()
	if not rod_tip or not lure or not is_instance_valid(rod_tip) or not is_instance_valid(lure):
		return
	if not lure.visible:
		return

	var cam := get_viewport().get_camera_3d()
	var width := 0.012
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var point := _sag_point(t)
		var ahead := _sag_point(minf(t + 0.04, 1.0))
		var tangent := ahead - point
		if tangent.length_squared() < 0.000001:
			tangent = Vector3.FORWARD
		else:
			tangent = tangent.normalized()
		var view := Vector3.UP
		if cam:
			view = cam.global_position - point
		var side := tangent.cross(view)
		if side.length_squared() < 0.000001:
			side = tangent.cross(Vector3.UP)
		side = side.normalized() * width
		immediate_mesh.surface_add_vertex(to_local(point - side))
		immediate_mesh.surface_add_vertex(to_local(point + side))
	immediate_mesh.surface_end()

func _sag_point(t: float) -> Vector3:
	var p_start := rod_tip.global_position
	var p_end := lure.global_position
	var dist := p_start.distance_to(p_end)
	var max_droop := clampf(dist * 0.12, 0.05, 1.8)
	var mid_point := (p_start + p_end) * 0.5
	mid_point.y -= max_droop
	var p0 := p_start.lerp(mid_point, t)
	var p1 := mid_point.lerp(p_end, t)
	return p0.lerp(p1, t)
