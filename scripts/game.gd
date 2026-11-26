extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const Levels = preload("res://scripts/level_data.gd")
const CityData = preload("res://scripts/city_data.gd")
const CITY_LEVEL := 4
const BlueprintScript = preload("res://scripts/blueprint.gd")
const WorldMapScript = preload("res://scripts/world_map.gd")
const BackdropScript = preload("res://scripts/ui_backdrop.gd")
const ReticleScript = preload("res://scripts/ui_reticle.gd")

var mode: String = "menu"
var level_root: Node3D
var player: CharacterBody3D
var vehicle: VehicleBody3D
var driving: bool = false
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
var inventory: Dictionary = {}
var inventory_panel: PanelContainer
var inventory_slots: Dictionary = {}
var hacking: bool = false
var hack_progress: float = 0.0
var hack_target: Node3D
var hack_panel: PanelContainer
var hack_bar: ProgressBar
var hack_label: Label

var ui: CanvasLayer
var screen: Control
var hud: Control
var objective_label: Label
var access_label: Label
var prompt_label: Label
var prompt_panel: PanelContainer
var subtitle_label: Label
var subtitle_panel: PanelContainer
var alarm_bar: ProgressBar
var alarm_fill: StyleBoxFlat
var alarm_overlay: ColorRect
var ai_label: Label
var reticle: Control
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
			var showcase_level := clampi(argument.get_slice("=", 1).to_int(), 0, CITY_LEVEL)
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
		if hacking:
			hack_progress += delta
			hack_bar.value = minf(100.0, hack_progress / 3.0 * 100.0)
			hack_label.text = tr("HUD_HACKING") % int(hack_bar.value)
			if hack_progress >= 3.0:
				finish_hack()
		if tour_mode:
			tour_time += delta
			if level_index == CITY_LEVEL and is_instance_valid(vehicle):
				if not driving:
					enter_vehicle(vehicle)
				if tour_time < 3.0:
					Input.action_press("move_forward")
				else:
					Input.action_release("move_forward")
			elif tour_time < 1.4:
				Input.action_press("move_forward")
			else:
				Input.action_release("move_forward")
				player.rotation.y -= delta * 0.22
		alarm = maxf(0.0, alarm - delta * 12.0)
		_update_hud()
		blueprint.visible = Input.is_action_pressed("plan")
		if blueprint.visible:
			blueprint.player_position = vehicle.global_position if driving and is_instance_valid(vehicle) else player.global_position
			blueprint.queue_redraw()
	if message_time > 0.0:
		message_time -= delta
		if message_time <= 0.0 and is_instance_valid(subtitle_label):
			subtitle_panel.hide()

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
		"handbrake": [KEY_SPACE],
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

