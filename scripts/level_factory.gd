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

static func textured_material(folder: String, basename: String, tint: Color, tiling: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = tint
	result.albedo_texture = load("res://assets/materials/%s/%s_Color.jpg" % [folder, basename])
	result.normal_enabled = true
	result.normal_texture = load("res://assets/materials/%s/%s_NormalGL.jpg" % [folder, basename])
	result.roughness_texture = load("res://assets/materials/%s/%s_Roughness.jpg" % [folder, basename])
	result.uv1_scale = Vector3.ONE * tiling
	return result

static func apply_material(node: Node3D, mat: Material) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
	for child in node.get_children():
		if child is MeshInstance3D:
			child.material_override = mat

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
	var collision_dimensions := dimensions
	var panel_actions := ["city_node", "test_node", "security", "distract", "overload", "node_a", "node_b", "node_c", "override", "relay_a", "relay_b"]
	if action_id == "badge":
		imported_model(item, "res://assets/models/props/keycard.glb", Vector3(0, -0.17, 0), 0.34)
		collision_dimensions = Vector3(0.5, 0.4, 0.2)
	elif action_id == "security":
		imported_model(item, "res://assets/models/props/hacking_tablet.glb", Vector3(0, -0.2, 0), 0.035)
		collision_dimensions = Vector3(0.6, 0.25, 0.6)
	elif action_id == "gpu":
		imported_model(item, "res://assets/models/props/nvidia_gpu.glb", Vector3(0, -0.17, 0), 0.34)
		var brand := sign_text(item, Vector3(0, 0.04, -0.065), "NVIDIA\nGEFORCE RTX", Color("9ed36f"), PI)
		brand.font_size = 28
		brand.pixel_size = 0.003
		brand.outline_size = 2
		collision_dimensions = Vector3(0.8, 0.4, 0.25)
	elif action_id in panel_actions:
		imported_model(item, "res://assets/models/props/button.glb", Vector3(0, -0.14, 0), 0.28)
		cylinder(item, Vector3(0, -0.55, 0), 0.12, 0.9, Color("253944"))
		var indicator := MeshInstance3D.new()
		var indicator_mesh := SphereMesh.new()
		indicator_mesh.radius = 0.065
		indicator_mesh.height = 0.13
		indicator.mesh = indicator_mesh
		indicator.position.y = 0.21
		indicator.material_override = material(color, 0.8)
		item.add_child(indicator)
		item.mesh = indicator
		collision_dimensions = Vector3(0.8, 0.5, 0.8)
	else:
		var mesh_instance := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = dimensions
		mesh_instance.mesh = mesh
		mesh_instance.material_override = material(color, 0.35)
		item.add_child(mesh_instance)
		item.mesh = mesh_instance
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = collision_dimensions
	collision.shape = shape
	item.add_child(collision)
	parent.add_child(item)
	return item

static func guard(parent: Node3D, pos: Vector3, route: Array[Vector3], game: Node, variant: String = "swat") -> CharacterBody3D:
	var guard := GuardScript.new()
	guard.position = pos
	guard.patrol = route
	guard.game = game
	guard.variant = variant
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
		wall_piece_x(parent, z, start_x, minf(left_end, end_x), color)
		wall_piece_x(parent, z, maxf(right_start, start_x), end_x, color)
	else:
		wall_piece_x(parent, z, start_x, end_x, color)

static func wall_piece_x(parent: Node3D, z: float, start_x: float, end_x: float, color: Color) -> void:
	var length := end_x - start_x
	if length <= 0.01:
		return
	var center := (start_x + end_x) * 0.5
	box(parent, Vector3(center, 1.6, z), Vector3(length, 3.2, 0.22), color)
	if length < 0.3:
		return
	for side in [-1.0, 1.0]:
		box(parent, Vector3(center, 0.5, z + side * 0.125), Vector3(length, 0.94, 0.025), color.darkened(0.14), false)
		box(parent, Vector3(center, 1.02, z + side * 0.14), Vector3(length, 0.065, 0.035), color.lightened(0.2), false)
		for x in range(int(ceil(start_x)) + 1, int(end_x), 3):
			box(parent, Vector3(x, 0.5, z + side * 0.145), Vector3(0.04, 0.9, 0.035), color.lightened(0.12), false)

static func wall_z(parent: Node3D, x: float, start_z: float, end_z: float, color: Color, gap_center: float = 999.0, gap_width: float = 0.0) -> void:
	if gap_center < 900.0:
		var near_end := gap_center - gap_width * 0.5
		var far_start := gap_center + gap_width * 0.5
		wall_piece_z(parent, x, start_z, minf(near_end, end_z), color)
		wall_piece_z(parent, x, maxf(far_start, start_z), end_z, color)
	else:
		wall_piece_z(parent, x, start_z, end_z, color)

static func wall_piece_z(parent: Node3D, x: float, start_z: float, end_z: float, color: Color) -> void:
	var length := end_z - start_z
	if length <= 0.01:
		return
	var center := (start_z + end_z) * 0.5
	box(parent, Vector3(x, 1.6, center), Vector3(0.22, 3.2, length), color)
	if length < 0.3:
		return
	for side in [-1.0, 1.0]:
		box(parent, Vector3(x + side * 0.125, 0.5, center), Vector3(0.025, 0.94, length), color.darkened(0.14), false)
		box(parent, Vector3(x + side * 0.14, 1.02, center), Vector3(0.035, 0.065, length), color.lightened(0.2), false)
		for z in range(int(ceil(start_z)) + 1, int(end_z), 3):
			box(parent, Vector3(x + side * 0.145, 0.5, z), Vector3(0.035, 0.9, 0.04), color.lightened(0.12), false)

static func desk(parent: Node3D, pos: Vector3, color: Color = Color("6e6258")) -> void:
	imported_model(parent, "res://assets/models/props/standing_desk.glb", pos, 0.78)
	furniture_collision(parent, pos + Vector3(0, 0.39, 0), Vector3(1.0, 0.78, 0.75))
	imported_model(parent, "res://assets/models/props/office_chair.glb", pos + Vector3(0, 0, 1.05), 1.0, PI)

static func furniture_collision(parent: Node3D, pos: Vector3, dimensions: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)

static func server(parent: Node3D, pos: Vector3, color: Color = Color("172c3b")) -> void:
	box(parent, pos + Vector3(0, 1.1, 0), Vector3(1.0, 2.2, 0.85), color)
	for y in [0.45, 0.85, 1.25, 1.65]:
		box(parent, pos + Vector3(0, y, -0.44), Vector3(0.7, 0.045, 0.025), Color("58c7cf"), false, 1.3)

static func plant(parent: Node3D, pos: Vector3) -> void:
	imported_model(parent, "res://assets/models/props/potted_plant.glb", pos, 1.15)

static func sign_text(parent: Node3D, pos: Vector3, text: String, color: Color = Color("bcecef"), yaw: float = 0.0) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.rotation.y = yaw
	label.double_sided = false
	label.font_size = 48
	label.pixel_size = 0.007
	label.modulate = color
	label.outline_size = 4
	parent.add_child(label)
	return label

static func picture(parent: Node3D, pos: Vector3, dimensions: Vector2, texture_path: String, title: String, yaw: float = 0.0) -> void:
	var frame := Node3D.new()
	frame.position = pos
	frame.rotation.y = yaw
	parent.add_child(frame)
	box(frame, Vector3.ZERO, Vector3(dimensions.x + 0.12, dimensions.y + 0.12, 0.07), Color("40352d"), false)
	box(frame, Vector3(0, 0, 0.042), Vector3(dimensions.x + 0.045, dimensions.y + 0.045, 0.018), Color("c0a369"), false)
	var image := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = dimensions
	image.mesh = mesh
	image.position.z = 0.054
	var image_material := StandardMaterial3D.new()
	image_material.albedo_texture = load(texture_path)
	image_material.roughness = 0.88
	image.material_override = image_material
	frame.add_child(image)
	if not title.is_empty():
		var caption := sign_text(frame, Vector3(0, -dimensions.y * 0.5 + 0.1, 0.065), title, Color("e7d7a7"))
		caption.font_size = 20
		caption.pixel_size = 0.0035
		caption.outline_size = 2

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

static func floor_zone(parent: Node3D, pos: Vector3, dimensions: Vector2, color: Color, surface: String = "") -> void:
	box(parent, Vector3(pos.x, 0.012, pos.z), Vector3(dimensions.x, 0.02, dimensions.y), color, false, 0.08)
	var border := color.lightened(0.28)
	for x in [-dimensions.x * 0.5, dimensions.x * 0.5]:
		box(parent, Vector3(pos.x + x, 0.025, pos.z), Vector3(0.055, 0.025, dimensions.y), border, false, 0.25)
	for z in [-dimensions.y * 0.5, dimensions.y * 0.5]:
		box(parent, Vector3(pos.x, 0.025, pos.z + z), Vector3(dimensions.x, 0.025, 0.055), border, false, 0.25)
	if not surface.is_empty():
		var body := StaticBody3D.new()
		body.position = Vector3(pos.x, 0.02, pos.z)
		body.collision_layer = 1
		body.collision_mask = 0
		body.set_meta("surface", surface)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(dimensions.x, 0.04, dimensions.y)
		collision.shape = shape
		body.add_child(collision)
		parent.add_child(body)

static func monitor(parent: Node3D, pos: Vector3, yaw: float = 0.0, color: Color = Color("55c8d4")) -> void:
	var display := Node3D.new()
	display.position = pos
	display.rotation.y = yaw
	parent.add_child(display)
	imported_model(display, "res://assets/models/props/computer_screen.glb", Vector3(0, 0.08, 0), 0.64)
	imported_model(display, "res://assets/models/props/keyboard.glb", Vector3(0, 0, -0.34), 0.055)
	var screen := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.64, 0.35)
	screen.mesh = quad
	screen.position = Vector3(0, 0.44, -0.112)
	var screen_material := material(color.darkened(0.35), 0.75)
	screen_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	screen.material_override = screen_material
	display.add_child(screen)
	var user_label := sign_text(display, Vector3(0, 0.44, -0.124), "bykovarchitect", Color("d5f2ef"), PI)
	user_label.font_size = 24
	user_label.pixel_size = 0.0035
	user_label.outline_size = 2
	var system_label := sign_text(display, Vector3(0, 0.59, -0.124), "ARCH OS  //  SECURE SESSION", Color("75bec7"), PI)
	system_label.font_size = 14
	system_label.pixel_size = 0.003
	system_label.outline_size = 1

