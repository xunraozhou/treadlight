extends Node2D
## One beat of warning, one beat of danger, six beats clear.
var width: float = 180.0
var offset_beats: float = 0.0
var warning: bool = false
var active: bool = false
var clock: Node

func update_at(at_beat: float) -> void:
	var phase := fposmod(at_beat - offset_beats, 8.0)
	warning = phase >= 5.0 and phase < 6.0
	active = phase >= 6.0 and phase < 7.0
	queue_redraw()

func _process(_delta: float) -> void:
	if clock:
		update_at(clock.beat())

func hits(point: Vector2) -> bool:
	return active and Rect2(global_position - Vector2(11, 23), Vector2(width + 22, 46)).has_point(point)

func _draw() -> void:
	var col := Color("ff6b86")
	draw_rect(Rect2(-9, -18, 10, 36), Color("735168"))
	draw_rect(Rect2(width, -18, 10, 36), Color("735168"))
	if warning:
		for x in range(0, int(width), 18):
			draw_line(Vector2(x, 0), Vector2(x + 9, 0), Color("f4ca7c"), 2.0)
		draw_circle(Vector2(-4, 0), 4, Color("f4ca7c"))
	elif active:
		draw_rect(Rect2(0, -14, width, 28), Color(col, 0.12))
		draw_line(Vector2.ZERO, Vector2(width, 0), col, 10)
		draw_line(Vector2.ZERO, Vector2(width, 0), Color("ffe6ef"), 3)
