extends CharacterBody2D
signal took_off
const SPEED: float = 140.0
const JUMP_SPEED: float = -530.0
const GRAVITY: float = 1550.0
var enabled: bool = false
var halo_phase: float = 0.0
var accent := Color("72f5d3")
var trail: Array[Vector2] = []
var automation: bool = false
var auto_direction: float = 0.0
var auto_jump: bool = false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 8.0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(22, 34)
	shape.shape = rectangle
	add_child(shape)

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	var direction := auto_direction if automation else Input.get_axis("left", "right")
	var wants_jump := auto_jump if automation else Input.is_action_just_pressed("jump")
	auto_jump = false
	velocity.x = direction * SPEED
	velocity.y += GRAVITY * delta
	var launched := wants_jump and is_on_floor()
	if launched:
		velocity.y = JUMP_SPEED
	move_and_slide()
	# Emit only after a real grounded launch survives collision resolution.
	if launched and velocity.y < 0.0 and not is_on_floor():
		took_off.emit()
	trail.push_front(global_position)
	if trail.size() > 10:
		trail.pop_back()
	queue_redraw()

func _draw() -> void:
	for i in range(trail.size() - 1, 0, -1):
		draw_circle(to_local(trail[i]), 4.0 * (1.0 - float(i) / 10.0), Color(accent, 0.08))
	draw_arc(Vector2.ZERO, 24.0 + (1.0 - halo_phase) * 18.0, 0, TAU, 48, Color(accent, 0.15 + halo_phase * 0.3), 1.2, true)
	draw_rect(Rect2(-11, -17, 22, 34), Color("d9fff0"))
	draw_rect(Rect2(-8, -14, 16, 28), accent)
	draw_rect(Rect2(-4, -9, 11, 5), Color("102e33"))
