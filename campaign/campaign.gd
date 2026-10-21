extends Node2D
const Clock = preload("res://campaign/beat_clock.gd")
const Runner = preload("res://campaign/player.gd")
const Bridge = preload("res://campaign/light_bridge.gd")
const Beam = preload("res://campaign/laser.gd")
const INK := Color("09151f")
const TEAL := Color("72f5d3")
const GOLD := Color("f4ca7c")
const MUTED := Color("8cabb6")
const WHITE := Color("e6f3ee")
const ROOM_NAMES = ["唤醒余音", "让光留下", "接续回响"]
const ROOM_HINTS = ["光桥前踩拍起跳 → 两拍后落在桥上 → 留下永久金桥。", "落拍修复道路，再穿过激光；金色预警一拍，实体危险一拍。", "依次修复两段光桥；全部共鸣点点亮后，终点才会开启。"]
var state: String = "menu"
var room_index: int = 0
var world: Node2D
var clock: Node
var player: CharacterBody2D
var bridges: Array = []
var lasers: Array = []
var platforms: Array[Rect2] = []
var ui: Control
var hud: Node2D
var font: SystemFont
var display_font: SystemFont
var pending_bridge: Node = null
var room_anchors: int = 0
var scroll_x: float = 0.0
var room_width: float = 2600.0
var room_score: int = 0
var room_perfect: int = 0
var room_good: int = 0
var room_miss: int = 0
var completed_scores: Array[int] = []
var deaths: int = 0
var message: String = ""
var message_left: float = 0.0
var grade_color := TEAL
var clear_light: float = 0.0
var elapsed_clear: float = 0.0
var muted: bool = false
var last_attempt_seconds: float = 0.0

func _ready() -> void:
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "WenQuanYi Micro Hei", "sans-serif"])
	display_font = SystemFont.new()
	display_font.font_names = PackedStringArray(["Bahnschrift", "DejaVu Sans", "sans-serif"])
	clock = Clock.new()
	add_child(clock)
	world = Node2D.new()
	add_child(world)
	hud = load("res://campaign/hud.gd").new()
	hud.set("game", self)
	add_child(hud)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	build_ui()

func start_room(index: int) -> void:
	clock.stop()
	for child in world.get_children():
		world.remove_child(child)
		child.queue_free()
	bridges.clear()
	lasers.clear()
	platforms.clear()
	pending_bridge = null
	room_anchors = 0
	room_index = index
	room_score = 0
	room_perfect = 0
	room_good = 0
	room_miss = 0
	clear_light = 0.0
	scroll_x = 0.0
	world.position = Vector2.ZERO
	message = "四拍准备 · 听见重音后出发"
	message_left = 2.0
	state = "playing"
	if index == 0:
		room_width = 2700.0
		add_platform(0, 480, 560)
		add_platform(480, 300, 520)
		add_bridge(780, 200, 520)
		add_platform(980, 540, 520)
		add_platform(1520, 340, 475)
		add_platform(1860, 400, 520)
		add_platform(2260, 440, 480)
	elif index == 1:
		room_width = 3000.0
		add_platform(0, 620, 560)
		add_platform(620, 340, 510)
		add_bridge(960, 200, 510)
		add_platform(1160, 640, 510)
		add_platform(1800, 420, 470)
		add_platform(2220, 780, 520)
		add_laser(1450, 482, 48, 0.0)
		add_laser(2450, 492, 48, 3.0)
	else:
		room_width = 3400.0
		add_platform(0, 500, 560)
		add_platform(500, 320, 515)
		add_bridge(820, 200, 515)
		add_platform(1020, 700, 515)
		add_platform(1720, 380, 475)
		add_bridge(2100, 200, 475)
		add_platform(2300, 600, 475)
		add_platform(2900, 500, 515)
		add_laser(1390, 487, 48, 1.0)
		add_laser(2600, 447, 48, 4.0)
	player = Runner.new()
	player.position = Vector2(110, 520)
	player.took_off.connect(on_takeoff)
	player.landed.connect(on_landing)
	world.add_child(player)
	world.show()
	clock.start()
	build_ui()

func add_platform(x: float, width: float, y: float) -> void:
	var rect := Rect2(x, y, width, 900.0 - y)
	platforms.append(rect)
	var body := StaticBody2D.new()
	body.position = rect.position
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.position = rect.size / 2.0
	body.add_child(collision)
	world.add_child(body)

func add_bridge(x: float, width: float, y: float) -> void:
	var bridge := Bridge.new()
	bridge.position = Vector2(x, y)
	bridge.width = width
	bridge.clock = clock
	world.add_child(bridge)
	bridges.append(bridge)

func add_laser(x: float, y: float, width: float, offset: float) -> void:
	var laser := Beam.new()
	laser.position = Vector2(x, y)
	laser.width = width
	laser.offset_beats = offset
	laser.clock = clock
	world.add_child(laser)
	lasers.append(laser)

