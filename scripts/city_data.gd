class_name CityData
extends RefCounted

const F = preload("res://scripts/level_factory.gd")
const VehicleScript = preload("res://scripts/vehicle.gd")
const CITY_SIZE := 140.0

static func build(root: Node3D, game: Node) -> Dictionary:
	F.box(root, Vector3(0, -0.3, 0), Vector3(CITY_SIZE, 0.6, CITY_SIZE), Color("354c3f"))
	_roads(root)
	_building(root, Vector3(-27, 0, 27), Vector3(20, 7, 18), Color("8b8174"), "ДОМ ЕВГЕНИЯ / HOME", "city_home", "ACT_HOME")
	_building(root, Vector3(-46, 0, 27), Vector3(10, 4, 12), Color("606d70"), "ГАРАЖ / GARAGE")
	_building(root, Vector3(27, 0, -27), Vector3(24, 12, 20), Color("75858a"), "АРХИТЕКТУРНОЕ БЮРО", "mission_0", "ACT_MISSION_0")
	_building(root, Vector3(-27, 0, -27), Vector3(26, 18, 20), Color("3c626e"), "ВОСТОК НЕЙРО", "mission_1", "ACT_MISSION_1")
	_building(root, Vector3(27, 0, 27), Vector3(28, 9, 20), Color("354b5a"), "ГОРОДСКОЙ РЕЗЕРВ")
	F.interactable(root, Vector3(20, 1.1, 37.15), "mission_2", "ACT_MISSION_2", 0, Color("3d9d79"), Vector3(2.0, 2.3, 0.22))
	F.interactable(root, Vector3(34, 1.1, 37.15), "mission_3", "ACT_MISSION_3", 0, Color("66558c"), Vector3(2.0, 2.3, 0.22))
	F.sign_text(root, Vector3(20, 2.75, 37.3), "ДАТА-ЦЕНТР / 03", Color("9bd9ff"))
	F.sign_text(root, Vector3(34, 2.75, 37.3), "ЯДРО / CORE 04", Color("d4b5ff"))
	for entry in [
		[Vector3(-13, 0, 14), Vector3(8, 5, 8)],
		[Vector3(47, 0, -13), Vector3(9, 6, 9)],
		[Vector3(-46, 0, -8), Vector3(10, 5, 8)],
		[Vector3(9, 0, 47), Vector3(8, 4, 10)]
	]:
		_building(root, entry[0], entry[1], Color("56666a"))
	for pos in [Vector3(-12, 0, -10), Vector3(12, 0, 12), Vector3(-13, 0, 48), Vector3(48, 0, 13), Vector3(-48, 0, 47), Vector3(48, 0, -48), Vector3(12, 0, -48), Vector3(-48, 0, -48)]:
		_streetlight(root, pos)
	for pos in [Vector3(-9, 0, 22), Vector3(9, 0, -22), Vector3(-40, 0, 11), Vector3(43, 0, 42), Vector3(-12, 0, -44), Vector3(13, 0, 43), Vector3(-43, 0, -44), Vector3(45, 0, -42)]:
		_tree(root, pos)
	for side in [-1.0, 1.0]:
		F.box(root, Vector3(side * 69.5, 0.65, 0), Vector3(1, 1.3, CITY_SIZE), Color("53605c"))
		F.box(root, Vector3(0, 0.65, side * 69.5), Vector3(CITY_SIZE, 1.3, 1), Color("53605c"))
	var vehicle := VehicleScript.new()
	vehicle.position = Vector3(-46, 0.65, 41)
	vehicle.rotation.y = PI
	vehicle.game = game
	root.add_child(vehicle)
	return {
		"spawn": Vector3(-37, 0.1, 40),
		"capture": Vector3(-37, 0.1, 45),
		"capture_yaw": -0.4,
		"checkpoints": [Vector3(-37, 0.1, 40)],
		"rooms": [
			_rect(-37, 18, 20, 18), _rect(-51, 21, 10, 12),
			_rect(15, -37, 24, 20), _rect(-40, -37, 26, 20), _rect(13, 17, 28, 20)
		],
		"points": [
			_point(-27, 36, "POINT_HOME"), _point(-46, 38, "POINT_GARAGE"),
			_point(27, -17, "POINT_BUREAU"), _point(-27, -17, "POINT_VOSTOK"),
			_point(20, 37, "POINT_DATACENTER"), _point(34, 37, "POINT_CORE")
		],
		"vehicle": vehicle
	}