func _ui_style(background: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(2)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _background(color: Color = Color(0.012, 0.025, 0.045, 0.97)) -> void:
	var backdrop := BackdropScript.new()
	backdrop.base_color = color
	backdrop.accent = Color("e76576") if color.r > 0.08 else Color("a982d0") if color.b > 0.055 else Color("64c6d4")
	screen.add_child(backdrop)
	_full_rect(backdrop)

func _screen_box() -> VBoxContainer:
	var center := CenterContainer.new()
	screen.add_child(center)
	_full_rect(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 630
	panel.add_theme_stylebox_override("panel", _ui_style(Color(0.018, 0.035, 0.052, 0.94), Color(0.35, 0.72, 0.77, 0.48)))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 560
	box.add_theme_constant_override("separation", 13)
	panel.add_child(box)
	return box

func _label(parent: Node, text: String, font_size: int = 22, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("d9e6e8"))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable, disabled: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(420, 46)
	button.disabled = disabled
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("d9e6e8"))
	button.add_theme_color_override("font_hover_color", Color("ecffff"))
	button.add_theme_color_override("font_pressed_color", Color("07151c"))
	button.add_theme_color_override("font_disabled_color", Color("60727a"))
	button.add_theme_stylebox_override("normal", _ui_style(Color("102b38"), Color("315563")))
	button.add_theme_stylebox_override("hover", _ui_style(Color("174452"), Color("71ced4")))
	button.add_theme_stylebox_override("pressed", _ui_style(Color("65bdc5"), Color("a4f0ed")))
	button.add_theme_stylebox_override("disabled", _ui_style(Color("101d25"), Color("253942")))
	button.add_theme_stylebox_override("focus", _ui_style(Color(0, 0, 0, 0), Color("d6b76c"), 2))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _style_option(button: OptionButton) -> void:
	button.custom_minimum_size.y = 42
	button.add_theme_color_override("font_color", Color("d9e6e8"))
	button.add_theme_color_override("font_hover_color", Color("ecffff"))
	button.add_theme_stylebox_override("normal", _ui_style(Color("102b38"), Color("315563")))
	button.add_theme_stylebox_override("hover", _ui_style(Color("174452"), Color("71ced4")))
	button.add_theme_stylebox_override("pressed", _ui_style(Color("174452"), Color("71ced4")))
	button.add_theme_stylebox_override("focus", _ui_style(Color(0, 0, 0, 0), Color("d6b76c"), 2))

func _style_slider(slider: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color("152c37")
	track.set_corner_radius_all(2)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("59b9c2")
	fill.set_corner_radius_all(2)
	fill.content_margin_top = 3
	fill.content_margin_bottom = 3
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)

func show_main_menu() -> void:
	get_tree().paused = false
	_clear_level()
	mode = "menu"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.hide()
	_clear_screen()
	_background()
	var box := _screen_box()
	var link_label := _label(box, "ARCH-LINK  //  OFFLINE PROTOTYPE", 12, HORIZONTAL_ALIGNMENT_LEFT)
	link_label.modulate = Color("73cbd1")
	_label(box, tr("GAME_TITLE"), 38)
	_label(box, tr("GAME_SUBTITLE"), 17)
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
	start_level(CITY_LEVEL)

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
	_button(box, tr("CITY_NAME"), func(): start_level(CITY_LEVEL))
	var names := ["L1_NAME", "L2_NAME", "L3_NAME", "L4_NAME"]
	for i in range(4):
		var caption: String = "%d. %s — %s" % [i + 1, tr(names[i]), tr("LEVEL_OPEN" if i <= unlocked_level else "LEVEL_LOCKED")]
		_button(box, caption, func(): start_level(i), i > unlocked_level)
	_button(box, tr("MENU_BACK"), show_main_menu)

func start_level(index: int, saved: Dictionary = {}) -> void:
	get_tree().paused = false
	_clear_level()
	level_index = clampi(index, 0, CITY_LEVEL)
	stage = int(saved.get("stage", 0))
	access = int(saved.get("access", 0 if level_index == CITY_LEVEL else level_index))
	has_plan = true if level_index == CITY_LEVEL else bool(saved.get("has_plan", false))
	nodes_done.assign(saved.get("nodes", []))
	relays_done.assign(saved.get("relays", []))
	var saved_inventory: Dictionary = saved.get("inventory", {})
	inventory = {"badge": bool(saved_inventory.get("badge", false)), "hack": bool(saved_inventory.get("hack", false)), "gpu": bool(saved_inventory.get("gpu", false))}
	hacking = false
	hack_progress = 0.0
	hack_target = null
	alarm = 0.0
	mode = "briefing"
	level_root = Node3D.new()
	level_root.name = "City" if level_index == CITY_LEVEL else "Mission%d" % (level_index + 1)
	level_root.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(level_root)
	_setup_environment()
	current_level_data = CityData.build(level_root, self) if level_index == CITY_LEVEL else Levels.build(level_root, level_index, self)
	vehicle = current_level_data.get("vehicle")
	player = PlayerScript.new()
	player.game = self
	player.mouse_sensitivity = 0.0022 * float(settings["mouse"])
	level_root.add_child(player)
	var spawns: Array = current_level_data["checkpoints"]
	player.position = spawns[clampi(stage, 0, spawns.size() - 1)]
	if level_index == CITY_LEVEL:
		player.position = saved.get("player_position", player.position)
		if is_instance_valid(vehicle) and saved.has("vehicle"):
			vehicle.restore_data(saved["vehicle"])
	_restore_items()
	_build_hud()
	_save_checkpoint()
	_show_briefing()

func _setup_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	if level_index == CITY_LEVEL:
		var sky := Sky.new()
		var sky_material := ProceduralSkyMaterial.new()
		sky_material.sky_top_color = Color("477da0")
		sky_material.sky_horizon_color = Color("d3b58e")
		sky_material.ground_bottom_color = Color("27343b")
		sky_material.ground_horizon_color = Color("d3b58e")
		sky.sky_material = sky_material
		environment.background_mode = Environment.BG_SKY
		environment.sky = sky
	else:
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color("07111f")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b8d4df") if level_index == CITY_LEVEL else Color("8fb9c7")
	environment.ambient_light_energy = 0.7 if level_index == CITY_LEVEL else 0.48
	world.environment = environment
	level_root.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -32, 0) if level_index == CITY_LEVEL else Vector3(-58, -32, 0)
	sun.light_color = Color("ffe0b0") if level_index == CITY_LEVEL else Color("b8d4df")
	sun.light_energy = 1.15 if level_index == CITY_LEVEL else 0.65
	sun.shadow_enabled = int(settings["quality"]) == 1
	level_root.add_child(sun)

