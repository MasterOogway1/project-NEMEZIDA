class_name CityData
extends RefCounted

const F = preload("res://scripts/level_factory.gd")
const VehicleScript = preload("res://scripts/vehicle.gd")
const CITY_SIZE := 140.0
const SUBURBAN := "res://assets/models/city/suburban/"
const COMMERCIAL := "res://assets/models/city/commercial/"
const ROADS := "res://assets/models/city/roads/"
const VEHICLES := "res://assets/models/vehicles/"

static func build(root: Node3D, game: Node) -> Dictionary:
	F.box(root, Vector3(0, -0.3, 0), Vector3(CITY_SIZE, 0.6, CITY_SIZE), Color("4d674c"))
	_roads(root)
	_building(root, Vector3(-27, 0, 27), SUBURBAN + "building-type-s.glb", 8.0, "ДОМ ЕВГЕНИЯ / HOME", "city_home", "ACT_HOME")
	_building(root, Vector3(-46, 0, 27), SUBURBAN + "building-type-q.glb", 4.5, "ГАРАЖ / GARAGE")
	_building(root, Vector3(27, 0, -27), COMMERCIAL + "building-a.glb", 12.0, "АРХИТЕКТУРНОЕ БЮРО", "mission_0", "ACT_MISSION_0")
	_building(root, Vector3(-27, 0, -27), COMMERCIAL + "building-skyscraper-a.glb", 22.0, "ВОСТОК НЕЙРО", "mission_1", "ACT_MISSION_1")
	var data_center := _building(root, Vector3(27, 0, 27), COMMERCIAL + "building-n.glb", 10.0, "ГОРОДСКОЙ РЕЗЕРВ")
	var data_size := F.model_bounds(data_center, Transform3D.IDENTITY).size
	var data_front := 27.0 + data_size.z * 0.5 + 0.18
	_door(root, Vector3(22, 1.1, data_front), "mission_2", "ACT_MISSION_2", "ДАТА-ЦЕНТР / 03")
	_door(root, Vector3(32, 1.1, data_front), "mission_3", "ACT_MISSION_3", "ЯДРО / CORE 04")
	_building(root, Vector3(-13, 0, 14), SUBURBAN + "building-type-k.glb", 6.0)
	_building(root, Vector3(47, 0, -13), COMMERCIAL + "building-a.glb", 7.0)
	_building(root, Vector3(-46, 0, -8), SUBURBAN + "building-type-a.glb", 5.0)
	_building(root, Vector3(9, 0, 47), COMMERCIAL + "building-b.glb", 7.0)
	for pos in [Vector3(-12, 0, -10), Vector3(12, 0, 12), Vector3(-13, 0, 48), Vector3(48, 0, 13), Vector3(-48, 0, 47), Vector3(48, 0, -48), Vector3(12, 0, -48), Vector3(-48, 0, -48)]:
		_streetlight(root, pos)
	for pos in [Vector3(-9, 0, 22), Vector3(9, 0, -22), Vector3(-40, 0, 11), Vector3(43, 0, 42), Vector3(-12, 0, -44), Vector3(13, 0, 43), Vector3(-43, 0, -44), Vector3(45, 0, -42)]:
		_tree(root, pos)
	_street_details(root)
	_parked_car(root, VEHICLES + "taxi.glb", Vector3(3.8, 0.04, 18), 0.0)
	_parked_car(root, VEHICLES + "suv.glb", Vector3(51.2, 0.04, -18), PI)
	_parked_car(root, VEHICLES + "sedan.glb", Vector3(-18, 0.04, 51.2), PI * 0.5)
	_boundaries(root)
	var vehicle := VehicleScript.new()
	vehicle.position = Vector3(-46, 0.65, 37)
	vehicle.rotation.y = PI
	vehicle.game = game
	root.add_child(vehicle)
	return {
		"spawn": Vector3(-37, 0.1, 38),
		"capture": Vector3(12, 0.1, 12),
		"capture_yaw": 0.75,
		"checkpoints": [Vector3(-37, 0.1, 38)],
		"rooms": [
			_rect(-34, 20, 14, 14), _rect(-51, 22, 10, 10),
			_rect(21, -33, 12, 12), _rect(-33, -33, 12, 12), _rect(18, 18, 18, 18)
		],
		"points": [
			_point(-27, 34, "POINT_HOME"), _point(-46, 34, "POINT_GARAGE"),
			_point(27, -21, "POINT_BUREAU"), _point(-27, -21, "POINT_VOSTOK"),
			_point(22, 36, "POINT_DATACENTER"), _point(32, 36, "POINT_CORE")
		],
		"vehicle": vehicle
	}

static func _roads(root: Node3D) -> void:
	var centers := range(-66, 67, 11)
	for x in [-55.0, 0.0, 55.0]:
		for z in centers:
			var intersection: bool = z in [-55, 0, 55]
			_road_tile(root, "road-crossroad.glb" if intersection else "road-straight.glb", Vector3(x, 0.02, z))
	for z in [-55.0, 0.0, 55.0]:
		for x in centers:
			if x in [-55, 0, 55]:
				continue
			_road_tile(root, "road-straight.glb", Vector3(x, 0.02, z), PI * 0.5)