func on_takeoff() -> void:
	if state != "playing" or clock.beat() < 4.0:
		return
	var result: Dictionary = clock.judge_at(clock.seconds())
	pending_bridge = null
	message = "%s  %+.0f ms" % [result.grade, result.error_ms]
	message_left = 1.1
	if not result.accepted:
		grade_color = Color("ff8ba1")
		room_miss += 1
		return
	grade_color = TEAL if result.grade == "准确" else GOLD
	if result.grade == "准确":
		room_perfect += 1
		room_score += 100
	else:
		room_good += 1
		room_score += 60
	for bridge in bridges:
		# Both shores and the active bridge allow a repair attempt. An anchored
		# bridge never consumes the attempt intended for the next broken bridge.
		if not bridge.anchored and player.position.x >= bridge.position.x - 120.0 and player.position.x <= bridge.position.x + bridge.width + 120.0 and absf(player.position.y + 17.0 - bridge.position.y) < 26.0:
			bridge.activate(clock.beat())
			pending_bridge = bridge
			message += " · 两拍后落桥留光"
			return

func on_landing() -> void:
	if state != "playing" or not is_instance_valid(pending_bridge):
		return
	var bridge: Node = pending_bridge
	pending_bridge = null
	bridge.update_at(clock.beat())
	if not bridge.active or bridge.anchored:
		return
	# Require real support by this bridge, rather than proximity to a beacon.
	if player.position.x < bridge.position.x or player.position.x > bridge.position.x + bridge.width or absf(player.position.y + 17.0 - bridge.position.y) > 3.0:
		return
	var result: Dictionary = clock.judge_at(clock.seconds())
	message_left = 1.4
	if result.accepted and bridge.anchor():
		room_anchors += 1
		room_score += 120
		grade_color = GOLD
		message = "落拍留光 · +120 · 道路已永久修复"
	else:
		grade_color = MUTED
		message = "落地偏拍 · 光桥仍会熄灭，可在两岸重试"

func tutorial() -> void:
	state = "help"
	build_ui()

func _process(delta: float) -> void:
	message_left = maxf(0.0, message_left - delta)
	if state == "playing" and is_instance_valid(player):
		scroll_x = clampf(player.position.x - 360.0, 0.0, room_width - 1280.0)
		world.position.x = -scroll_x
		player.halo_phase = fposmod(clock.beat(), 1.0)
		var restored: float = 0.55 * room_anchors / maxf(1.0, bridges.size())
		clear_light = move_toward(clear_light, restored, delta * 0.5)
	elif state in ["clear", "complete"]:
		clear_light = minf(1.0, clear_light + delta * 0.7)
	queue_redraw()
	hud.queue_redraw()

func _physics_process(_delta: float) -> void:
	if state != "playing" or not is_instance_valid(player):
		return
	player.enabled = clock.beat() >= 4.0
	if not player.enabled:
		return
	player.position.x = maxf(12.0, player.position.x)
	for laser in lasers:
		# Local world coordinates avoid the camera transform affecting collisions.
		laser.update_at(clock.beat())
		if laser.hits(player.global_position):
			fail_room("触碰激光 · 先等预警结束，或起跳越过光束")
			return
	if player.position.y > 810.0:
		fail_room("坠入暗处 · 在虚线光桥前踩拍起跳")
	elif player.position.x >= room_width - 130.0:
		if room_anchors == bridges.size():
			finish_room()
		else:
			message = "终点尚未共鸣 · 返回光桥，踩拍起跳并落桥修复"
			message_left = 1.0

func fail_room(reason: String) -> void:
	if state != "playing":
		return
	deaths += 1
	last_attempt_seconds = maxf(0.0, clock.seconds() - 2.0)
	message = reason
	state = "dead"
	player.enabled = false
	clock.pause_clock()
	build_ui()

func finish_room() -> void:
	if state != "playing" or room_anchors != bridges.size():
		return
	last_attempt_seconds = maxf(0.0, clock.seconds() - 2.0)
	completed_scores.append(room_score)
	state = "complete" if room_index == 2 else "clear"
	player.enabled = false
	clock.pause_clock()
	build_ui()

func new_journey() -> void:
	completed_scores.clear()
	deaths = 0
	start_room(0)

func next_room() -> void:
	if state == "complete":
		new_journey()
	elif state == "clear":
		start_room(room_index + 1)
	elif state == "dead":
		start_room(room_index)

func to_menu() -> void:
	clock.stop()
	if is_instance_valid(player):
		player.enabled = false
	state = "menu"
	world.hide()
	build_ui()

func toggle_pause() -> void:
	if state == "playing":
		state = "paused"
		player.enabled = false
		clock.pause_clock()
	elif state == "paused":
		state = "playing"
		clock.resume_clock()
	build_ui()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_ENTER:
			if state == "menu":
				new_journey()
			elif state in ["dead", "clear", "complete"]:
				next_room()
			elif state == "help":
				to_menu()
		KEY_R:
			if state in ["playing", "paused", "dead"]:
				start_room(room_index)
		KEY_ESCAPE:
			if state in ["playing", "paused"]:
				toggle_pause()
			elif state != "menu":
				to_menu()
		KEY_BRACKETLEFT:
			clock.calibrate(-10.0)
		KEY_BRACKETRIGHT:
			clock.calibrate(10.0)
		KEY_M:
			muted = not muted
			clock.music.volume_db = -80.0 if muted else -10.0