func _show_briefing() -> void:
	player.controls_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.hide()
	_clear_screen()
	_background(Color(0.01, 0.025, 0.045, 0.93))
	var box := _screen_box()
	_label(box, tr("CITY_TAG") if level_index == CITY_LEVEL else "%02d / 04" % (level_index + 1), 18)
	_label(box, tr("CITY_NAME") if level_index == CITY_LEVEL else tr("L%d_NAME" % (level_index + 1)), 34)
	_label(box, tr("BRIEF_CITY") if level_index == CITY_LEVEL else tr("BRIEF_L%d" % (level_index + 1)), 20)
	_button(box, tr("MENU_EXPLORE") if level_index == CITY_LEVEL else tr("MENU_START"), _begin_play)
	_button(box, tr("MENU_MAIN"), show_main_menu)

func _begin_play() -> void:
	_clear_screen()
	mode = "playing"
	hud.show()
	player.controls_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	show_message(tr("HUD_CITY_HINT") if level_index == CITY_LEVEL else tr("HUD_PLAN_HINT"), 6.0)

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
	player.controls_enabled = not driving and not hacking
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
	_style_option(language)
	language.item_selected.connect(_set_language)
	box.add_child(language)
	_label(box, tr("SETTINGS_VOLUME"), 18, HORIZONTAL_ALIGNMENT_LEFT)
	var volume := HSlider.new()
	volume.min_value = 0
	volume.max_value = 100
	volume.step = 1
	volume.value = float(settings["volume"]) * 100.0
	_style_slider(volume)
	volume.value_changed.connect(func(value: float): settings["volume"] = value / 100.0; _apply_settings())
	box.add_child(volume)
	_label(box, tr("SETTINGS_MOUSE"), 18, HORIZONTAL_ALIGNMENT_LEFT)
	var mouse := HSlider.new()
	mouse.min_value = 0.4
	mouse.max_value = 2.0
	mouse.step = 0.05
	mouse.value = float(settings["mouse"])
	_style_slider(mouse)
	mouse.value_changed.connect(func(value: float): settings["mouse"] = value; _apply_settings())
	box.add_child(mouse)
	_label(box, tr("SETTINGS_QUALITY"), 18, HORIZONTAL_ALIGNMENT_LEFT)
	var quality := OptionButton.new()
	quality.add_item(tr("QUALITY_LOW"), 0)
	quality.add_item(tr("QUALITY_HIGH"), 1)
	quality.selected = int(settings["quality"])
	_style_option(quality)
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
	checkpoint_data = {"level": level_index, "stage": stage, "access": access, "has_plan": has_plan, "nodes": nodes_done.duplicate(), "relays": relays_done.duplicate(), "inventory": inventory.duplicate()}
	if level_index == CITY_LEVEL and is_instance_valid(player):
		checkpoint_data["player_position"] = vehicle.exit_position() if driving and is_instance_valid(vehicle) else player.position
		if is_instance_valid(vehicle):
			checkpoint_data["vehicle"] = vehicle.save_data()
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
				threshold = {"plan": 1, "override": 2, "gpu": 4}.get(action, 99)
				if action in relays_done:
					item.set_completed()
		if stage >= threshold:
			item.set_completed()
	if bool(inventory.get("hack", false)):
		for camera in get_tree().get_nodes_in_group("security_camera"):
			camera.disable()
		for item in get_tree().get_nodes_in_group("interactable"):
			if item.action_id == "security":
				item.set_completed()

