extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const Levels = preload("res://scripts/level_data.gd")
const BlueprintScript = preload("res://scripts/blueprint.gd")
const WorldMapScript = preload("res://scripts/world_map.gd")

var mode: String = "menu"
var level_root: Node3D
var player: CharacterBody3D
var current_level_data: Dictionary = {}
var level_index: int = 0
var stage: int = 0
var access: int = 0
var has_plan: bool = false
var nodes_done: Array[String] = []
var relays_done: Array[String] = []
var unlocked_level: int = 0
var has_save: bool = false
var checkpoint_data: Dictionary = {}
var alarm: float = 0.0
var last_known_player_position := Vector3.ZERO

var ui: CanvasLayer
var screen: Control
var hud: Control
var objective_label: Label
var access_label: Label
var prompt_label: Label
var subtitle_label: Label
var alarm_bar: ProgressBar
var ai_label: Label
var blueprint: Control
var message_time: float = 0.0
var tour_mode: bool = false
var tour_time: float = 0.0
var settings_return: String = "menu"
var settings: Dictionary = {"language": "ru", "volume": 0.75, "mouse": 1.0, "quality": 1, "fullscreen": false}

var sounds: Dictionary = {}
var effects: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configure_input()
	_load_settings()
	_setup_audio()
	_setup_ui()
	_load_progress_info()
	show_main_menu()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--showcase="):
			var showcase_level := clampi(argument.get_slice("=", 1).to_int(), 0, 3)
			start_level(showcase_level)
			_begin_play()
			if "--capture" in OS.get_cmdline_user_args() or "--capture-plan" in OS.get_cmdline_user_args() or "--tour" in OS.get_cmdline_user_args():
				player.position = current_level_data.get("capture", player.position)
				player.rotation.y = float(current_level_data.get("capture_yaw", 0.0))
			if "--capture-plan" in OS.get_cmdline_user_args():
				has_plan = true
				Input.action_press("plan")
			if "--tour" in OS.get_cmdline_user_args():
				tour_mode = true
		if argument == "--capture":
			_capture_after_delay()

func _process(delta: float) -> void:
	if mode == "playing" and is_instance_valid(player):
		if tour_mode:
			tour_time += delta
			if tour_time < 1.4:
				Input.action_press("move_forward")
			else:
				Input.action_release("move_forward")
				player.rotation.y -= delta * 0.22
		alarm = maxf(0.0, alarm - delta * 12.0)
		_update_hud()
		blueprint.visible = Input.is_action_pressed("plan")
		if blueprint.visible:
			blueprint.player_position = player.global_position
			blueprint.queue_redraw()
	if message_time > 0.0:
		message_time -= delta
		if message_time <= 0.0 and is_instance_valid(subtitle_label):
			subtitle_label.hide()

func _input(event: InputEvent) -> void:
	if event is InputEvent and event.is_echo():
		return
	if event.is_action_pressed("pause"):
		if mode == "playing":
			show_pause()
		elif mode == "paused":
			resume_game()
		elif mode == "settings" and settings_return == "pause":
			show_pause()
	if event.is_action_pressed("screenshot") and mode == "playing":
		take_screenshot()

func _configure_input() -> void:
	var bindings := {
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"sprint": [KEY_SHIFT],
		"crouch": [KEY_C, KEY_CTRL],
		"interact": [KEY_E],
		"plan": [KEY_TAB],
		"pause": [KEY_ESCAPE],
		"screenshot": [KEY_F12]
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func _setup_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hud)
	_full_rect(hud)
	screen = Control.new()
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(screen)
	_full_rect(screen)

