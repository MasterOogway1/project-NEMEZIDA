extends CharacterBody3D

const WALK_SPEED := 4.2
const SPRINT_SPEED := 7.0
const CROUCH_SPEED := 2.2
const MOUSE_SENSITIVITY := 0.0022

var game: Node
var camera: Camera3D
var head: Node3D
var collision: CollisionShape3D
var controls_enabled: bool = false
var mouse_sensitivity: float = MOUSE_SENSITIVITY
var crouching: bool = false
var noise_level: float = 0.0
var step_clock: float = 0.0
var current_target: Node3D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	collision = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.75
	collision.shape = capsule
	collision.position.y = 0.88
	add_child(collision)
	head = Node3D.new()
	head.position.y = 1.58
	add_child(head)
	camera = Camera3D.new()
	camera.fov = 75.0
	camera.near = 0.06
	camera.far = 120.0
	head.add_child(camera)
	camera.current = true

func _input(event: InputEvent) -> void:
	if not controls_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-82.0), deg_to_rad(82.0))
	if event.is_action_pressed("interact") and is_instance_valid(current_target):
		game.interact_with(current_target)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = -0.2
	var input_dir := Vector2.ZERO
	if controls_enabled:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		crouching = Input.is_action_pressed("crouch")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var speed := WALK_SPEED
	if crouching:
		speed = CROUCH_SPEED
	elif Input.is_action_pressed("sprint") and controls_enabled:
		speed = SPRINT_SPEED
	if not controls_enabled:
		direction = Vector3.ZERO
	velocity.x = move_toward(velocity.x, direction.x * speed, 22.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, 22.0 * delta)
	move_and_slide()
	var target_height := 0.95 if crouching else 1.58
	head.position.y = lerpf(head.position.y, target_height, 12.0 * delta)
	collision.shape.height = lerpf(collision.shape.height, 1.05 if crouching else 1.75, 12.0 * delta)
	collision.position.y = collision.shape.height * 0.5
	var moving := Vector2(velocity.x, velocity.z).length()
	noise_level = 0.0
	if moving > 0.2 and is_on_floor() and controls_enabled:
		noise_level = 0.25 if crouching else (1.0 if speed == SPRINT_SPEED else 0.55)
		step_clock -= delta
		if step_clock <= 0.0:
			step_clock = 0.58 if crouching else (0.28 if speed == SPRINT_SPEED else 0.42)
			game.play_sound("step", -18.0 if crouching else -11.0)
	else:
		step_clock = 0.0
	_find_target()

func _find_target() -> void:
	current_target = null
	if not controls_enabled:
		return
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * 2.8
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		var collider: Object = result.get("collider")
		if collider is Node and collider.is_in_group("interactable"):
			current_target = collider

func eye_position() -> Vector3:
	return camera.global_position