func _build_hud() -> void:
	for child in hud.get_children():
		hud.remove_child(child)
		child.queue_free()
	alarm_overlay = ColorRect.new()
	alarm_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alarm_overlay.color = Color(0.5, 0.02, 0.04, 0)
	hud.add_child(alarm_overlay)
	_full_rect(alarm_overlay)
	var margin := MarginContainer.new()
	hud.add_child(margin)
	_full_rect(margin)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	var top := HBoxContainer.new()
	top.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_theme_constant_override("separation", 16)
	margin.add_child(top)
	var objective_panel := PanelContainer.new()
	objective_panel.custom_minimum_size.x = 620
	objective_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	objective_panel.add_theme_stylebox_override("panel", _ui_style(Color(0.015, 0.035, 0.05, 0.82), Color(0.35, 0.72, 0.77, 0.42)))
	top.add_child(objective_panel)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 3)
	objective_panel.add_child(left)
	var mission_text := tr("CITY_TAG") if level_index == CITY_LEVEL else "%02d / 04" % (level_index + 1)
	var mission_tag := _label(left, "%s  //  %s" % [mission_text, tr("HUD_OBJECTIVE").to_upper()], 11, HORIZONTAL_ALIGNMENT_LEFT)
	mission_tag.modulate = Color("73cbd1")
	objective_label = _label(left, "", 18, HORIZONTAL_ALIGNMENT_LEFT)
	objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	access_label = _label(left, "", 12, HORIZONTAL_ALIGNMENT_LEFT)
	access_label.modulate = Color("91a9b1")
	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(top_spacer)
	var right_panel := PanelContainer.new()
	right_panel.custom_minimum_size.x = 260
	right_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	right_panel.add_theme_stylebox_override("panel", _ui_style(Color(0.015, 0.035, 0.05, 0.82), Color(0.35, 0.72, 0.77, 0.42)))
	top.add_child(right_panel)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 4)
	right_panel.add_child(right)
	var alarm_title := _label(right, ("VEHICLE  //  " + tr("HUD_FUEL")) if level_index == CITY_LEVEL else ("SECURITY  //  " + tr("HUD_ALARM")), 11, HORIZONTAL_ALIGNMENT_LEFT)
	alarm_title.modulate = Color("e5a1aa")
	alarm_bar = ProgressBar.new()
	alarm_bar.max_value = 100
	alarm_bar.show_percentage = false
	alarm_bar.custom_minimum_size = Vector2(220, 8)
	alarm_bar.add_theme_stylebox_override("background", _ui_style(Color("172731"), Color("304751")))
	alarm_fill = _ui_style(Color("56b9c1"), Color("56b9c1"))
	alarm_bar.add_theme_stylebox_override("fill", alarm_fill)
	right.add_child(alarm_bar)
	ai_label = _label(right, "", 12, HORIZONTAL_ALIGNMENT_LEFT)
	reticle = ReticleScript.new()
	reticle.set_anchors_preset(Control.PRESET_CENTER)
	reticle.offset_left = -12
	reticle.offset_right = 12
	reticle.offset_top = -12
	reticle.offset_bottom = 12
	hud.add_child(reticle)
	prompt_panel = PanelContainer.new()
	prompt_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_panel.offset_left = -340
	prompt_panel.offset_right = 340
	prompt_panel.offset_top = -116
	prompt_panel.offset_bottom = -66
	prompt_panel.add_theme_stylebox_override("panel", _ui_style(Color(0.015, 0.04, 0.052, 0.92), Color("65c7ce")))
	hud.add_child(prompt_panel)
	prompt_label = _label(prompt_panel, "", 18)
	prompt_panel.hide()
	subtitle_panel = PanelContainer.new()
	subtitle_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	subtitle_panel.offset_left = -500
	subtitle_panel.offset_right = 500
	subtitle_panel.offset_top = -198
	subtitle_panel.offset_bottom = -138
	subtitle_panel.add_theme_stylebox_override("panel", _ui_style(Color(0.015, 0.03, 0.042, 0.88), Color(0.4, 0.62, 0.67, 0.45)))
	hud.add_child(subtitle_panel)
	subtitle_label = _label(subtitle_panel, "", 17)
	subtitle_panel.hide()
	inventory_panel = PanelContainer.new()
	inventory_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	inventory_panel.offset_left = 24
	inventory_panel.offset_right = 332
	inventory_panel.offset_top = -174
	inventory_panel.offset_bottom = -48
	inventory_panel.add_theme_stylebox_override("panel", _ui_style(Color(0.015, 0.035, 0.05, 0.84), Color(0.35, 0.72, 0.77, 0.42)))
	hud.add_child(inventory_panel)
	var inventory_box := VBoxContainer.new()
	inventory_box.add_theme_constant_override("separation", 8)
	inventory_panel.add_child(inventory_box)
	var inventory_title := _label(inventory_box, "ARCH-LINK  //  " + tr("HUD_INVENTORY"), 11, HORIZONTAL_ALIGNMENT_LEFT)
	inventory_title.modulate = Color("73cbd1")
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 6)
	inventory_box.add_child(slots)
	inventory_slots.clear()
	for item_id in ["badge", "hack", "gpu"]:
		var slot := PanelContainer.new()
		slot.custom_minimum_size.x = 88
		slot.add_theme_stylebox_override("panel", _ui_style(Color("102630"), Color("304751")))
		slots.add_child(slot)
		var slot_box := VBoxContainer.new()
		slot.add_child(slot_box)
		_label(slot_box, tr("INV_" + item_id.to_upper()), 11)
		var status := _label(slot_box, "[  ]", 15)
		inventory_slots[item_id] = status
	hack_panel = PanelContainer.new()
	hack_panel.set_anchors_preset(Control.PRESET_CENTER)
	hack_panel.offset_left = -240
	hack_panel.offset_right = 240
	hack_panel.offset_top = -65
	hack_panel.offset_bottom = 65
	hack_panel.add_theme_stylebox_override("panel", _ui_style(Color(0.015, 0.035, 0.05, 0.96), Color("65c7ce"), 2))
	hud.add_child(hack_panel)
	var hack_box := VBoxContainer.new()
	hack_box.add_theme_constant_override("separation", 14)
	hack_panel.add_child(hack_box)
	hack_label = _label(hack_box, "", 18)
	hack_bar = ProgressBar.new()
	hack_bar.max_value = 100
	hack_bar.show_percentage = false
	hack_bar.custom_minimum_size = Vector2(320, 14)
	hack_bar.add_theme_stylebox_override("background", _ui_style(Color("172731"), Color("304751")))
	hack_bar.add_theme_stylebox_override("fill", _ui_style(Color("56b9c1"), Color("56b9c1")))
	hack_box.add_child(hack_bar)
	hack_panel.hide()
	update_inventory()
	var controls := _label(hud, tr("HUD_CITY_CONTROLS") if level_index == CITY_LEVEL else tr("HUD_CONTROLS"), 12)
	controls.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	controls.offset_left = -500
	controls.offset_right = 500
	controls.offset_top = -32
	controls.offset_bottom = -10
	controls.modulate = Color(0.7, 0.82, 0.86, 0.8)
	blueprint = BlueprintScript.new()
	blueprint.rooms = current_level_data["rooms"]
	blueprint.points = current_level_data["points"]
	blueprint.has_plan = has_plan
	blueprint.level_title = tr("CITY_NAME") if level_index == CITY_LEVEL else tr("L%d_NAME" % (level_index + 1))
	blueprint.level_size = Vector2(CityData.CITY_SIZE, CityData.CITY_SIZE) if level_index == CITY_LEVEL else Vector2(30, 30)
	blueprint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(blueprint)
	_full_rect(blueprint)
	blueprint.hide()
	_update_hud()

