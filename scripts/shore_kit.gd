extends Node3D
## Procedural shore dressing. Dock collision stays on the Dock node.

func _ready() -> void:
	_pine(Vector3(-14.0, 0.92, 16.0), 1.0)
	_pine(Vector3(-7.0, 0.92, 24.0), 1.25)
	_pine(Vector3(9.0, 0.92, 18.0), 0.9)
	_pine(Vector3(18.0, 0.92, 14.0), 1.15)
	_rock(Vector3(-5.5, 0.95, 6.5), 1.1)
	_rock(Vector3(4.2, 0.95, 7.0), 0.8)
	_rock(Vector3(12.0, 0.95, 8.5), 1.3)
	_cabin(Vector3(-16.0, 0.92, 22.0))
	_pumpkin(Vector3(-12.4, 0.92, 12.0))
	_pumpkin(Vector3(2.2, 0.92, 9.5))
	_pumpkin(Vector3(8.6, 0.92, 13.2))
	_plank_seams.call_deferred()

func _flat(hex: String) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(hex)
	mat.roughness = 1.0
	mat.metallic = 0.0
	return mat

func _add_mesh(parent: Node, mesh: Mesh, pos: Vector3, node_name: String) -> void:
	var inst := MeshInstance3D.new()
	inst.name = node_name
	inst.mesh = mesh
	inst.position = pos
	parent.add_child(inst)

func _pine(base: Vector3, scale: float) -> void:
	var root := Node3D.new()
	root.name = "Pine"
	root.position = base
	root.scale = Vector3.ONE * scale
	add_child(root)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.16
	trunk.bottom_radius = 0.26
	trunk.height = 1.5
	trunk.material = _flat("2A2018")
	_add_mesh(root, trunk, Vector3(0, 0.75, 0), "Trunk")
	for i in 3:
		var tier := CylinderMesh.new()
		tier.top_radius = 0.04
		tier.bottom_radius = 1.35 - float(i) * 0.32
		tier.height = 1.05
		tier.radial_segments = 6
		tier.material = _flat("1E4A52")
		_add_mesh(root, tier, Vector3(0, 1.7 + float(i) * 0.72, 0), "Tier%d" % i)

func _rock(pos: Vector3, scale: float) -> void:
	var rock := BoxMesh.new()
	rock.size = Vector3(1.4, 0.7, 1.1) * scale
	rock.material = _flat("B8A090")
	_add_mesh(self, rock, pos, "Rock")

func _cabin(origin: Vector3) -> void:
	var root := Node3D.new()
	root.name = "BaitShopBlockout"
	root.position = origin
	add_child(root)
	var body := BoxMesh.new()
	body.size = Vector3(4.2, 2.4, 3.4)
	body.material = _flat("D4C8B0")
	_add_mesh(root, body, Vector3(0, 1.2, 0), "Walls")
	var roof := BoxMesh.new()
	roof.size = Vector3(4.8, 0.35, 4.0)
	roof.material = _flat("2A2018")
	_add_mesh(root, roof, Vector3(0, 2.55, 0), "Roof")
	var window := BoxMesh.new()
	window.size = Vector3(0.7, 0.7, 0.08)
	var glow := _flat("E07828")
	glow.emission_enabled = true
	glow.emission = Color("E07828")
	glow.emission_energy_multiplier = 0.6
	window.material = glow
	_add_mesh(root, window, Vector3(0, 1.35, 1.72), "Window")

func _pumpkin(pos: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Pumpkin"
	root.position = pos
	add_child(root)
	var body := SphereMesh.new()
	body.radius = 0.38
	body.height = 0.62
	body.radial_segments = 8
	body.rings = 4
	var skin := _flat("E07828")
	skin.emission_enabled = true
	skin.emission = Color("E07828")
	skin.emission_energy_multiplier = 0.15
	body.material = skin
	_add_mesh(root, body, Vector3(0, 0.32, 0), "Body")
	var stem := CylinderMesh.new()
	stem.top_radius = 0.05
	stem.bottom_radius = 0.07
	stem.height = 0.16
	stem.radial_segments = 5
	stem.material = _flat("2A2018")
	_add_mesh(root, stem, Vector3(0, 0.68, 0), "Stem")

func _plank_seams() -> void:
	var dock := get_parent().get_node_or_null("Dock")
	if dock == null:
		return
	for i in 9:
		var seam := BoxMesh.new()
		seam.size = Vector3(3.05, 0.03, 0.08)
		seam.material = _flat("B8A090")
		_add_mesh(dock, seam, Vector3(0, 0.19, -6.4 + float(i) * 1.6), "PlankSeam%d" % i)
