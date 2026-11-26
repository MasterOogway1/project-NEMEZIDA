extends CharacterBody3D

enum State { PATROL, SUSPICION, INVESTIGATE, ALERT, SEARCH }

var game: Node
var patrol: Array[Vector3] = []
var patrol_index: int = 0
var state: State = State.PATROL
var last_known := Vector3.ZERO
var state_time: float = 0.0
var memory: float = 0.0
var body_material: StandardMaterial3D
var visual: Node3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D
var left_leg: MeshInstance3D
var right_leg: MeshInstance3D
var walk_cycle: float = 0.0
var patrol_wait: float = 0.0
var patrol_yaw: float = 0.0
var scan_phase: float = 0.0
var stuck_time: float = 0.0
var previous_position := Vector3.ZERO

func _ready() -> void:
	add_to_group("security")
	collision_layer = 4
	collision_mask = 1
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.34
	shape.height = 1.7
	collider.shape = shape
	collider.position.y = 0.85
	add_child(collider)
	visual = Node3D.new()
	add_child(visual)
	body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color("526b91")
	var uniform_material := StandardMaterial3D.new()
	uniform_material.albedo_color = Color("26384d")
	var body := MeshInstance3D.new()
	var torso := BoxMesh.new()
	torso.size = Vector3(0.64, 0.76, 0.36)
	body.mesh = torso
	body.position.y = 1.08
	body.material_override = body_material
	visual.add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.24
	sphere.height = 0.48
	head.mesh = sphere
	head.position.y = 1.62
	head.material_override = body_material
	visual.add_child(head)
	var visor := MeshInstance3D.new()
	var visor_mesh := BoxMesh.new()
	visor_mesh.size = Vector3(0.34, 0.1, 0.08)
	visor.mesh = visor_mesh
	visor.position = Vector3(0, 1.63, -0.22)
	var visor_material := StandardMaterial3D.new()
	visor_material.albedo_color = Color("83e6ef")
	visor_material.emission_enabled = true
	visor_material.emission = Color("2c9ca9")
	visor.material_override = visor_material
	visual.add_child(visor)
	left_arm = limb(Vector3(-0.42, 1.06, 0), Vector3(0.16, 0.72, 0.18), body_material)
	right_arm = limb(Vector3(0.42, 1.06, 0), Vector3(0.16, 0.72, 0.18), body_material)
	left_leg = limb(Vector3(-0.17, 0.4, 0), Vector3(0.23, 0.72, 0.26), uniform_material)
	right_leg = limb(Vector3(0.17, 0.4, 0), Vector3(0.23, 0.72, 0.26), uniform_material)
	scan_phase = global_position.x * 0.37 + global_position.z * 0.21
	previous_position = global_position
	if not patrol.is_empty():
		last_known = patrol[0]
		if patrol.size() > 1:
			if flat_distance(global_position, patrol[0]) < 0.35:
				patrol_index = 1
			var direction := patrol[patrol_index] - global_position
			rotation.y = atan2(-direction.x, -direction.z)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(game) or game.mode != "playing":
		return
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = -0.2
	state_time += delta
	patrol_wait = maxf(0.0, patrol_wait - delta)
	var sees := can_see_player()
	if sees:
		last_known = game.player.global_position
		game.last_known_player_position = last_known
		game.add_detection(delta * 46.0)
		state = State.ALERT
		memory = 4.0
		state_time = 0.0
	else:
		memory -= delta
		if state == State.ALERT and memory <= 0.0:
			state = State.SEARCH
			state_time = 0.0
		elif game.alarm >= 48.0 and state == State.PATROL:
			last_known = game.last_known_player_position
			state = State.INVESTIGATE
			state_time = 0.0
		elif state == State.PATROL and hears_player():
			last_known = game.player.global_position
			state = State.SUSPICION
			state_time = 0.0
	if state == State.SUSPICION and state_time > 0.7:
		state = State.INVESTIGATE
		state_time = 0.0
	var target := global_position
	var speed := 0.0
	match state:
		State.PATROL:
			if not patrol.is_empty():
				if patrol_wait > 0.0:
					rotation.y = patrol_yaw + sin(state_time * 2.2 + scan_phase) * 0.5
				else:
					target = patrol[patrol_index]
					speed = 1.55
					if flat_distance(global_position, target) < 0.35:
						patrol_index = (patrol_index + 1) % patrol.size()
						patrol_wait = 0.35 + fmod(absf(scan_phase), 0.45)
						patrol_yaw = rotation.y
						state_time = 0.0
		State.SUSPICION:
			speed = 0.0
		State.INVESTIGATE:
			target = last_known
			speed = 2.25
			if flat_distance(global_position, target) < 0.65 or state_time > 9.0:
				state = State.SEARCH
				state_time = 0.0
		State.ALERT:
			target = last_known
			speed = 3.25
		State.SEARCH:
			target = last_known + Vector3(sin(state_time * 1.7) * 2.0, 0, cos(state_time * 1.3) * 2.0)
			speed = 1.7
			if state_time > 7.0 and game.alarm < 40.0:
				state = State.PATROL
				state_time = 0.0
	var flat_target := Vector3(target.x, global_position.y, target.z)
	var difference := flat_target - global_position
	if speed > 0.0 and difference.length() > 0.18:
		var direction := difference.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		var target_angle := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 8.0 * delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	walk_cycle += delta * horizontal_speed * 5.0
	var stride := sin(walk_cycle) * minf(horizontal_speed / 1.5, 1.0) * 0.55
	left_leg.rotation.x = stride
	right_leg.rotation.x = -stride
	left_arm.rotation.x = -stride * 0.7
	right_arm.rotation.x = stride * 0.7
	visual.position.y = absf(sin(walk_cycle)) * minf(horizontal_speed, 1.0) * 0.035
	if speed > 0.0 and difference.length() > 0.5 and flat_distance(global_position, previous_position) < 0.005:
		stuck_time += delta
	else:
		stuck_time = 0.0
	previous_position = global_position
	if stuck_time > 1.4:
		if state == State.PATROL and patrol.size() > 1:
			patrol_index = (patrol_index + 1) % patrol.size()
			patrol_wait = 0.15
		elif state == State.INVESTIGATE:
			state = State.SEARCH
			state_time = 0.0
		stuck_time = 0.0
	var color := Color("526b91")
	if state == State.SUSPICION or state == State.INVESTIGATE or state == State.SEARCH:
		color = Color("d7a94f")
	elif state == State.ALERT:
		color = Color("d95767")
	body_material.albedo_color = body_material.albedo_color.lerp(color, 8.0 * delta)

func limb(pos: Vector3, dimensions: Vector3, mat: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	part.mesh = mesh
	part.position = pos
	part.material_override = mat
	visual.add_child(part)
	return part

func can_see_player() -> bool:
	if not is_instance_valid(game.player):
		return false
	var to_player: Vector3 = game.player.eye_position() - (global_position + Vector3(0, 1.5, 0))
	var distance := to_player.length()
	var range_limit := 9.0 if game.player.crouching else 13.0
	if distance > range_limit or distance < 0.01:
		return false
	var forward := -global_transform.basis.z
	var direction := Vector3(to_player.x, 0, to_player.z).normalized()
	if forward.dot(direction) < 0.55:
		return false
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 1.5, 0), game.player.eye_position(), 1)
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	return result.is_empty()

func hears_player() -> bool:
	var distance := global_position.distance_to(game.player.global_position)
	return distance < game.player.noise_level * 11.0

func flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func state_caption() -> String:
	match state:
		State.SUSPICION:
			return tr("AI_SUSPICION")
		State.INVESTIGATE, State.SEARCH:
			return tr("AI_SEARCH")
		State.ALERT:
			return tr("AI_ALERT")
	return tr("AI_PATROL")
