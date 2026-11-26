class_name LevelData
extends RefCounted

const F = preload("res://scripts/level_factory.gd")

static func build(root: Node3D, index: int, game: Node) -> Dictionary:
	match index:
		0:
			return level_one(root, game)
		1:
			return level_two(root, game)
		2:
			return level_three(root, game)
		3:
			return level_four(root, game)
	return {}

static func base(root: Node3D, floor_color: Color, wall_color: Color, accent: Color, lamp_color: Color) -> void:
	F.box(root, Vector3(0, -0.25, 0), Vector3(30, 0.5, 30), floor_color)
	for offset in [-10.0, -5.0, 0.0, 5.0, 10.0]:
		F.box(root, Vector3(offset, 0.006, 0), Vector3(0.025, 0.012, 30), floor_color.darkened(0.2), false)
		F.box(root, Vector3(0, 0.006, offset), Vector3(30, 0.012, 0.025), floor_color.darkened(0.2), false)
	var ceiling := F.box(root, Vector3(0, 3.35, 0), Vector3(30, 0.15, 30), Color("152630"), false)
	ceiling.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	F.wall_x(root, -15, -15, 15, wall_color)
	F.wall_x(root, 15, -15, 15, wall_color)
	F.wall_z(root, -15, -15, 15, wall_color)
	F.wall_z(root, 15, -15, 15, wall_color)
	for z in [-14.84, 14.84]:
		F.box(root, Vector3(0, 0.22, z), Vector3(29.7, 0.44, 0.08), accent.darkened(0.48), false)
		F.box(root, Vector3(0, 2.85, z), Vector3(29.7, 0.09, 0.09), accent, false, 0.25)
		for x in [-12.0, -4.0, 4.0, 12.0]:
			F.box(root, Vector3(x, 1.55, z), Vector3(0.12, 2.5, 0.1), accent.darkened(0.2), false)
	for x in [-14.84, 14.84]:
		F.box(root, Vector3(x, 0.22, 0), Vector3(0.08, 0.44, 29.7), accent.darkened(0.48), false)
		F.box(root, Vector3(x, 2.85, 0), Vector3(0.09, 0.09, 29.7), accent, false, 0.25)
		for z in [-12.0, -4.0, 4.0, 12.0]:
			F.box(root, Vector3(x, 1.55, z), Vector3(0.1, 2.5, 0.12), accent.darkened(0.2), false)
	for x in [-10.0, 0.0, 10.0]:
		for z in [-10.0, 0.0, 10.0]:
			F.light(root, Vector3(x, 2.8, z), lamp_color, 0.7, 8.0)
			F.box(root, Vector3(x, 3.05, z), Vector3(1.8, 0.05, 0.28), lamp_color, false, 1.0)
			F.box(root, Vector3(x, 3.12, z), Vector3(2.1, 0.08, 0.45), accent.darkened(0.4), false)

static func point(x: float, z: float, label: String) -> Dictionary:
	return {"x": x + 15.0, "z": z + 15.0, "label": label}

static func room(x: float, z: float, width: float, depth: float) -> Rect2:
	return Rect2(x + 15.0, z + 15.0, width, depth)