func _full_rect(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _clear_screen() -> void:
	for child in screen.get_children():
		screen.remove_child(child)
		child.queue_free()

func _background(color: Color = Color(0.012, 0.025, 0.045, 0.97)) -> void:
	var background := ColorRect.new()
	background.color = color
	screen.add_child(background)
	_full_rect(background)

func _screen_box() -> VBoxContainer:
	var center := CenterContainer.new()
	screen.add_child(center)
	_full_rect(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 560
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	return box

func _label(parent: Node, text: String, font_size: int = 22, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable, disabled: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(420, 46)
	button.disabled = disabled
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func show_main_menu() -> void:
	get_tree().paused = false
	_clear_level()
	mode = "menu"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.hide()
	_clear_screen()
	_background()
	var box := _screen_box()
	_label(box, tr("GAME_TITLE"), 42)
	_label(box, tr("GAME_SUBTITLE"), 19)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 20
	box.add_child(spacer)
	_button(box, tr("MENU_NEW"), start_new_game)
	var continue_button := _button(box, tr("MENU_CONTINUE"), continue_game, not has_save)
	continue_button.tooltip_text = tr("MENU_CONTINUE")
	_button(box, tr("MENU_LEVELS"), show_level_select)
	_button(box, tr("MENU_SETTINGS"), func(): show_settings("menu"))
	_button(box, tr("MENU_QUIT"), func(): get_tree().quit())

func start_new_game() -> void:
	unlocked_level = 0
	has_save = false
	checkpoint_data.clear()
	start_level(0)

func continue_game() -> void:
	var config := ConfigFile.new()
	if config.load("user://progress.cfg") != OK:
		return
	var data: Dictionary = config.get_value("checkpoint", "data", {})
	unlocked_level = config.get_value("progress", "unlocked", 0)
	if not data.is_empty():
		start_level(int(data.get("level", 0)), data)

func show_level_select() -> void:
	get_tree().paused = false
	mode = "levels"
	_clear_level()
	hud.hide()
	_clear_screen()
	_background()
	var box := _screen_box()
	_label(box, tr("LEVEL_SELECT"), 34)
	var names := ["L1_NAME", "L2_NAME", "L3_NAME", "L4_NAME"]
	for i in range(4):
		var caption: String = "%d. %s — %s" % [i + 1, tr(names[i]), tr("LEVEL_OPEN" if i <= unlocked_level else "LEVEL_LOCKED")]
		_button(box, caption, func(): start_level(i), i > unlocked_level)
	_button(box, tr("MENU_BACK"), show_main_menu)

func start_level(index: int, saved: Dictionary = {}) -> void:
	get_tree().paused = false
	_clear_level()
	level_index = clampi(index, 0, 3)
	stage = int(saved.get("stage", 0))
	access = int(saved.get("access", level_index))
	has_plan = bool(saved.get("has_plan", false))
	nodes_done.assign(saved.get("nodes", []))
	relays_done.assign(saved.get("relays", []))
	alarm = 0.0
	mode = "briefing"
	level_root = Node3D.new()
	level_root.name = "Mission%d" % (level_index + 1)
	level_root.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(level_root)
	_setup_environment()
	current_level_data = Levels.build(level_root, level_index, self)
	player = PlayerScript.new()
	player.game = self
	player.mouse_sensitivity = 0.0022 * float(settings["mouse"])
	level_root.add_child(player)
	var spawns: Array = current_level_data["checkpoints"]
	player.position = spawns[clampi(stage, 0, spawns.size() - 1)]
	_restore_items()
	_build_hud()
	_save_checkpoint()
	_show_briefing()

func _setup_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("07111f")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("8fb9c7")
	environment.ambient_light_energy = 0.48
	world.environment = environment
	level_root.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, -32, 0)
	sun.light_color = Color("b8d4df")
	sun.light_energy = 0.65
	sun.shadow_enabled = int(settings["quality"]) == 1
	level_root.add_child(sun)

func _show_briefing() -> void:
	player.controls_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.hide()
	_clear_screen()
	_background(Color(0.01, 0.025, 0.045, 0.93))
	var box := _screen_box()
	_label(box, "%02d / 04" % (level_index + 1), 18)
	_label(box, tr("L%d_NAME" % (level_index + 1)), 34)
	_label(box, tr("BRIEF_L%d" % (level_index + 1)), 20)
	_button(box, tr("MENU_START"), _begin_play)
	_button(box, tr("MENU_MAIN"), show_main_menu)

func _begin_play() -> void:
	_clear_screen()
	mode = "playing"
	hud.show()
	player.controls_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	show_message(tr("HUD_PLAN_HINT"), 5.0)

func show_pause() -> void:
	if not is_instance_valid(player):
		return
	mode = "paused"
	player.controls_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_clear_screen()
	_background(Color(0.01, 0.02, 0.035, 0.86))
	var box := _screen_box()
	_label(box, tr("PAUSE_TITLE"), 36)
	_button(box, tr("MENU_RESUME"), resume_game)
	_button(box, tr("MENU_RESTART"), func(): start_level(level_index, checkpoint_data))
	_button(box, tr("MENU_SETTINGS"), func(): show_settings("pause"))
	_button(box, tr("MENU_MAIN"), show_main_menu)

func resume_game() -> void:
	get_tree().paused = false
	_clear_screen()
	mode = "playing"
	player.controls_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func show_settings(from: String) -> void:
	settings_return = from
	mode = "settings"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_clear_screen()
	_background()
	var box := _screen_box()
	_label(box, tr("SETTINGS_TITLE"), 34)
	_label(box, tr("SETTINGS_LANGUAGE"), 18, HORIZONTAL_ALIGNMENT_LEFT)
	var language := OptionButton.new()
	language.add_item("Русский", 0)
	language.add_item("English", 1)
	language.selected = 0 if settings["language"] == "ru" else 1
	language.item_selected.connect(_set_language)
	box.add_child(language)
	_label(box, tr("SETTINGS_VOLUME"), 18, HORIZONTAL_ALIGNMENT_LEFT)
	var volume := HSlider.new()
	volume.min_value = 0
	volume.max_value = 100
	volume.step = 1
	volume.value = float(settings["volume"]) * 100.0
	volume.value_changed.connect(func(value: float): settings["volume"] = value / 100.0; _apply_settings())
	box.add_child(volume)
	_label(box, tr("SETTINGS_MOUSE"), 18, HORIZONTAL_ALIGNMENT_LEFT)
	var mouse := HSlider.new()
	mouse.min_value = 0.4
	mouse.max_value = 2.0
	mouse.step = 0.05
	mouse.value = float(settings["mouse"])
	mouse.value_changed.connect(func(value: float): settings["mouse"] = value; _apply_settings())
	box.add_child(mouse)
	_label(box, tr("SETTINGS_QUALITY"), 18, HORIZONTAL_ALIGNMENT_LEFT)
	var quality := OptionButton.new()
	quality.add_item(tr("QUALITY_LOW"), 0)
	quality.add_item(tr("QUALITY_HIGH"), 1)
	quality.selected = int(settings["quality"])
	quality.item_selected.connect(func(index: int): settings["quality"] = index; _apply_settings())
	box.add_child(quality)
	var fullscreen := CheckButton.new()
	fullscreen.text = tr("SETTINGS_FULLSCREEN")
	fullscreen.button_pressed = bool(settings["fullscreen"])
	fullscreen.toggled.connect(func(value: bool): settings["fullscreen"] = value; _apply_settings())
	box.add_child(fullscreen)
	_button(box, tr("MENU_BACK"), _close_settings)

func _close_settings() -> void:
	_save_settings()
	if settings_return == "pause":
		show_pause()
	else:
		show_main_menu()

func _set_language(index: int) -> void:
	settings["language"] = "ru" if index == 0 else "en"
	_apply_settings()
	_save_settings()
	show_settings(settings_return)

func _apply_settings() -> void:
	TranslationServer.set_locale(settings["language"])
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.001, float(settings["volume"]))))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED)
	get_viewport().scaling_3d_scale = 0.7 if int(settings["quality"]) == 0 else 1.0
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED if int(settings["quality"]) == 0 else Viewport.MSAA_2X
	if is_instance_valid(player):
		player.mouse_sensitivity = 0.0022 * float(settings["mouse"])

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		for key in settings:
			settings[key] = config.get_value("settings", key, settings[key])
	_apply_settings()

