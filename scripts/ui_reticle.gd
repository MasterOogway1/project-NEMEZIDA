extends Control

var active: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var center := size * 0.5
	var color := Color("8de7e4") if active else Color(0.82, 0.9, 0.92, 0.8)
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		draw_line(center + direction * 4.0, center + direction * 9.0, color, 1.25, true)
	draw_circle(center, 1.25, color)
