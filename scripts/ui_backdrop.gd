extends Control

var base_color := Color(0.012, 0.025, 0.045, 0.98)
var accent := Color("64c6d4")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), base_color)
	var minor := Color(accent, 0.045)
	var major := Color(accent, 0.085)
	for x in range(0, int(size.x) + 1, 48):
		var width := 1.0 if x % 192 == 0 else 0.5
		draw_line(Vector2(x, 0), Vector2(x, size.y), major if x % 192 == 0 else minor, width)
	for y in range(0, int(size.y) + 1, 48):
		var width := 1.0 if y % 192 == 0 else 0.5
		draw_line(Vector2(0, y), Vector2(size.x, y), major if y % 192 == 0 else minor, width)
	draw_colored_polygon(PackedVector2Array([Vector2(size.x * 0.72, 0), Vector2(size.x, 0), Vector2(size.x, size.y * 0.55)]), Color(accent, 0.025))
	draw_rect(Rect2(0, 0, size.x, 64), Color(0.005, 0.012, 0.02, 0.5))
	draw_rect(Rect2(0, size.y - 44, size.x, 44), Color(0.005, 0.012, 0.02, 0.55))
	draw_line(Vector2(28, 63), Vector2(size.x - 28, 63), Color(accent, 0.32), 1.0)
	draw_line(Vector2(28, size.y - 44), Vector2(size.x - 28, size.y - 44), Color(accent, 0.18), 1.0)
	for x in range(32, int(size.x) - 32, 96):
		draw_line(Vector2(x, 60), Vector2(x + 18, 60), Color(accent, 0.45), 1.0)
	var corner := Color(accent, 0.65)
	for origin in [Vector2(24, 82), Vector2(size.x - 24, 82), Vector2(24, size.y - 62), Vector2(size.x - 24, size.y - 62)]:
		var direction := Vector2(1 if origin.x < size.x * 0.5 else -1, 1 if origin.y < size.y * 0.5 else -1)
		draw_line(origin, origin + Vector2(direction.x * 22, 0), corner, 2.0)
		draw_line(origin, origin + Vector2(0, direction.y * 22), corner, 2.0)