func _save_settings() -> void:
	var config := ConfigFile.new()
	for key in settings:
		config.set_value("settings", key, settings[key])
	config.save("user://settings.cfg")

func _load_progress_info() -> void:
	var config := ConfigFile.new()
	if config.load("user://progress.cfg") == OK:
		has_save = config.has_section("checkpoint")
		unlocked_level = int(config.get_value("progress", "unlocked", 0))

func _save_checkpoint() -> void:
	checkpoint_data = {"level": level_index, "stage": stage, "access": access, "has_plan": has_plan, "nodes": nodes_done.duplicate(), "relays": relays_done.duplicate()}
	var config := ConfigFile.new()
	config.load("user://progress.cfg")
	config.set_value("progress", "unlocked", unlocked_level)
	config.set_value("checkpoint", "data", checkpoint_data)
	config.save("user://progress.cfg")
	has_save = true

func _restore_items() -> void:
	for item in get_tree().get_nodes_in_group("interactable"):
		var action: String = item.action_id
		var threshold := 99
		match level_index:
			0:
				threshold = {"plan": 1, "city_node": 2, "invite": 3}.get(action, 99)
			1:
				threshold = {"plan": 1, "badge": 2, "test_node": 3}.get(action, 99)
			2:
				threshold = {"plan": 1, "badge": 2}.get(action, 99)
				if action in nodes_done:
					item.set_completed()
			3:
				threshold = {"plan": 1, "override": 2}.get(action, 99)
				if action in relays_done:
					item.set_completed()
		if stage >= threshold:
			item.set_completed()