func update_inventory() -> void:
	for item_id in inventory_slots:
		var status: Label = inventory_slots[item_id]
		var owned := bool(inventory.get(item_id, false))
		status.text = "[X]" if owned else "[  ]"
		status.modulate = Color("7de0c4") if owned else Color("60747c")

func _update_hud() -> void:
	if not is_instance_valid(objective_label):
		return
	objective_label.text = _objective_text()
	blueprint.has_plan = has_plan
	var target_available := not driving and is_instance_valid(player.current_target)
	reticle.active = target_available
	reticle.queue_redraw()
	if level_index == CITY_LEVEL:
		access_label.text = tr("CITY_DISTRICT")
		var fuel: float = vehicle.fuel if is_instance_valid(vehicle) else 0.0
		alarm_bar.value = fuel
		alarm_fill.bg_color = Color("e76576") if fuel < 20.0 else Color("56b9c1")
		alarm_fill.border_color = alarm_fill.bg_color
		alarm_overlay.color = Color(0, 0, 0, 0)
		prompt_panel.visible = driving or target_available
		if driving:
			prompt_label.text = tr("HUD_VEHICLE_CONTROLS")
		elif target_available:
			prompt_label.text = tr("HUD_INTERACT") % player.current_target.caption()
		else:
			prompt_label.text = ""
		ai_label.text = vehicle.speed_text() if driving and is_instance_valid(vehicle) else tr("HUD_ON_FOOT")
		return
	access_label.text = tr("HUD_ACCESS") % access
	alarm_bar.value = alarm
	alarm_fill.bg_color = Color("e76576") if alarm > 55.0 else Color("d6b76c") if alarm > 20.0 else Color("56b9c1")
	alarm_fill.border_color = alarm_fill.bg_color
	alarm_overlay.color = Color(0.55, 0.02, 0.04, alarm * 0.0009)
	prompt_panel.visible = target_available
	if target_available:
		prompt_label.text = tr("HUD_INTERACT") % player.current_target.caption()
	else:
		prompt_label.text = ""
	var guards := get_tree().get_nodes_in_group("security")
	ai_label.text = "SCAN  //  CLEAR"
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
			return tr(["OBJ_L4_PLAN", "OBJ_L4_KEY", "OBJ_L4_RELAYS", "OBJ_L4_GPU", "OBJ_L4_CORE"][mini(stage, 4)])
		4:
			return tr("OBJ_CITY")
	return ""