static func _roads(root: Node3D) -> void:
	for x in [-55.0, 0.0, 55.0]:
		F.box(root, Vector3(x, 0.012, 0), Vector3(11, 0.024, 136), Color("30383d"), false)
		for z in range(-64, 65, 8):
			F.box(root, Vector3(x, 0.03, z), Vector3(0.16, 0.018, 3.6), Color("c5b978"), false)
	for z in [-55.0, 0.0, 55.0]:
		F.box(root, Vector3(0, 0.014, z), Vector3(136, 0.028, 11), Color("30383d"), false)
		for x in range(-64, 65, 8):
			F.box(root, Vector3(x, 0.032, z), Vector3(3.6, 0.018, 0.16), Color("c5b978"), false)
	for side in [-1.0, 1.0]:
		F.box(root, Vector3(side * 6.2, 0.035, 0), Vector3(1.2, 0.07, 136), Color("8a8d86"), false)
		F.box(root, Vector3(0, 0.035, side * 6.2), Vector3(136, 0.07, 1.2), Color("8a8d86"), false)

static func _building(root: Node3D, pos: Vector3, dimensions: Vector3, color: Color, title: String = "", action: String = "", caption: String = "") -> void:
	F.box(root, Vector3(pos.x, 0.025, pos.z), Vector3(dimensions.x + 3, 0.05, dimensions.z + 3), Color("85877f"), false)
	F.box(root, pos + Vector3(0, dimensions.y * 0.5, 0), dimensions, color)
	F.box(root, pos + Vector3(0, dimensions.y + 0.18, 0), Vector3(dimensions.x + 0.5, 0.36, dimensions.z + 0.5), color.darkened(0.25))
	var front_z := pos.z + dimensions.z * 0.5 + 0.025
	for y in range(3, int(dimensions.y), 3):
		for x in [-dimensions.x * 0.31, 0.0, dimensions.x * 0.31]:
			F.box(root, Vector3(pos.x + x, y, front_z), Vector3(1.7, 1.25, 0.045), Color("8bb9c0"), false, 0.28)
	for side in [-1.0, 1.0]:
		for y in range(3, int(dimensions.y), 3):
			for z in [-dimensions.z * 0.27, dimensions.z * 0.27]:
				F.box(root, Vector3(pos.x + side * (dimensions.x * 0.5 + 0.025), y, pos.z + z), Vector3(0.045, 1.25, 1.6), Color("759ea6"), false, 0.2)
	if not action.is_empty():
		F.interactable(root, Vector3(pos.x, 1.1, front_z + 0.12), action, caption, 0, Color("3d9d79"), Vector3(2.0, 2.3, 0.22))
	if not title.is_empty():
		F.sign_text(root, Vector3(pos.x, 2.85, front_z + 0.17), title, Color("d4eeee"))

static func _streetlight(root: Node3D, pos: Vector3) -> void:
	F.cylinder(root, pos + Vector3(0, 2.6, 0), 0.09, 5.2, Color("35434a"))
	F.box(root, pos + Vector3(0, 5.15, 0), Vector3(0.65, 0.12, 0.35), Color("ffe0a3"), false, 1.2)
	F.light(root, pos + Vector3(0, 4.9, 0), Color("ffd79a"), 0.8, 10.0)

static func _tree(root: Node3D, pos: Vector3) -> void:
	F.cylinder(root, pos + Vector3(0, 1.1, 0), 0.18, 2.2, Color("594b39"))
	var crown := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.55
	mesh.height = 3.1
	mesh.radial_segments = 12
	mesh.rings = 6
	crown.mesh = mesh
	crown.material_override = F.material(Color("426b4b"))
	crown.position = pos + Vector3(0, 3.0, 0)
	root.add_child(crown)

static func _rect(x: float, z: float, width: float, depth: float) -> Rect2:
	return Rect2(x + CITY_SIZE * 0.5, z + CITY_SIZE * 0.5, width, depth)

static func _point(x: float, z: float, label: String) -> Dictionary:
	return {"x": x + CITY_SIZE * 0.5, "z": z + CITY_SIZE * 0.5, "label": label}
