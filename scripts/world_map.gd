extends Control

var containment: float = 0.0
var title: String = ""

func _draw() -> void:
	var ocean := Color("071a2b")
	var land := Color("214c55")
	var safe := Color("4bd6a0")
	var danger := Color("e76576")
	draw_style_box(_panel(ocean), Rect2(Vector2.ZERO, size))
	var continents := [
		PackedVector2Array([Vector2(0.08,0.25),Vector2(0.19,0.15),Vector2(0.29,0.25),Vector2(0.25,0.42),Vector2(0.17,0.48),Vector2(0.1,0.39)]),
		PackedVector2Array([Vector2(0.24,0.49),Vector2(0.32,0.54),Vector2(0.35,0.72),Vector2(0.29,0.88),Vector2(0.25,0.68)]),
		PackedVector2Array([Vector2(0.43,0.25),Vector2(0.52,0.18),Vector2(0.61,0.28),Vector2(0.72,0.23),Vector2(0.88,0.34),Vector2(0.81,0.51),Vector2(0.65,0.46),Vector2(0.58,0.58),Vector2(0.49,0.46)]),
		PackedVector2Array([Vector2(0.47,0.48),Vector2(0.58,0.5),Vector2(0.61,0.69),Vector2(0.54,0.85),Vector2(0.48,0.67)]),
		PackedVector2Array([Vector2(0.79,0.68),Vector2(0.89,0.65),Vector2(0.93,0.78),Vector2(0.84,0.84)])
	]
	for polygon in continents:
		var scaled := PackedVector2Array()
		for point in polygon:
			scaled.append(point * size)
		draw_colored_polygon(scaled, land)
	var nodes := [Vector2(0.18,0.3),Vector2(0.28,0.61),Vector2(0.5,0.31),Vector2(0.55,0.58),Vector2(0.68,0.35),Vector2(0.84,0.72),Vector2(0.76,0.43)]
	for i in range(nodes.size()):
		var p: Vector2 = nodes[i] * size
		var q: Vector2 = nodes[(i + 1) % nodes.size()] * size
		draw_line(p, q, Color(0.9,0.35,0.42,0.45), 2.0, true)
		var controlled := float(i) / float(nodes.size()) * 100.0 > containment
		draw_circle(p, 8.0, danger if controlled else safe)
		draw_arc(p, 14.0, 0, TAU, 24, danger if controlled else safe, 2.0, true)
	draw_string(ThemeDB.fallback_font, Vector2(30, 38), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("d7f2f2"))
	draw_string(ThemeDB.fallback_font, Vector2(30, size.y - 28), tr("MAP_CAPTION") % int(containment), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("d7f2f2"))

func _panel(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("397384")
	style.set_border_width_all(1)
	return style