static func _road_tile(root: Node3D, filename: String, pos: Vector3, yaw: float = 0.0) -> void:
	var tile: Node3D = load(ROADS + filename).instantiate()
	tile.position = pos
	tile.rotation.y = yaw
	tile.scale = Vector3(11, 1, 11)
	root.add_child(tile)

static func _building(root: Node3D, pos: Vector3, path: String, height: float, title: String = "", action: String = "", caption: String = "") -> Node3D:
	var model := F.imported_model(root, path, pos, height)
	var bounds := F.model_bounds(model, Transform3D.IDENTITY)
	F.furniture_collision(root, pos + Vector3(0, bounds.size.y * 0.5, 0), bounds.size)
	if not title.is_empty() or not action.is_empty():
		var front_z := pos.z + bounds.size.z * 0.5 + 0.18
		F.imported_model(root, SUBURBAN + "path-short.glb", Vector3(pos.x, 0.04, front_z + 0.8), 0.08)
		_door(root, Vector3(pos.x, 1.1, front_z), action, caption, title)
	return model

static func _door(root: Node3D, pos: Vector3, action: String, caption: String, title: String) -> void:
	if not action.is_empty():
		var item := F.interactable(root, pos, action, caption, 0, Color("3d9d79"), Vector3(2.0, 2.3, 0.22))
		_hide_meshes(item)
	if not title.is_empty():
		F.sign_text(root, pos + Vector3(0, 1.75, 0.12), title, Color("d4eeee"))

static func _hide_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		node.hide()
	for child in node.get_children():
		_hide_meshes(child)

static func _streetlight(root: Node3D, pos: Vector3) -> void:
	F.imported_model(root, ROADS + "light-curved.glb", pos, 5.2)
	F.light(root, pos + Vector3(0, 4.8, 0), Color("ffd79a"), 0.65, 10.0)

static func _tree(root: Node3D, pos: Vector3) -> void:
	F.imported_model(root, SUBURBAN + "tree-large.glb", pos, 4.5)

static func _street_details(root: Node3D) -> void:
	for entry in [
		[Vector3(-6.3, 0, -6.3), 0.0], [Vector3(6.3, 0, 6.3), PI],
		[Vector3(-6.3, 0, 6.3), PI * 0.5], [Vector3(6.3, 0, -6.3), -PI * 0.5]
	]:
		F.imported_model(root, ROADS + "road-sign-stop.glb", entry[0], 2.2, entry[1])
	F.imported_model(root, ROADS + "traffic-light.glb", Vector3(6.5, 0, 5.5), 3.8, PI)
	F.imported_model(root, ROADS + "traffic-light.glb", Vector3(-6.5, 0, -5.5), 3.8)
	F.imported_model(root, ROADS + "dumpster.glb", Vector3(36, 0, -24), 1.4)
	F.imported_model(root, ROADS + "dumpster.glb", Vector3(-36, 0, -25), 1.4)
	F.imported_model(root, SUBURBAN + "planter.glb", Vector3(-22, 0, 34), 0.8)
	F.imported_model(root, SUBURBAN + "driveway-short.glb", Vector3(-46, 0.04, 34), 0.08)
	F.imported_model(root, ROADS + "construction-barrier.glb", Vector3(54, 0, 42), 1.1, PI * 0.5)

static func _parked_car(root: Node3D, path: String, pos: Vector3, yaw: float) -> void:
	var model := F.imported_model(root, path, pos, 1.15, yaw)
	var size := F.model_bounds(model, Transform3D.IDENTITY).size
	if absf(yaw) > 0.1:
		size = Vector3(size.z, size.y, size.x)
	F.furniture_collision(root, pos + Vector3(0, size.y * 0.5, 0), size)

static func _boundaries(root: Node3D) -> void:
	for side in [-1.0, 1.0]:
		F.furniture_collision(root, Vector3(side * 69.0, 0.65, 0), Vector3(1, 1.3, CITY_SIZE))
		F.furniture_collision(root, Vector3(0, 0.65, side * 69.0), Vector3(CITY_SIZE, 1.3, 1))
	for coordinate in range(-66, 67, 6):
		F.imported_model(root, SUBURBAN + "fence-1x4.glb", Vector3(-68, 0, coordinate), 1.3, PI * 0.5)
		F.imported_model(root, SUBURBAN + "fence-1x4.glb", Vector3(68, 0, coordinate), 1.3, PI * 0.5)
		F.imported_model(root, SUBURBAN + "fence-1x4.glb", Vector3(coordinate, 0, -68), 1.3)
		F.imported_model(root, SUBURBAN + "fence-1x4.glb", Vector3(coordinate, 0, 68), 1.3)

static func _rect(x: float, z: float, width: float, depth: float) -> Rect2:
	return Rect2(x + CITY_SIZE * 0.5, z + CITY_SIZE * 0.5, width, depth)

static func _point(x: float, z: float, label: String) -> Dictionary:
	return {"x": x + CITY_SIZE * 0.5, "z": z + CITY_SIZE * 0.5, "label": label}
