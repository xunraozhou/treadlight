extends StaticBody2D
var width: float = 320.0
var expires_at: float = -1.0
var active: bool = false
var anchored: bool = false
var remaining: float = 0.0
var clock: Node
var shape_node: CollisionShape2D
var pulse: float = 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	shape_node = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 18)
	shape_node.shape = shape
	shape_node.position = Vector2(width / 2.0, 9)
	shape_node.disabled = true
	add_child(shape_node)

func activate(at_beat: float) -> void:
	if anchored:
		return
	expires_at = at_beat + 4.0
	active = true
	shape_node.set_deferred("disabled", false)
	pulse = 1.0

func anchor() -> bool:
	if anchored or not active:
		return false
	anchored = true
	active = true
	remaining = 4.0
	shape_node.set_deferred("disabled", false)
	pulse = 1.0
	return true

func update_at(at_beat: float) -> void:
	if anchored:
		queue_redraw()
		return
	remaining = maxf(0.0, expires_at - at_beat)
	if active and at_beat >= expires_at:
		active = false
		shape_node.set_deferred("disabled", true)
	queue_redraw()

func _process(delta: float) -> void:
	if clock:
		update_at(clock.beat())
	pulse = maxf(0.0, pulse - delta * 2.0)

func _draw() -> void:
	var color := Color("f4ca7c") if anchored else Color("72f5d3")
	var alpha := 1.0
	if active and not anchored and remaining <= 1.0:
		alpha = 0.35 + 0.65 * absf(sin(remaining * PI * 6.0))
	if active:
		draw_rect(Rect2(0, -8, width, 34), Color(color, 0.07 * alpha))
		draw_rect(Rect2(0, 0, width, 18), Color(color, 0.25 * alpha))
		draw_line(Vector2.ZERO, Vector2(width, 0), Color(color, alpha), 3.0)
		for x in range(8, int(width), 20):
			draw_line(Vector2(x, 7), Vector2(x + 9, 15), Color(color, 0.5 * alpha), 1.0)
		for i in range(4):
			draw_circle(Vector2(width / 2.0 + (i - 1.5) * 16.0, 32), 3, Color(color, alpha if remaining > i else 0.15))
		if anchored:
			var center := Vector2(width / 2.0, -38)
			draw_circle(center, 10, Color(color, 0.18))
			draw_colored_polygon(PackedVector2Array([center + Vector2(0, -12), center + Vector2(7, 0), center + Vector2(0, 12), center + Vector2(-7, 0)]), color)
	else:
		for x in range(0, int(width), 22):
			draw_line(Vector2(x, 0), Vector2(x + 10, 0), Color(color, 0.2), 1.0)
	if pulse > 0.0:
		draw_arc(Vector2(width / 2.0, 0), (1.0 - pulse) * width, PI, TAU, 64, Color(color, pulse * 0.5), 2, true)