static func level_one(root: Node3D, game: Node) -> Dictionary:
	base(root, Color("45484a"), Color("718087"), Color("b49a67"), Color("ffe0a3"))
	F.wall_x(root, 4, -15, 15, Color("718087"), 0, 3)
	F.wall_z(root, -5, -15, 4, Color("718087"), -4, 3)
	F.wall_z(root, 6, 4, 15, Color("718087"), 9, 2.6)
	F.desk(root, Vector3(-10, 0, 9))
	F.desk(root, Vector3(-8, 0, 9))
	F.interactable(root, Vector3(-10, 1.2, 9), "plan", "ACT_BLUEPRINT", 0, Color("d3b56c"), Vector3(0.85, 0.08, 0.6))
	F.interactable(root, Vector3(-8, 1.25, 9), "invite", "ACT_INVITE", 0, Color("276879"), Vector3(0.75, 0.55, 0.15))
	F.interactable(root, Vector3(10, 1.0, -9), "city_node", "ACT_CITY_NODE")
	F.interactable(root, Vector3(0, 1.0, 14.65), "exit", "ACT_EXIT", 0, Color("3d9d79"), Vector3(1.8, 2.1, 0.18))
	F.sign_text(root, Vector3(0, 2.5, 14.48), "ВЫХОД / EXIT", Color("bcecef"), PI)
	F.sign_text(root, Vector3(-10, 2.3, 3.85), "АРХИТЕКТУРНОЕ БЮРО")
	F.plant(root, Vector3(-13, 0, 12))
	F.plant(root, Vector3(12, 0, 7))
	F.floor_zone(root, Vector3(-10, 0, 9), Vector2(7, 5), Color("5c5548"))
	F.floor_zone(root, Vector3(8.5, 0, 10), Vector2(10, 6), Color("405b5b"))
	F.desk(root, Vector3(-10, 0, 6.5), Color("81715a"))
	F.architectural_model(root, Vector3(-10, 0, 6.5))
	F.bench(root, Vector3(8, 0, 12), Color("657a71"), PI)
	F.desk(root, Vector3(9, 0, 7), Color("81715a"))
	F.laptop(root, Vector3(9, 0.82, 7), PI)
	F.box(root, Vector3(-13.7, 1.0, 0), Vector3(1.6, 2.0, 0.55), Color("554d43"))
	for y in [0.35, 0.85, 1.35, 1.85]:
		F.box(root, Vector3(-13.7, y, -0.3), Vector3(1.5, 0.07, 0.65), Color("aa9167"), false)
	for x in [-12.9, -12.65, -12.4]:
		F.cylinder(root, Vector3(x, 0.65, 7), 0.075, 1.3, Color("d8cfb4"))
	F.light(root, Vector3(-10, 2.35, 8), Color("ffc979"), 1.15, 6.0)
	F.sign_text(root, Vector3(9, 2.25, 14.48), "ПРИЁМНАЯ / RECEPTION", Color("f1d59b"), PI)
	for z in [-7.0, -11.0]:
		F.box(root, Vector3(11.8, 0.8, z), Vector3(1.2, 1.6, 1.2), Color("475d66"))
	F.security_camera(root, Vector3(4.5, 2.65, 3.6), 0, game)
	return {
		"spawn": Vector3(0, 0.1, 12),
		"capture": Vector3(-6.5, 0.1, 12),
		"capture_yaw": 0.85,
		"rooms": [room(-14.8, 4.2, 20.5, 10.5), room(-14.8, -14.8, 9.5, 18.5), room(-4.7, -14.8, 19.5, 18.5), room(6.2, 4.2, 8.5, 10.5)],
		"points": [point(-10, 9, "POINT_PLAN"), point(10, -9, "POINT_NODE"), point(0, 14, "POINT_EXIT")],
		"checkpoints": [Vector3(0, 0.1, 12), Vector3(-8, 0.1, 7), Vector3(8, 0.1, -6), Vector3(-7, 0.1, 7)]
	}