func _build_hud() -> void:
	for child in hud.get_children():
		hud.remove_child(child)
		child.queue_free()
	var margin := MarginContainer.new()
	hud.add_child(margin)
	_full_rect(margin)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	var top := HBoxContainer.new()
	margin.add_child(top)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(left)
	objective_label = _label(left, "", 19, HORIZONTAL_ALIGNMENT_LEFT)
	objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	access_label = _label(left, "", 16, HORIZONTAL_ALIGNMENT_LEFT)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 220
	top.add_child(right)
	var alarm_title := _label(right, tr("HUD_ALARM"), 14, HORIZONTAL_ALIGNMENT_RIGHT)
	alarm_title.modulate = Color("f39aa4")
	alarm_bar = ProgressBar.new()
	alarm_bar.max_value = 100
	alarm_bar.show_percentage = false
	alarm_bar.custom_minimum_size = Vector2(220, 12)
	right.add_child(alarm_bar)
	ai_label = _label(right, "", 15, HORIZONTAL_ALIGNMENT_RIGHT)
	var crosshair := _label(hud, "+", 24)
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-8, -22)
	prompt_label = _label(hud, "", 20)
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.offset_left = -350
	prompt_label.offset_right = 350
	prompt_label.offset_top = -105
	prompt_label.offset_bottom = -65
	subtitle_label = _label(hud, "", 19)
	subtitle_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	subtitle_label.offset_left = -520
	subtitle_label.offset_right = 520
	subtitle_label.offset_top = -195
	subtitle_label.offset_bottom = -115
	var controls := _label(hud, tr("HUD_CONTROLS"), 13)
	controls.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	controls.offset_left = -500
	controls.offset_right = 500
	controls.offset_top = -34
	controls.offset_bottom = -10
	controls.modulate = Color(0.75, 0.86, 0.9, 0.8)
	blueprint = BlueprintScript.new()
	blueprint.rooms = current_level_data["rooms"]
	blueprint.points = current_level_data["points"]
	blueprint.has_plan = has_plan
	blueprint.level_title = tr("L%d_NAME" % (level_index + 1))
	blueprint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(blueprint)
	_full_rect(blueprint)
	blueprint.hide()
	_update_hud()

func _update_hud() -> void:
	if not is_instance_valid(objective_label):
		return
	objective_label.text = "%s: %s" % [tr("HUD_OBJECTIVE"), _objective_text()]
	access_label.text = tr("HUD_ACCESS") % access
	alarm_bar.value = alarm
	blueprint.has_plan = has_plan
	if is_instance_valid(player.current_target):
		prompt_label.text = tr("HUD_INTERACT") % player.current_target.caption()
	else:
		prompt_label.text = ""
	var guards := get_tree().get_nodes_in_group("security")
	ai_label.text = ""
	for guard in guards:
		if guard.state != 0:
			ai_label.text = guard.state_caption()
			break

func _objective_text() -> String:
	match level_index:
		0:
			return tr(["OBJ_L1_PLAN", "OBJ_L1_NODE", "OBJ_L1_INVITE", "OBJ_L1_EXIT"][mini(stage, 3)])
		1:
			return tr(["OBJ_L2_PLAN", "OBJ_L2_BADGE", "OBJ_L2_NODE", "OBJ_L2_EXIT"][mini(stage, 3)])
		2:
			if stage == 2:
				return tr("OBJ_L3_NODES") % nodes_done.size()
			return tr(["OBJ_L3_PLAN", "OBJ_L3_BADGE", "OBJ_L3_NODES", "OBJ_L3_EXIT"][mini(stage, 3)])
		3:
			if stage == 2:
				return tr("OBJ_L4_RELAYS") % relays_done.size()
			return tr(["OBJ_L4_PLAN", "OBJ_L4_KEY", "OBJ_L4_RELAYS", "OBJ_L4_CORE"][mini(stage, 3)])
	return ""

