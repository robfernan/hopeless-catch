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
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_override = material

func _process(_delta: float) -> void:
	if not rod_tip or not lure or not is_instance_valid(rod_tip) or not is_instance_valid(lure):
		immediate_mesh.clear_surfaces()
		return
	
	if not lure.visible:
		immediate_mesh.clear_surfaces()
		return

	var p_start: Vector3 = rod_tip.global_position
	var p_end: Vector3 = lure.global_position
	
	# Calculate slack / droop based on distance
	var dist: float = p_start.distance_to(p_end)
	var max_droop: float = clampf(dist * 0.12, 0.05, 1.8)
	
	# If reeling in tight, reduce droop
	var mid_point: Vector3 = (p_start + p_end) * 0.5
	mid_point.y -= max_droop
	
	immediate_mesh.clear_surfaces()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		# Quadratic bezier curve for natural sag
		var p0: Vector3 = p_start.lerp(mid_point, t)
		var p1: Vector3 = mid_point.lerp(p_end, t)
		var point: Vector3 = p0.lerp(p1, t)
		
		# Convert to local mesh coordinates
		var local_point: Vector3 = to_local(point)
		immediate_mesh.surface_add_vertex(local_point)
		
	immediate_mesh.surface_end()
