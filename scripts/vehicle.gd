extends VehicleBody3D

const MAX_STEERING := 0.52
const ENGINE_FORCE := 760.0
const REVERSE_FORCE := 420.0

var game: Node
var action_id: String = "vehicle"
var required_access: int = 0
var completed: bool = false
var occupied: bool = false
var fuel: float = 100.0
var driver_camera: Camera3D
var speed_kph: float = 0.0
var fuel_warning: bool = false

func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 1
	collision_mask = 3
	mass = 720.0
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0.0, 0.35, 0.0)
	_build_chassis()
	_build_wheels()
	driver_camera = Camera3D.new()
	driver_camera.position = Vector3(0.0, 2.75, 6.5)
	driver_camera.rotation_degrees.x = -13.0
	driver_camera.fov = 72.0
	driver_camera.near = 0.1
	driver_camera.far = 220.0
	add_child(driver_camera)

func _build_chassis() -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.82, 0.72, 3.7)
	collision.shape = shape
	collision.position.y = 0.68
	add_child(collision)
	_part(Vector3(0.0, 0.68, 0.0), Vector3(1.82, 0.5, 3.7), Color("527b83"))
	_part(Vector3(0.0, 1.14, 0.18), Vector3(1.56, 0.55, 1.9), Color("41646d"))
	_part(Vector3(0.0, 1.18, -0.79), Vector3(1.38, 0.36, 0.035), Color("8fc3ce"), 0.18)
	_part(Vector3(0.0, 1.18, 1.15), Vector3(1.38, 0.34, 0.035), Color("709da7"), 0.08)
	_part(Vector3(0.0, 0.48, -1.88), Vector3(1.88, 0.16, 0.12), Color("26363d"))
	_part(Vector3(0.0, 0.48, 1.88), Vector3(1.88, 0.16, 0.12), Color("26363d"))
	for x in [-0.61, 0.61]:
		_part(Vector3(x, 0.72, -1.87), Vector3(0.38, 0.2, 0.04), Color("ffe2a1"), 1.4)
		_part(Vector3(x, 0.72, 1.87), Vector3(0.34, 0.18, 0.04), Color("d95858"), 0.8)

func _part(pos: Vector3, dimensions: Vector3, color: Color, emission: float = 0.0) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color, emission)
	mesh_instance.position = pos
	add_child(mesh_instance)

func _material(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.7
	if emission > 0.0:
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = emission
	return result

func _build_wheels() -> void:
	for z in [-1.18, 1.18]:
		for x in [-0.91, 0.91]:
			var wheel := VehicleWheel3D.new()
			wheel.position = Vector3(x, 0.38, z)
			wheel.use_as_steering = z < 0.0
			wheel.use_as_traction = z > 0.0
			wheel.wheel_radius = 0.35
			wheel.wheel_rest_length = 0.2
			wheel.wheel_friction_slip = 3.2
			wheel.wheel_roll_influence = 0.12
			wheel.suspension_travel = 0.2
			wheel.suspension_stiffness = 38.0
			wheel.suspension_max_force = 7500.0
			wheel.damping_compression = 1.8
			wheel.damping_relaxation = 2.6
			add_child(wheel)
			var visual := MeshInstance3D.new()
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.35
			mesh.bottom_radius = 0.35
			mesh.height = 0.24
			mesh.radial_segments = 20
			visual.mesh = mesh
			visual.rotation.z = PI * 0.5
			visual.material_override = _material(Color("172027"))
			wheel.add_child(visual)

func _input(event: InputEvent) -> void:
	if occupied and event.is_action_pressed("interact") and not event.is_echo():
		game.exit_vehicle()
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	speed_kph = linear_velocity.length() * 3.6
	if not occupied or game.mode != "playing":
		engine_force = 0.0
		brake = 3.0
		steering = 0.0
		return
	var forward_input := Input.get_action_strength("move_forward")
	var reverse_input := Input.get_action_strength("move_back")
	var steer_input := Input.get_action_strength("move_left") - Input.get_action_strength("move_right")
	steering = move_toward(steering, steer_input * MAX_STEERING, delta * 1.8)
	var signed_speed := -global_transform.basis.z.dot(linear_velocity)
	brake = 0.0
	if Input.is_action_pressed("handbrake"):
		brake = 14.0
		engine_force = 0.0
	elif forward_input > 0.0:
		if signed_speed < -1.0:
			brake = 8.0
			engine_force = 0.0
		else:
			engine_force = forward_input * ENGINE_FORCE if fuel > 0.0 else 0.0
	elif reverse_input > 0.0:
		if signed_speed > 1.0:
			brake = 8.0
			engine_force = 0.0
		else:
			engine_force = -reverse_input * REVERSE_FORCE if fuel > 0.0 else 0.0
	else:
		engine_force = 0.0
		brake = 0.45
	if fuel > 0.0 and absf(engine_force) > 0.0:
		fuel = maxf(0.0, fuel - delta * 0.12)
	if fuel <= 0.0 and not fuel_warning:
		fuel_warning = true
		game.show_message(tr("MSG_FUEL_EMPTY"), 7.0)
	if global_position.y < -5.0:
		position = Vector3(0.0, 1.0, 12.0)
		rotation = Vector3.ZERO
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO

func caption() -> String:
	return tr("ACT_VEHICLE")

func speed_text() -> String:
	return tr("HUD_SPEED") % int(speed_kph)

func save_data() -> Dictionary:
	return {"position": position, "rotation": rotation, "fuel": fuel}

func restore_data(data: Dictionary) -> void:
	position = data.get("position", position)
	rotation = data.get("rotation", rotation)
	fuel = clampf(float(data.get("fuel", 100.0)), 0.0, 100.0)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

func exit_position() -> Vector3:
	for side in [-1.0, 1.0]:
		var candidate := to_global(Vector3(side * 2.1, -position.y + 0.12, 0.3))
		var from := global_position + Vector3.UP
		var to := candidate + Vector3.UP
		var query := PhysicsRayQueryParameters3D.create(from, to, 1, [get_rid()])
		if get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			return candidate
	return to_global(Vector3(-2.1, -position.y + 0.12, 0.3))