static func laptop(parent: Node3D, pos: Vector3, yaw: float = 0.0) -> void:
	var display := Node3D.new()
	display.position = pos
	display.rotation.y = yaw
	parent.add_child(display)
	imported_model(display, "res://assets/models/props/laptop.glb", Vector3.ZERO, 0.43)

static func bench(parent: Node3D, pos: Vector3, color: Color, yaw: float = 0.0) -> void:
	imported_model(parent, "res://assets/models/props/couch.glb", pos, 0.95, yaw)
	furniture_collision(parent, pos + Vector3(0, 0.35, 0), Vector3(1.9, 0.7, 0.85))

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

static func imported_model(parent: Node3D, path: String, pos: Vector3, height: float, yaw: float = 0.0) -> Node3D:
	var wrapper := Node3D.new()
	wrapper.position = pos
	wrapper.rotation.y = yaw
	parent.add_child(wrapper)
	var instance: Node3D = load(path).instantiate()
	var bounds := model_bounds(instance, Transform3D.IDENTITY)
	var scale_factor := height / maxf(bounds.size.y, 0.001)
	var center := bounds.get_center()
	instance.scale = Vector3.ONE * scale_factor
	instance.position = Vector3(-center.x, -bounds.position.y, -center.z) * scale_factor
	wrapper.add_child(instance)
	return wrapper

static func model_bounds(node: Node3D, transform: Transform3D) -> AABB:
	var result := AABB()
	var first := true
	for child in node.get_children():
		if child is Node3D:
			var child_transform: Transform3D = transform * child.transform
			if child is MeshInstance3D:
				var bounds: AABB = child_transform * child.get_aabb()
				if first:
					result = bounds
					first = false
				else:
					result = result.merge(bounds)
			var children := model_bounds(child, child_transform)
			if children.size != Vector3.ZERO:
				if first:
					result = children
					first = false
				else:
					result = result.merge(children)
	return result