static func level_two(root: Node3D, game: Node) -> Dictionary:
	base(root, Color("253c48"), Color("385a69"), Color("42a7ae"), Color("b7f1ed"))
	F.wall_x(root, 5, -15, 15, Color("385a69"), 0, 3)
	F.wall_x(root, -4, -15, 15, Color("385a69"), -7, 3)
	F.wall_z(root, 2, -15, 5, Color("385a69"), 0, 3)
	F.wall_z(root, -6, 5, 15, Color("385a69"), 10, 2.6)
	F.desk(root, Vector3(6, 0, 10), Color("3f6670"))
	F.interactable(root, Vector3(6, 1.25, 10), "plan", "ACT_BLUEPRINT", 1, Color("d3b56c"), Vector3(0.85, 0.08, 0.6))
	F.interactable(root, Vector3(-11, 1.0, 0), "badge", "ACT_BADGE", 1, Color("d3b56c"), Vector3(0.5, 0.1, 0.35))
	F.interactable(root, Vector3(-12, 1.0, 10), "security", "ACT_SECURITY", 1)
	F.interactable(root, Vector3(10, 1.0, -10), "test_node", "ACT_TEST_NODE", 2)
	F.interactable(root, Vector3(0, 1.0, -14.65), "exit", "ACT_ELEVATOR", 1, Color("3d9d79"), Vector3(2.0, 2.2, 0.18))
	F.sign_text(root, Vector3(0, 2.55, 4.82), "VOSTOK NEURAL / ВОСТОК НЕЙРО")
	F.sign_text(root, Vector3(0, 2.4, -14.45), "LIFT / ЛИФТ")
	for x in [7.0, 10.0, 13.0]:
		F.server(root, Vector3(x, 0, -12.8))
	for pos in [Vector3(-3,0,11), Vector3(11,0,8), Vector3(-12,0,-8), Vector3(5,0,1)]:
		F.plant(root, pos)
	F.floor_zone(root, Vector3(5, 0, 10), Vector2(17, 6), Color("294b55"))
	F.floor_zone(root, Vector3(9, 0, -10), Vector2(10, 7), Color("183b48"))
	F.floor_zone(root, Vector3(-11, 0, 9.5), Vector2(5, 6), Color("45504c"))
	F.desk(root, Vector3(8.5, 0, 10), Color("58757a"))
	F.monitor(root, Vector3(8.5, 0.82, 10), PI, Color("68e0d4"))
	F.bench(root, Vector3(-1.5, 0, 10.5), Color("46727b"), PI * 0.5)
	F.desk(root, Vector3(-12, 0, 10.7), Color("4d686c"))
	F.monitor(root, Vector3(-12, 0.82, 10.7), 0, Color("e5bd72"))
	for x in [7.0, 10.0, 13.0]:
		F.box(root, Vector3(x, 2.35, -12.8), Vector3(0.75, 0.12, 0.75), Color("64d9d5"), false, 0.75)
		F.light(root, Vector3(x, 2.4, -11.5), Color("58c7cf"), 0.65, 4.0)
	F.sign_text(root, Vector3(9, 2.4, -14.45), "ИСПЫТАТЕЛЬНАЯ ЗОНА", Color("8ee8e2"))
	F.guard(root, Vector3(5, 0.1, 1), [Vector3(5,0.1,1), Vector3(12,0.1,1), Vector3(12,0.1,-2), Vector3(5,0.1,-2)], game, "business_man")
	F.guard(root, Vector3(-4, 0.1, -8), [Vector3(-4,0.1,-8), Vector3(5,0.1,-8), Vector3(5,0.1,-12), Vector3(-4,0.1,-12)], game)
	F.security_camera(root, Vector3(-2, 2.65, 4.6), 0, game)
	F.security_camera(root, Vector3(13.8, 2.65, -4.5), PI * 0.5, game)
	return {
		"spawn": Vector3(0, 0.1, 13),
		"capture": Vector3(6, 0.1, 3),
		"capture_yaw": -0.2,
		"rooms": [room(-14.8, 5.2, 8.5, 9.5), room(-5.7, 5.2, 20.5, 9.5), room(-14.8, -3.8, 16.5, 8.5), room(2.3, -3.8, 12.5, 8.5), room(-14.8, -14.8, 16.5, 10.5), room(2.3, -14.8, 12.5, 10.5)],
		"points": [point(6, 10, "POINT_PLAN"), point(-11, 0, "POINT_BADGE"), point(10, -10, "POINT_NODE"), point(0, -14, "POINT_EXIT")],
		"checkpoints": [Vector3(0, 0.1, 13), Vector3(5, 0.1, 8), Vector3(-8, 0.1, 1), Vector3(7, 0.1, -7)]
	}

