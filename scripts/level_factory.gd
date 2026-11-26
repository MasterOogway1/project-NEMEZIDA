class_name LevelFactory
extends RefCounted

const InteractableScript = preload("res://scripts/interactable.gd")
const GuardScript = preload("res://scripts/guard.gd")
const CameraScript = preload("res://scripts/security_camera.gd")

static func material(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.82
	if emission > 0.0:
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = emission
	return result

static func box(parent: Node3D, pos: Vector3, dimensions: Vector3, color: Color, solid: bool = true, emission: float = 0.0) -> Node3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material(color, emission)
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = pos
		body.add_child(mesh_instance)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = dimensions
		collision.shape = shape
		body.add_child(collision)
		parent.add_child(body)
		return body
	mesh_instance.position = pos
	parent.add_child(mesh_instance)
	return mesh_instance

static func light(parent: Node3D, pos: Vector3, color: Color = Color("b9e5e6"), energy: float = 1.1, radius: float = 9.0) -> OmniLight3D:
	var lamp := OmniLight3D.new()
	lamp.position = pos
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.omni_range = radius
	parent.add_child(lamp)
	return lamp

static func interactable(parent: Node3D, pos: Vector3, action_id: String, caption_key: String, access: int = 0, color: Color = Color("276879"), dimensions: Vector3 = Vector3(0.8, 1.0, 0.35)) -> StaticBody3D:
	var item := InteractableScript.new()
	item.position = pos
	item.action_id = action_id
	item.caption_key = caption_key
	item.required_access = access
	item.collision_layer = 1
	item.collision_mask = 0
	item.add_to_group("interactable")
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material(color, 0.35)
	item.add_child(mesh_instance)
	item.mesh = mesh_instance
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	item.add_child(collision)
	parent.add_child(item)
	return item

static func guard(parent: Node3D, pos: Vector3, route: Array[Vector3], game: Node) -> CharacterBody3D:
	var guard := GuardScript.new()
	guard.position = pos
	guard.patrol = route
	guard.game = game
	parent.add_child(guard)
	return guard

static func security_camera(parent: Node3D, pos: Vector3, yaw: float, game: Node) -> Node3D:
	var camera := CameraScript.new()
	camera.position = pos
	camera.base_yaw = yaw
	camera.game = game
	parent.add_child(camera)
	return camera

static func wall_x(parent: Node3D, z: float, start_x: float, end_x: float, color: Color, gap_center: float = 999.0, gap_width: float = 0.0) -> void:
	if gap_center < 900.0:
		var left_end := gap_center - gap_width * 0.5
		var right_start := gap_center + gap_width * 0.5
		if left_end > start_x:
			box(parent, Vector3((start_x + left_end) * 0.5, 1.6, z), Vector3(left_end - start_x, 3.2, 0.22), color)
		if right_start < end_x:
			box(parent, Vector3((right_start + end_x) * 0.5, 1.6, z), Vector3(end_x - right_start, 3.2, 0.22), color)
	else:
		box(parent, Vector3((start_x + end_x) * 0.5, 1.6, z), Vector3(end_x - start_x, 3.2, 0.22), color)

static func wall_z(parent: Node3D, x: float, start_z: float, end_z: float, color: Color, gap_center: float = 999.0, gap_width: float = 0.0) -> void:
	if gap_center < 900.0:
		var near_end := gap_center - gap_width * 0.5
		var far_start := gap_center + gap_width * 0.5
		if near_end > start_z:
			box(parent, Vector3(x, 1.6, (start_z + near_end) * 0.5), Vector3(0.22, 3.2, near_end - start_z), color)
		if far_start < end_z:
			box(parent, Vector3(x, 1.6, (far_start + end_z) * 0.5), Vector3(0.22, 3.2, end_z - far_start), color)
	else:
		box(parent, Vector3(x, 1.6, (start_z + end_z) * 0.5), Vector3(0.22, 3.2, end_z - start_z), color)

static func desk(parent: Node3D, pos: Vector3, color: Color = Color("6e6258")) -> void:
	box(parent, pos + Vector3(0, 0.72, 0), Vector3(2.0, 0.12, 0.9), color)
	for x in [-0.82, 0.82]:
		for z in [-0.32, 0.32]:
			box(parent, pos + Vector3(x, 0.35, z), Vector3(0.1, 0.7, 0.1), color)

static func server(parent: Node3D, pos: Vector3, color: Color = Color("172c3b")) -> void:
	box(parent, pos + Vector3(0, 1.1, 0), Vector3(1.0, 2.2, 0.85), color)
	for y in [0.45, 0.85, 1.25, 1.65]:
		box(parent, pos + Vector3(0, y, -0.44), Vector3(0.7, 0.045, 0.025), Color("58c7cf"), false, 1.3)

static func plant(parent: Node3D, pos: Vector3) -> void:
	box(parent, pos + Vector3(0, 0.3, 0), Vector3(0.55, 0.6, 0.55), Color("66534a"))
	box(parent, pos + Vector3(0, 0.95, 0), Vector3(0.8, 0.85, 0.8), Color("356c59"), false)

static func sign_text(parent: Node3D, pos: Vector3, text: String, color: Color = Color("bcecef")) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.font_size = 48
	label.pixel_size = 0.007
	label.modulate = color
	label.outline_size = 4
	parent.add_child(label)
	return label

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, emission: float = 0.0) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material(color, emission)
	mesh_instance.position = pos
	parent.add_child(mesh_instance)
	return mesh_instance

