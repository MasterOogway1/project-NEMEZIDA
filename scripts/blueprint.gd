extends Control

var rooms: Array = []
var points: Array = []
var player_position := Vector3.ZERO
var level_size := Vector2(30.0, 30.0)
var has_plan: bool = false
var level_title: String = ""

func _draw() -> void:
	var ink := Color("8bcbd1")
	var bright := Color("d4eeee")
	var dim := Color(0.28, 0.52, 0.58, 0.62)
	var paper := Color(0.012, 0.032, 0.047, 0.97)
	draw_style_box(_panel(paper, Color(0.4, 0.72, 0.76, 0.6)), Rect2(Vector2.ZERO, size))
	for x in range(24, int(size.x), 24):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(ink, 0.035), 0.5)
	for y in range(24, int(size.y), 24):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(ink, 0.035), 0.5)
	draw_rect(Rect2(22, 22, size.x - 44, size.y - 44), Color(ink, 0.2), false, 1.0)
	draw_line(Vector2(44, 66), Vector2(size.x - 44, 66), Color(ink, 0.45), 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(46, 43), "VN  /  ARCHITECTURAL RECORD", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, dim)
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 222, 43), "SCHEMA 01  /  1:100", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, dim)
	if not has_plan:
		var center := size * 0.5
		draw_rect(Rect2(center - Vector2(170, 42), Vector2(340, 84)), Color(ink, 0.45), false, 1.0)
		draw_string(ThemeDB.fallback_font, center + Vector2(-150, 7), tr("PLAN_MISSING"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, ink)
		return
	var margin := 62.0
	var available := size - Vector2(margin * 2.0, 158.0)
	var scale_factor := minf(available.x / level_size.x, available.y / level_size.y)
	var origin := Vector2(margin, 82.0) + (available - level_size * scale_factor) * 0.5
	for room in rooms:
		var rect: Rect2 = room
		var draw_rect := Rect2(origin + rect.position * scale_factor, rect.size * scale_factor)
		draw_rect(draw_rect, Color(0.12, 0.32, 0.37, 0.2), true)
		draw_rect(draw_rect, dim, false, 2.0)
		var inner := draw_rect.grow(-4.0)
		if inner.size.x > 0 and inner.size.y > 0:
			draw_rect(inner, Color(ink, 0.1), false, 0.5)
	for point in points:
		var pos: Vector2 = origin + Vector2(point["x"], point["z"]) * scale_factor
		var marker := PackedVector2Array([pos + Vector2(0, -7), pos + Vector2(7, 0), pos + Vector2(0, 7), pos + Vector2(-7, 0)])
		draw_colored_polygon(marker, Color("e0bc68"))
		draw_arc(pos, 12.0, 0.0, TAU, 24, Color(0.88, 0.73, 0.4, 0.35), 1.0, true)
		draw_string(ThemeDB.fallback_font, pos + Vector2(15, 5), tr(point["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, bright)
	var player_2d := Vector2(player_position.x, player_position.z)
	var player_draw := origin + (player_2d + level_size * 0.5) * scale_factor
	draw_circle(player_draw, 5.0, bright)
	draw_arc(player_draw, 12.0, 0.0, TAU, 32, bright, 1.5, true)
	draw_line(player_draw + Vector2(0, -17), player_draw + Vector2(0, -25), bright, 2.0, true)
	draw_string(ThemeDB.fallback_font, Vector2(margin, 102), level_title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, bright)
	var footer := size.y - 46.0
	draw_line(Vector2(44, footer - 10), Vector2(size.x - 44, footer - 10), Color(ink, 0.25), 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(margin, footer + 14), tr("PLAN_LEGEND"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, dim)
	for i in range(5):
		var segment := Rect2(Vector2(size.x - 220 + i * 24, footer), Vector2(24, 5))
		draw_rect(segment, ink if i % 2 == 0 else Color(ink, 0.2), true)
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 220, footer + 24), "0        2.5        5 M", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, dim)

func _panel(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	return style