func button(text: String, rect: Rect2, callback: Callable, primary: bool = false) -> void:
	var item := Button.new()
	item.text = text
	item.position = rect.position
	item.size = rect.size
	item.focus_mode = Control.FOCUS_NONE
	item.add_theme_font_override("font", font)
	item.add_theme_font_size_override("font_size", 18)
	item.add_theme_color_override("font_color", INK if primary else WHITE)
	item.add_theme_color_override("font_hover_color", INK if primary else TEAL)
	for kind in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = TEAL if primary else Color("162a35")
		if kind == "hover":
			style.bg_color = Color("b0ffe7") if primary else Color("24424d")
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		item.add_theme_stylebox_override(kind, style)
	item.pressed.connect(callback)
	ui.add_child(item)

func build_ui() -> void:
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	if state == "menu":
		button("开始旅程  →", Rect2(82, 430, 222, 56), new_journey, true)
		button("玩法 / 两拍回响", Rect2(320, 430, 222, 56), tutorial)
	elif state == "help":
		button("开始旅程  →", Rect2(410, 490, 218, 52), new_journey, true)
		button("返回标题", Rect2(646, 490, 218, 52), to_menu)
	elif state == "playing":
		button("暂停 Esc", Rect2(1048, 30, 108, 36), toggle_pause)
		button("重试 R", Rect2(1168, 30, 82, 36), func(): start_room(room_index))
	elif state == "paused":
		button("继续  Esc", Rect2(410, 456, 218, 52), toggle_pause, true)
		button("返回标题", Rect2(646, 456, 218, 52), to_menu)
	elif state in ["clear", "complete", "dead"]:
		var label := "重新点亮  Enter" if state == "dead" else ("再一次旅程  Enter" if state == "complete" else "前往下一间  Enter")
		button(label, Rect2(410, 456, 258, 52), next_room, true)
		button("返回标题", Rect2(686, 456, 178, 52), to_menu)

func text_at(at: Vector2, value: String, size: int = 18, color: Color = WHITE) -> void:
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), INK.lerp(Color("163f43"), clear_light * 0.7))
	# Slow parallax ruins, dust and an eclipse establish depth without external art.
	for i in range(34):
		var x := fposmod(i * 163.0 - scroll_x * 0.2, 1400.0) - 60.0
		var height := 70.0 + fposmod(i * 71.0, 230.0)
		draw_rect(Rect2(x, 560 - height, 26 + i % 3 * 13, height + 200), Color("102b36").lerp(Color("25605c"), clear_light))
	for i in range(64):
		var x := fposmod(i * 97.3 - scroll_x * 0.08, 1280)
		var y := 122.0 + fposmod(i * 63.7, 400.0)
		draw_circle(Vector2(x, y), 1.0 if i % 3 else 1.8, Color(TEAL, 0.13 + clear_light * 0.25))
	var moon := Vector2(1020 - scroll_x * 0.03, 244)
	draw_circle(moon, 112, Color(TEAL, 0.025 + clear_light * 0.09))
	draw_arc(moon, 82, -PI * 0.8, PI * 0.65, 100, Color(TEAL, 0.2 + clear_light * 0.4), 1.4, true)
	if state in ["menu", "help"]:
		return
	for rect in platforms:
		var screen := Rect2(rect.position - Vector2(scroll_x, 0), rect.size)
		draw_rect(screen, Color("142e38").lerp(Color("285a52"), clear_light))
		draw_line(screen.position, screen.position + Vector2(screen.size.x, 0), Color("80b5b3").lerp(TEAL, clear_light), 2.0)
		for x in range(int(rect.position.x) + 22, int(rect.end.x), 64):
			draw_line(Vector2(x - scroll_x, rect.position.y + 15), Vector2(x - scroll_x, 720), Color("1b3b44"), 1)
	for bridge in bridges:
		text_at(Vector2(bridge.position.x - scroll_x + 8, bridge.position.y + 70), "共鸣已留下" if bridge.anchored else "起跳造路 · 落拍留光", 14, GOLD if bridge.anchored else Color(TEAL, 0.6))
	var goal_x := room_width - 125.0 - scroll_x
	var goal_y: float = platforms.back().position.y
	draw_rect(Rect2(goal_x - 24, goal_y - 115, 48, 115), Color(TEAL, 0.1 + clear_light * 0.2))
	var gate_open := room_anchors == bridges.size()
	var gate_color := GOLD if gate_open else MUTED
	draw_arc(Vector2(goal_x, goal_y - 62), 32, 0, TAU, 60, gate_color, 2, true)
	draw_line(Vector2(goal_x, goal_y - 90), Vector2(goal_x, goal_y - 32), gate_color, 3)
	text_at(Vector2(goal_x - 50, goal_y - 135), "共鸣之门" if gate_open else "等待共鸣", 17, gate_color)