static func floor_zone(parent: Node3D, pos: Vector3, dimensions: Vector2, color: Color) -> void:
	box(parent, Vector3(pos.x, 0.012, pos.z), Vector3(dimensions.x, 0.02, dimensions.y), color, false, 0.08)
	var border := color.lightened(0.28)
	for x in [-dimensions.x * 0.5, dimensions.x * 0.5]:
		box(parent, Vector3(pos.x + x, 0.025, pos.z), Vector3(0.055, 0.025, dimensions.y), border, false, 0.25)
	for z in [-dimensions.y * 0.5, dimensions.y * 0.5]:
		box(parent, Vector3(pos.x, 0.025, pos.z + z), Vector3(dimensions.x, 0.025, 0.055), border, false, 0.25)

static func monitor(parent: Node3D, pos: Vector3, yaw: float = 0.0, color: Color = Color("55c8d4")) -> void:
	var display := Node3D.new()
	display.position = pos
	display.rotation.y = yaw
	parent.add_child(display)
	box(display, Vector3(0, 0.34, 0), Vector3(0.95, 0.58, 0.09), Color("17232c"), false)
	box(display, Vector3(0, 0.34, -0.052), Vector3(0.82, 0.44, 0.018), color, false, 0.75)
	box(display, Vector3(0, 0.04, 0), Vector3(0.08, 0.2, 0.08), Color("263945"), false)
	box(display, Vector3(0, -0.05, 0), Vector3(0.42, 0.04, 0.28), Color("263945"), false)
	for line in [-0.12, 0.0, 0.12]:
		box(display, Vector3(-0.08, 0.34 + line, -0.065), Vector3(0.48, 0.018, 0.012), Color("d0f4ee"), false, 0.6)

static func bench(parent: Node3D, pos: Vector3, color: Color, yaw: float = 0.0) -> void:
	var seat := Node3D.new()
	seat.position = pos
	seat.rotation.y = yaw
	parent.add_child(seat)
	box(seat, Vector3(0, 0.48, 0), Vector3(2.2, 0.16, 0.65), color)
	box(seat, Vector3(0, 0.86, 0.28), Vector3(2.2, 0.65, 0.12), color)
	for x in [-0.82, 0.82]:
		box(seat, Vector3(x, 0.22, 0), Vector3(0.12, 0.45, 0.5), Color("24333c"))

static func architectural_model(parent: Node3D, pos: Vector3) -> void:
	box(parent, pos + Vector3(0, 0.79, 0), Vector3(1.35, 0.05, 0.7), Color("d7cfb5"), false)
	for entry in [[-0.43, 0.26, 0.2], [0.0, 0.42, -0.12], [0.4, 0.2, 0.14]]:
		var height: float = entry[1]
		box(parent, pos + Vector3(entry[0], 0.82 + height * 0.5, entry[2]), Vector3(0.28, height, 0.25), Color("eee4c9"), false)
		box(parent, pos + Vector3(entry[0], 0.85 + height * 0.5, entry[2] - 0.13), Vector3(0.17, 0.035, 0.015), Color("73a7ad"), false, 0.25)

static func cable_tray(parent: Node3D, z: float, color: Color) -> void:
	for x in [-1.0, 1.0]:
		box(parent, Vector3(0, 2.95, z + x * 0.18), Vector3(27, 0.12, 0.08), color, false)
	for x in range(-13, 14, 2):
		box(parent, Vector3(x, 2.95, z), Vector3(0.08, 0.08, 0.45), color.darkened(0.2), false)

static func core_pylon(parent: Node3D, pos: Vector3, color: Color) -> void:
	cylinder(parent, pos + Vector3(0, 0.12, 0), 0.65, 0.24, Color("252b42"))
	cylinder(parent, pos + Vector3(0, 1.25, 0), 0.24, 2.3, color, 0.65)
	for y in [0.45, 1.15, 1.85, 2.4]:
		cylinder(parent, pos + Vector3(0, y, 0), 0.48, 0.09, color.lightened(0.2), 0.85)
