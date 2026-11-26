extends CharacterBody3D

enum State { PATROL, SUSPICION, INVESTIGATE, ALERT, SEARCH }

var game: Node
var patrol: Array[Vector3] = []
var patrol_index: int = 0
var state: State = State.PATROL
var last_known := Vector3.ZERO
var state_time: float = 0.0
var memory: float = 0.0
var variant: String = "swat"
var visual: Node3D
var character: Node3D
var animation_player: AnimationPlayer
var alert_light: OmniLight3D
var current_animation: String = ""
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
	visual.scale = Vector3.ONE * 0.95
	add_child(visual)
	if not variant in ["swat", "worker", "business_man"]:
		variant = "swat"
	character = load("res://assets/models/characters/%s.glb" % variant).instantiate()
	character.position = Vector3(0, 0.01, -0.09)
	character.rotation.y = PI
	visual.add_child(character)
	animation_player = find_animation_player(character)
	if is_instance_valid(animation_player):
		for action in ["Idle_Neutral", "Walk", "Run", "Interact"]:
			var animation_name: String = "CharacterArmature|" + action
			if animation_player.has_animation(animation_name):
				animation_player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
		play_animation("Idle_Neutral")
	alert_light = OmniLight3D.new()
	alert_light.position.y = 1.8
	alert_light.light_color = Color("83e6ef")
	alert_light.light_energy = 0.18
	alert_light.omni_range = 2.0
	add_child(alert_light)
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
	if horizontal_speed > 2.4:
		play_animation("Run")
	elif horizontal_speed > 0.1:
		play_animation("Walk")
	else:
		play_animation("Idle_Neutral")
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
	alert_light.light_color = alert_light.light_color.lerp(color, 8.0 * delta)
	alert_light.light_energy = 0.65 if state != State.PATROL else 0.18

func find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result := find_animation_player(child)
		if is_instance_valid(result):
			return result
	return null

func play_animation(action: String) -> void:
	if not is_instance_valid(animation_player):
		return
	var animation_name: String = "CharacterArmature|" + action
	if current_animation != animation_name and animation_player.has_animation(animation_name):
		current_animation = animation_name
		animation_player.play(animation_name, 0.18)

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