static func level_three(root: Node3D, game: Node) -> Dictionary:
	base(root, Color("142b39"), Color("294c60"), Color("287e9c"), Color("9bd9ff"))
	F.wall_x(root, 4, -15, 15, Color("294c60"), 0, 3)
	F.wall_x(root, -3, -15, 15, Color("294c60"), 0, 3)
	F.wall_z(root, -6, 4, 15, Color("294c60"), 10, 2.6)
	F.wall_z(root, 6, 4, 15, Color("294c60"), 10, 2.6)
	F.desk(root, Vector3(-11, 0, 10), Color("35586a"))
	F.interactable(root, Vector3(-11, 1.2, 10), "plan", "ACT_BLUEPRINT", 2, Color("d3b56c"), Vector3(0.85, 0.08, 0.6))
	F.interactable(root, Vector3(11, 1.0, 10), "badge", "ACT_BADGE", 2, Color("d3b56c"), Vector3(0.5, 0.1, 0.35))
	F.interactable(root, Vector3(-13.5, 1.0, 0), "distract", "ACT_DISTRACT", 2)
	F.interactable(root, Vector3(13.5, 1.0, 0), "overload", "ACT_OVERLOAD", 2, Color("914554"))
	for entry in [["node_a", -10.0, "ACT_NODE_A"], ["node_b", 0.0, "ACT_NODE_B"], ["node_c", 10.0, "ACT_NODE_C"]]:
		var x: float = entry[1]
		F.server(root, Vector3(x, 0, -10))
		F.interactable(root, Vector3(x, 1.0, -9.45), entry[0], entry[2], 3, Color("276879"), Vector3(0.65, 0.55, 0.12))
	for x in [-10.0, -5.0, 0.0, 5.0, 10.0]:
		F.server(root, Vector3(x, 0, -6))
	F.interactable(root, Vector3(0, 1.0, 14.65), "exit", "ACT_EXIT", 2, Color("3d9d79"), Vector3(1.8, 2.1, 0.18))
	F.sign_text(root, Vector3(0, 2.55, 3.82), "COLD RESERVE / ХОЛОДНЫЙ РЕЗЕРВ")
	F.floor_zone(root, Vector3(0, 0, 0), Vector2(28, 4.5), Color("1d3b49"))
	F.floor_zone(root, Vector3(0, 0, -10), Vector2(28, 8), Color("102f40"))
	F.floor_zone(root, Vector3(-11, 0, 10), Vector2(5.5, 5.5), Color("294b55"))
	F.desk(root, Vector3(-11, 0, 12), Color("35586a"))
	F.monitor(root, Vector3(-11, 0.82, 12), PI, Color("75cde8"))
	F.cable_tray(root, -6, Color("426f82"))
	F.cable_tray(root, -10, Color("426f82"))
	for x in [-10.0, -5.0, 0.0, 5.0, 10.0]:
		F.box(root, Vector3(x, 1.1, -6.44), Vector3(0.08, 1.85, 0.025), Color("4ebcff"), false, 1.4)
	for x in range(-13, 14, 2):
		F.box(root, Vector3(x, 0.035, -3.45), Vector3(0.9, 0.025, 0.18), Color("d2a74e"), false, 0.2)
	for pos in [Vector3(-13, 2.4, -8), Vector3(13, 2.4, -8), Vector3(0, 2.4, -12)]:
		F.light(root, pos, Color("5fb9ff"), 0.8, 6.0)
	F.sign_text(root, Vector3(0, 2.5, -14.45), "СЕРВЕРНЫЙ РЯД / 03", Color("8fd8ff"))
	F.guard(root, Vector3(-11, 0.1, 1), [Vector3(-11,0.1,1), Vector3(11,0.1,1)], game, "worker")
	F.guard(root, Vector3(-12, 0.1, -4), [Vector3(-12,0.1,-4), Vector3(12,0.1,-4)], game)
	F.guard(root, Vector3(-12, 0.1, -13), [Vector3(-12,0.1,-13), Vector3(12,0.1,-13)], game)
	F.security_camera(root, Vector3(-5, 2.65, 3.6), 0, game)
	F.security_camera(root, Vector3(14.5, 2.65, -2.5), PI * 0.5, game)
	return {
		"spawn": Vector3(0, 0.1, 13),
		"capture": Vector3(3, 0.1, -4),
		"capture_yaw": 0.0,
		"rooms": [room(-14.8, 4.2, 8.5, 10.5), room(-5.7, 4.2, 11.5, 10.5), room(6.3, 4.2, 8.5, 10.5), room(-14.8, -2.8, 29.5, 6.5), room(-14.8, -14.8, 29.5, 11.5)],
		"points": [point(-11, 10, "POINT_PLAN"), point(11, 10, "POINT_BADGE"), point(-10, -10, "POINT_NODE"), point(0, -10, "POINT_NODE"), point(10, -10, "POINT_NODE"), point(0, 14, "POINT_EXIT")],
		"checkpoints": [Vector3(0, 0.1, 13), Vector3(-9, 0.1, 8), Vector3(8, 0.1, 8), Vector3(0, 0.1, 1)]
	}

