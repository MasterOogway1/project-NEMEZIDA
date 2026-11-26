extends Control

var rooms: Array = []
var points: Array = []
var player_position := Vector3.ZERO
var level_size := Vector2(30.0, 30.0)
var has_plan: bool = false
var level_title: String = ""

func _draw() -> void:
	var ink := Color("70d7e8")
	var dim := Color(0.18, 0.45, 0.55, 0.55)
	var paper := Color(0.015, 0.055, 0.085, 0.96)
	draw_style_box(_panel(paper, ink), Rect2(Vector2.ZERO, size))
	if not has_plan:
		draw_string(ThemeDB.fallback_font, size * 0.5 + Vector2(-150, 0), tr("PLAN_MISSING"), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, ink)
		return
	var margin := 70.0
	var available := size - Vector2(margin * 2.0, margin * 2.0)
	var scale_factor := minf(available.x / level_size.x, available.y / level_size.y)
	var origin := (size - level_size * scale_factor) * 0.5
	for room in rooms:
		var rect: Rect2 = room
		var draw_rect := Rect2(origin + rect.position * scale_factor, rect.size * scale_factor)
		draw_rect(draw_rect, dim, false, 2.0)
	for point in points:
		var pos: Vector2 = origin + Vector2(point["x"], point["z"]) * scale_factor
		draw_circle(pos, 6.0, Color("f0c76e"))
		draw_string(ThemeDB.fallback_font, pos + Vector2(10, 5), tr(point["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ink)
	var player_2d := Vector2(player_position.x, player_position.z)
	var player_draw := origin + (player_2d + level_size * 0.5) * scale_factor
	draw_circle(player_draw, 7.0, Color("ffffff"))
	draw_arc(player_draw, 13.0, 0.0, TAU, 24, Color("ffffff"), 2.0, true)
	draw_string(ThemeDB.fallback_font, Vector2(margin, 38), level_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, ink)
	draw_string(ThemeDB.fallback_font, Vector2(margin, size.y - 24), tr("PLAN_LEGEND"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, dim)

func _panel(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	return style