func interact_with(item: Node3D) -> void:
	if mode != "playing" or not item.is_in_group("interactable"):
		return
	if item.completed and item.action_id != "distract":
		show_message(tr("MSG_ALREADY"))
		return
	if access < item.required_access:
		show_message(tr("MSG_LOCKED") % item.required_access)
		play_sound("error")
		return
	var action: String = item.action_id
	if action == "security":
		item.set_completed()
		for camera in get_tree().get_nodes_in_group("security_camera"):
			camera.disable()
		show_message(tr("MSG_CAMERAS"))
		play_sound("success")
		return
	if action == "distract":
		for guard in get_tree().get_nodes_in_group("security"):
			guard.last_known = Vector3(-12, 0.1, -12)
			guard.state = 2
			guard.state_time = 0.0
		alarm = maxf(alarm, 18.0)
		show_message(tr("MSG_DISTRACT"))
		play_sound("terminal")
		return
	if action == "overload":
		raise_alarm(72.0)
		show_message(tr("MSG_OVERLOAD"))
		play_sound("error")
		return
	var expected_stage := 0
	match action:
		"city_node", "badge": expected_stage = 1
		"invite", "test_node": expected_stage = 2
		"override": expected_stage = 1
		"exit": expected_stage = 3
		"node_a", "node_b", "node_c", "relay_a", "relay_b": expected_stage = 2
		"core": expected_stage = 3
	if action in ["node_a", "node_b", "node_c"] and level_index == 2 and stage == 3:
		show_message(tr("MSG_ALREADY"))
		return
	if stage != expected_stage:
		show_message(tr("MSG_WRONG_STAGE"))
		return
	item.set_completed()
	play_sound("terminal")
	match action:
		"plan":
			has_plan = true
			stage = 1
			show_message(tr("MSG_PLAN"))
		"city_node":
			stage = 2
			show_message(tr("MSG_CITY_NODE"))
		"invite":
			stage = 3
			show_message(tr("MSG_INVITE"), 8.0)
		"badge":
			access += 1
			stage = 2
			show_message(tr("MSG_BADGE"))
		"test_node":
			stage = 3
			show_message(tr("MSG_TEST_NODE"))
		"exit":
			complete_level()
			return
		"node_a", "node_b", "node_c":
			if action not in nodes_done:
				nodes_done.append(action)
			if nodes_done.size() >= 3:
				stage = 3
			show_message(tr("MSG_NODE"))
		"override":
			access = 4
			stage = 2
			show_message(tr("MSG_OVERRIDE"))
		"relay_a", "relay_b":
			if action not in relays_done:
				relays_done.append(action)
			if relays_done.size() >= 2:
				stage = 3
			show_message(tr("MSG_RELAY"))
		"core":
			show_final_choice()
			return
	_save_checkpoint()
	play_sound("success")

func add_detection(amount: float) -> void:
	if mode != "playing":
		return
	alarm = minf(100.0, alarm + amount)
	if alarm >= 100.0:
		player_caught()

func raise_alarm(value: float) -> void:
	last_known_player_position = player.global_position
	alarm = maxf(alarm, value)
	for guard in get_tree().get_nodes_in_group("security"):
		guard.last_known = last_known_player_position
		guard.state = 2
		guard.state_time = 0.0

func player_caught() -> void:
	if mode != "playing":
		return
	mode = "caught"
	player.controls_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_clear_screen()
	_background(Color(0.12, 0.015, 0.025, 0.9))
	var box := _screen_box()
	_label(box, tr("CAUGHT_TITLE"), 36)
	_label(box, tr("CAUGHT_TEXT"), 20)
	_button(box, tr("MENU_RETRY"), func(): start_level(level_index, checkpoint_data))
	_button(box, tr("MENU_MAIN"), show_main_menu)
	play_sound("error")