func add_inventory(item_id: String) -> void:
	inventory[item_id] = true
	update_inventory()

func start_hack(item: Node3D) -> void:
	if hacking:
		return
	if not bool(inventory.get("badge", false)):
		show_message(tr("MSG_BADGE_REQUIRED"))
		play_sound("error")
		return
	hacking = true
	hack_progress = 0.0
	hack_target = item
	hack_bar.value = 0
	player.controls_enabled = false
	hack_panel.show()
	play_sound("terminal")

func finish_hack() -> void:
	hacking = false
	hack_panel.hide()
	if is_instance_valid(hack_target):
		hack_target.set_completed()
	add_inventory("hack")
	for camera in get_tree().get_nodes_in_group("security_camera"):
		camera.disable()
	player.controls_enabled = true
	show_message(tr("MSG_CAMERAS"))
	_save_checkpoint()
	play_sound("success")

func interact_with(item: Node3D) -> void:
	if mode != "playing" or not item.is_in_group("interactable"):
		return
	var action: String = item.action_id
	if action == "vehicle":
		enter_vehicle(item)
		return
	if action.begins_with("mission_"):
		var mission_index := action.trim_prefix("mission_").to_int()
		if mission_index > unlocked_level:
			show_message(tr("MSG_MISSION_LOCKED"))
			play_sound("error")
			return
		_save_checkpoint()
		start_level(mission_index)
		return
	if action == "city_home":
		_save_checkpoint()
		show_message(tr("MSG_CITY_HOME"))
		play_sound("success")
		return
	if item.completed and item.action_id != "distract":
		show_message(tr("MSG_ALREADY"))
		return
	if access < item.required_access:
		show_message(tr("MSG_LOCKED") % item.required_access)
		play_sound("error")
		return
	if action == "security":
		start_hack(item)
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
		"gpu": expected_stage = 3
		"core": expected_stage = 4
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
			add_inventory("badge")
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
		"gpu":
			stage = 4
			add_inventory("gpu")
			show_message(tr("MSG_GPU"))
		"core":
			show_final_choice()
			return
	_save_checkpoint()
	play_sound("success")

