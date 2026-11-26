extends Node3D

var game: Node
var disabled: bool = false
var base_yaw: float = 0.0
var sweep: float = 0.65
var clock: float = 0.0
var pivot: Node3D
var lens_material: StandardMaterial3D

func _ready() -> void:
	add_to_group("security_camera")
	pivot = Node3D.new()
	pivot.rotation = Vector3(-0.12, base_yaw, 0)
	add_child(pivot)
	var mount := MeshInstance3D.new()
	var mount_mesh := BoxMesh.new()
	mount_mesh.size = Vector3(0.16, 0.65, 0.16)
	mount.mesh = mount_mesh
	mount.position.y = 0.42
	var mount_material := StandardMaterial3D.new()
	mount_material.albedo_color = Color("263944")
	mount.material_override = mount_material
	add_child(mount)
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.5, 0.28, 0.65)
	body.mesh = mesh
	pivot.add_child(body)
	var lens := MeshInstance3D.new()
	var lens_mesh := SphereMesh.new()
	lens_mesh.radius = 0.12
	lens_mesh.height = 0.24
	lens.mesh = lens_mesh
	lens.position.z = -0.34
	lens_material = StandardMaterial3D.new()
	lens_material.albedo_color = Color("e76576")
	lens_material.emission_enabled = true
	lens_material.emission = Color("a72f42")
	lens.material_override = lens_material
	pivot.add_child(lens)
	var cone := SpotLight3D.new()
	cone.light_color = Color("e76576")
	cone.light_energy = 0.5
	cone.spot_range = 7.0
	cone.spot_angle = 38.0
	cone.position.z = -0.35
	pivot.add_child(cone)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(game) or game.mode != "playing":
		return
	clock += delta
	pivot.rotation.y = base_yaw + sin(clock * 0.55) * sweep
	if disabled:
		lens_material.albedo_color = Color("4bd6a0")
		return
	if can_see_player():
		game.last_known_player_position = game.player.global_position
		game.add_detection(delta * 34.0)
		lens_material.albedo_color = Color("ffbe55")
	else:
		lens_material.albedo_color = Color("e76576")

func can_see_player() -> bool:
	var origin := pivot.global_position
	var to_player: Vector3 = game.player.eye_position() - origin
	if to_player.length() > 13.0 or to_player.length() < 0.01:
		return false
	var forward := -pivot.global_transform.basis.z
	if forward.dot(to_player.normalized()) < 0.72:
		return false
	var query := PhysicsRayQueryParameters3D.create(origin, game.player.eye_position(), 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func disable() -> void:
	disabled = true
