extends StaticBody3D

var action_id: String = ""
var caption_key: String = ""
var required_access: int = 0
var completed: bool = false
var optional: bool = false
var mesh: MeshInstance3D

func set_completed() -> void:
	completed = true
	if is_instance_valid(mesh):
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("4bd6a0")
		material.emission_enabled = true
		material.emission = Color("1d6b52")
		material.emission_energy_multiplier = 0.7
		mesh.material_override = material

func caption() -> String:
	return tr(caption_key)