func enter_vehicle(car: Node3D) -> void:
	if level_index != CITY_LEVEL or driving or mode != "playing":
		return
	vehicle = car
	driving = true
	player.controls_enabled = false
	player.current_target = null
	player.collision_layer = 0
	player.collision_mask = 0
	player.set_physics_process(false)
	player.camera.current = false
	vehicle.occupied = true
	vehicle.driver_camera.current = true
	play_sound("terminal")
	_save_checkpoint()

func exit_vehicle() -> void:
	if not driving or not is_instance_valid(vehicle):
		return
	if vehicle.speed_kph > 12.0:
		show_message(tr("MSG_VEHICLE_STOP"))
		return
	var exit_pos: Vector3 = vehicle.exit_position()
	driving = false
	vehicle.occupied = false
	vehicle.engine_force = 0.0
	vehicle.brake = 4.0
	vehicle.driver_camera.current = false
	player.position = exit_pos
	player.velocity = Vector3.ZERO
	player.collision_layer = 2
	player.collision_mask = 1
	player.set_physics_process(true)
	player.camera.current = true
	player.controls_enabled = mode == "playing"
	play_sound("terminal")
	_save_checkpoint()

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
	hacking = false
	hack_target = null
	hack_panel.hide()
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
	var config := ConfigFile.new()
	config.load("user://progress.cfg")
	config.set_value("progress", "unlocked", unlocked_level)
	config.set_value("checkpoint", "data", {"level": CITY_LEVEL, "stage": 0, "access": 0, "has_plan": true, "nodes": [], "relays": [], "inventory": inventory.duplicate()})
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
	_button(box, tr("MENU_CITY"), func(): start_level(CITY_LEVEL))
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
		subtitle_panel.show()
		message_time = duration

func _clear_level() -> void:
	if is_instance_valid(level_root):
		remove_child(level_root)
		level_root.queue_free()
	level_root = null
	player = null
	vehicle = null
	driving = false
	hacking = false
	hack_target = null
	alarm = 0.0

func _exit_tree() -> void:
	if is_instance_valid(effects):
		effects.stop()

func _setup_audio() -> void:
	effects = AudioStreamPlayer.new()
	add_child(effects)
	sounds["step"] = _tone(75.0, 0.09, 0.7)
	sounds["step_wood"] = _tone(112.0, 0.085, 0.42)
	sounds["step_carpet"] = _tone(52.0, 0.13, 0.9)
	sounds["step_hard"] = _tone(78.0, 0.075, 0.68)
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

func play_footstep(surface: String, volume: float) -> void:
	var sound_name := "step_carpet" if surface == "carpet" else "step_wood" if surface == "wood" else "step_hard"
	if not sounds.has(sound_name):
		return
	effects.stream = sounds[sound_name]
	effects.volume_db = volume - 4.0 if surface == "carpet" else volume
	effects.pitch_scale = randf_range(0.96, 1.04) * (0.88 if surface == "carpet" else 1.0)
	effects.play()

func play_sound(sound_name: String, volume: float = -7.0) -> void:
	if sounds.has(sound_name):
		effects.stream = sounds[sound_name]
		effects.volume_db = volume
		effects.pitch_scale = 1.0
		effects.play()

func _capture_after_delay() -> void:
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(subtitle_label):
		subtitle_panel.hide()
	take_screenshot()

func take_screenshot() -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://screenshots")
	var filename := "user://screenshots/mission_%d_%s.png" % [level_index + 1, Time.get_datetime_string_from_system().replace(":", "-")]
	var image := get_viewport().get_texture().get_image()
	image.save_png(filename)
	print("Screenshot saved: ", ProjectSettings.globalize_path(filename))