static func level_four(root: Node3D, game: Node) -> Dictionary:
	base(root, Color("1b2033"), Color("3d405d"), Color("8a5ba6"), Color("d4b5ff"))
	F.wall_x(root, 5, -15, 15, Color("343855"), 0, 3)
	F.wall_x(root, -3, -15, 15, Color("343855"), 0, 3)
	F.wall_z(root, -5, -15, 5, Color("343855"), -8, 3)
	F.wall_z(root, 5, -15, 5, Color("343855"), -8, 3)
	F.interactable(root, Vector3(-11, 1.2, 10), "plan", "ACT_BLUEPRINT", 3, Color("d3b56c"), Vector3(0.85, 0.08, 0.6))
	F.desk(root, Vector3(-11, 0, 10), Color("424767"))
	F.interactable(root, Vector3(11, 1.0, 10), "override", "ACT_OVERRIDE", 3, Color("d3b56c"), Vector3(0.45, 0.7, 0.2))
	F.interactable(root, Vector3(-10, 1.0, -9), "relay_a", "ACT_RELAY_A", 4, Color("66558c"))
	F.interactable(root, Vector3(10, 1.0, -9), "relay_b", "ACT_RELAY_B", 4, Color("66558c"))
	F.interactable(root, Vector3(0, 1.25, -12), "core", "ACT_CORE", 4, Color("8b497b"), Vector3(2.2, 2.5, 0.6))
	for x in [-11.0, -7.0, 7.0, 11.0]:
		F.server(root, Vector3(x, 0, -12.8), Color("252943"))
	for z in [-6.0, 0.0, 9.0]:
		F.box(root, Vector3(0, 0.02, z), Vector3(1.4, 0.035, 2.3), Color("70518c"), false, 0.65)
	F.sign_text(root, Vector3(0, 2.55, 4.82), "GUARDIAN / ОПЕКУН")
	F.floor_zone(root, Vector3(0, 0, 10), Vector2(27, 6), Color("30334c"))
	F.floor_zone(root, Vector3(0, 0, -9), Vector2(8.5, 10), Color("312745"))
	F.desk(root, Vector3(-11, 0, 12), Color("4b4d6a"))
	F.monitor(root, Vector3(-11, 0.82, 12), PI, Color("c792e7"))
	for pos in [Vector3(-4.3, 0, -7), Vector3(4.3, 0, -7), Vector3(-4.3, 0, -12), Vector3(4.3, 0, -12)]:
		F.core_pylon(root, pos, Color("9a62bf"))
	F.cylinder(root, Vector3(0, 0.08, -12), 1.65, 0.16, Color("533a70"), 0.35)
	F.cylinder(root, Vector3(0, 2.8, -12), 1.45, 0.12, Color("a261c3"), 0.85)
	for x in [-1.4, 1.4]:
		F.box(root, Vector3(x, 1.4, -12), Vector3(0.12, 2.7, 0.12), Color("b578ce"), false, 0.65)
	F.light(root, Vector3(0, 2.55, -11), Color("cf75ff"), 1.3, 7.0)
	for x in [-12.0, 12.0]:
		F.light(root, Vector3(x, 2.4, 0), Color("e16b91"), 0.75, 6.0)
	F.sign_text(root, Vector3(0, 2.55, -14.45), "ЯДРО / CORE 04", Color("e0b0ff"))
	F.guard(root, Vector3(-11, 0.1, 1), [Vector3(-11,0.1,1), Vector3(11,0.1,1)], game)
	F.guard(root, Vector3(-12, 0.1, -4), [Vector3(-12,0.1,-4), Vector3(12,0.1,-4)], game)
	F.guard(root, Vector3(-3, 0.1, -8), [Vector3(-3,0.1,-8), Vector3(3,0.1,-8), Vector3(3,0.1,-13.6), Vector3(-3,0.1,-13.6)], game)
	F.guard(root, Vector3(-12, 0.1, 9), [Vector3(-12,0.1,9), Vector3(12,0.1,9)], game)
	F.security_camera(root, Vector3(-4, 2.65, 4.6), 0, game)
	F.security_camera(root, Vector3(4, 2.65, -3.4), 0, game)
	return {
		"spawn": Vector3(0, 0.1, 13),
		"capture": Vector3(0, 0.1, -4),
		"capture_yaw": 0.0,
		"rooms": [room(-14.8, 5.2, 29.5, 9.5), room(-14.8, -2.8, 29.5, 7.5), room(-14.8, -14.8, 9.5, 11.5), room(-4.7, -14.8, 9.5, 11.5), room(5.3, -14.8, 9.5, 11.5)],
		"points": [point(-11, 10, "POINT_PLAN"), point(11, 10, "POINT_BADGE"), point(-10, -9, "POINT_NODE"), point(10, -9, "POINT_NODE"), point(0, -12, "POINT_CORE")],
		"checkpoints": [Vector3(0, 0.1, 13), Vector3(-9, 0.1, 8), Vector3(8, 0.1, 8), Vector3(0, 0.1, -5)]
	}