func complete_level() -> void:
	mode = "map"
	player.controls_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	unlocked_level = maxi(unlocked_level, mini(level_index + 1, 3))
	var next_level := mini(level_index + 1, 3)
	var config := ConfigFile.new()
	config.load("user://progress.cfg")
	config.set_value("progress", "unlocked", unlocked_level)
	config.set_value("checkpoint", "data", {"level": next_level, "stage": 0, "access": next_level, "has_plan": false, "nodes": [], "relays": []})
	config.save("user://progress.cfg")
	has_save = true
	hud.hide()
	_clear_screen()
	_background()
	var box := _screen_box()
	_label(box, tr("MAP_COMPLETE"), 22)
	var map := WorldMapScript.new()
	map.containment = float(level_index + 1) * 25.0
	map.title = tr("MAP_TITLE")
	map.custom_minimum_size = Vector2(820, 350)
	box.add_child(map)
	_button(box, tr("MENU_NEXT"), func(): start_level(level_index + 1))
	_button(box, tr("MENU_MAIN"), show_main_menu)
	play_sound("success")

func show_final_choice() -> void:
	mode = "final"
	player.controls_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_clear_screen()
	_background(Color(0.025, 0.015, 0.065, 0.94))
	var box := _screen_box()
	_label(box, tr("FINAL_TITLE"), 36)
	_label(box, tr("FINAL_TEXT"), 20)
	_button(box, tr("FINAL_ISOLATE"), func(): show_ending("isolate"))
	_button(box, tr("FINAL_DISTRIBUTE"), func(): show_ending("distribute"))

func show_ending(choice: String) -> void:
	mode = "ending"
	unlocked_level = 3
	var config := ConfigFile.new()
	config.load("user://progress.cfg")
	config.set_value("progress", "unlocked", 3)
	config.set_value("progress", "completed", true)
	config.save("user://progress.cfg")
	_clear_screen()
	_background(Color(0.01, 0.035, 0.045, 0.97))
	var box := _screen_box()
	var suffix := "ISOLATE" if choice == "isolate" else "DISTRIBUTE"
	_label(box, tr("ENDING_%s_TITLE" % suffix), 36)
	_label(box, tr("ENDING_%s_TEXT" % suffix), 20)
	var map := WorldMapScript.new()
	map.containment = 100.0
	map.title = tr("MAP_TITLE")
	map.custom_minimum_size = Vector2(760, 230)
	box.add_child(map)
	_label(box, tr("ENDING_CREDITS"), 15)
	_button(box, tr("MENU_MAIN"), show_main_menu)
	play_sound("success")

func show_message(text: String, duration: float = 5.0) -> void:
	if is_instance_valid(subtitle_label):
		subtitle_label.text = text
		subtitle_label.show()
		message_time = duration

func _clear_level() -> void:
	if is_instance_valid(level_root):
		remove_child(level_root)
		level_root.queue_free()
	level_root = null
	player = null
	alarm = 0.0

func _exit_tree() -> void:
	if is_instance_valid(effects):
		effects.stop()

func _setup_audio() -> void:
	effects = AudioStreamPlayer.new()
	add_child(effects)
	sounds["step"] = _tone(75.0, 0.09, 0.7)
	sounds["terminal"] = _tone(520.0, 0.18, 0.05)
	sounds["success"] = _tone(760.0, 0.32, 0.0)
	sounds["error"] = _tone(135.0, 0.4, 0.15)

func _tone(frequency: float, duration: float, noise: float) -> AudioStreamWAV:
	var rate := 22050
	var frames := int(rate * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(frequency * 100)
	for i in range(frames):
		var time := float(i) / float(rate)
		var envelope := minf(time * 40.0, 1.0) * minf((duration - time) * 18.0, 1.0)
		var sample := (sin(TAU * frequency * time) * 0.32 + rng.randf_range(-noise, noise) * 0.22) * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xff
		data[i * 2 + 1] = (value >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream

func play_sound(sound_name: String, volume: float = -7.0) -> void:
	if sounds.has(sound_name):
		effects.stream = sounds[sound_name]
		effects.volume_db = volume
		effects.play()

func _capture_after_delay() -> void:
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(subtitle_label):
		subtitle_label.hide()
	take_screenshot()

func take_screenshot() -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://screenshots")
	var filename := "user://screenshots/mission_%d_%s.png" % [level_index + 1, Time.get_datetime_string_from_system().replace(":", "-")]
	var image := get_viewport().get_texture().get_image()
	image.save_png(filename)
	print("Screenshot saved: ", ProjectSettings.globalize_path(filename))
