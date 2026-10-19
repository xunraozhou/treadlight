extends Node2D
## Drawn after the world so pause and result cards cover every game element.
var game: Node

func _draw() -> void:
	if game.state == "menu":
		draw_menu()
	else:
		draw_hud()
		if game.state != "playing":
			draw_overlay()

func text_at(at: Vector2, value: String, size: int = 18, color: Color = Color("e6f3ee")) -> void:
	draw_string(game.font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func draw_menu() -> void:
	text_at(Vector2(84, 88), "A RHYTHM PLATFORMER  /  120 BPM", 16, game.TEAL)
	draw_string(game.display_font, Vector2(78, 237), "TREADLIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 92, game.WHITE)
	text_at(Vector2(84, 298), "踏光：律动之旅", 36, game.GOLD)
	text_at(Vector2(84, 360), "让每一次起跳，唤醒前方的路。", 24, game.WHITE)
	text_at(Vector2(84, 398), "三个房间  /  四拍光桥  /  一束危险的光", 18, game.MUTED)
	text_at(Vector2(84, 545), "A / D 或 ← / →  移动     空格 / W / ↑  跳跃", 18, game.WHITE)
	text_at(Vector2(84, 578), "普通跳跃随时可用；在光桥前踩准节拍，让道路亮起两秒。", 17, game.MUTED)
	text_at(Vector2(84, 611), "[ / ]  判定校准：%+d ms    ·    M  音乐开关" % game.clock.calibration_ms, 16, game.MUTED)
	draw_line(Vector2(84, 652), Vector2(1196, 652), Color("29444d"), 1)
	text_at(Vector2(84, 684), "基于 FireEntity1 / LIGHT//BOUND · Apache-2.0 · 新增原创旅程模式", 14, game.MUTED)
	# A miniature bridge illustrates the core mechanic on the title screen.
	draw_line(Vector2(815, 440), Vector2(1190, 440), game.TEAL, 3)
	for i in range(4):
		draw_circle(Vector2(900 + i * 42, 489), 6, game.TEAL if i < 3 else Color("29444d"))
	text_at(Vector2(872, 536), "JUMP  →  LIGHT  →  CROSS", 14, game.TEAL)

func draw_hud() -> void:
	draw_rect(Rect2(0, 0, 1280, 112), Color(game.INK, 0.94))
	text_at(Vector2(30, 48), "0%d  /  %s" % [game.room_index + 1, game.ROOM_NAMES[game.room_index]], 24)
	text_at(Vector2(30, 83), game.ROOM_HINTS[game.room_index], 16, game.MUTED)
	text_at(Vector2(766, 48), "%04d  光能" % game.room_score, 21, game.GOLD)
	text_at(Vector2(766, 81), "准确 %d  良好 %d  偏拍 %d" % [game.room_perfect, game.room_good, game.room_miss], 14, game.MUTED)
	draw_rect(Rect2(0, 624, 1280, 96), Color(game.INK, 0.96))
	var current_beat: float = game.clock.beat()
	var phase := fposmod(current_beat, 1.0)
	var beat_in_bar := int(current_beat) % 4
	for i in range(4):
		var at := Vector2(565 + i * 50, 660)
		var col: Color = game.TEAL if i == beat_in_bar else Color("2c4650")
		draw_circle(at, 8.0 + (1.0 - phase) * 3.0 if i == beat_in_bar else 8.0, col)
		draw_arc(at, 17, -PI / 2.0, -PI / 2.0 + maxf(0.01, (1.0 - phase) * TAU), 40, Color(col, 0.5), 1, true)
	text_at(Vector2(530, 705), "120 BPM   ·   光桥持续 4 拍", 15, game.MUTED)
	text_at(Vector2(30, 661), "A / D 移动     空格 起跳", 16, game.WHITE)
	text_at(Vector2(30, 692), "[ / ] 校准 %+d ms    M 音乐" % game.clock.calibration_ms, 14, game.MUTED)
	draw_rect(Rect2(940, 656, 290, 3), Color("2c4650"))
	draw_rect(Rect2(940, 656, 290 * clampf(game.player.position.x / game.room_width, 0, 1), 3), game.TEAL)
	text_at(Vector2(940, 691), "安全平台可等待下一拍", 15, game.MUTED)
	if current_beat < 4.0 and game.state == "playing":
		text_at(Vector2(535, 252), "准备  %d" % (4 - int(current_beat)), 40, game.GOLD)
	elif game.message_left > 0.0 and game.state == "playing":
		text_at(Vector2(350, 170), game.message, 22, game.grade_color)
	else:
		for bridge in game.bridges:
			if game.player.position.x > bridge.position.x - 200 and game.player.position.x < bridge.position.x and not bridge.active:
				text_at(Vector2(405, 170), "随重音起跳 → 唤醒前方光桥", 23, game.TEAL)

func draw_overlay() -> void:
	draw_rect(Rect2(0, 112, 1280, 512), Color(game.INK, 0.78))
	draw_rect(Rect2(355, 208, 570, 330), Color("102630"))
	draw_line(Vector2(355, 208), Vector2(925, 208), game.GOLD if game.state == "dead" else game.TEAL, 2)
	var title := "光还在，重新出发。"
	var sub: String = game.message
	if game.state == "paused":
		title = "把节奏留在这里。"
		sub = "音乐、光桥和激光都已暂停。"
	elif game.state == "clear":
		title = "这个房间，亮起来了。"
		sub = "准备进入下一段旅程。"
	elif game.state == "complete":
		title = "踏光而来，万物复明。"
		sub = "三个房间全部点亮。"
	text_at(Vector2(405, 282), title, 29, game.GOLD if game.state == "dead" else game.TEAL)
	text_at(Vector2(405, 330), sub, 16, game.MUTED)
	if game.state != "paused":
		text_at(Vector2(405, 382), "本房间 %d 光能    准确 %d / 良好 %d" % [game.room_score, game.room_perfect, game.room_good], 19, game.WHITE)
		var total: int = 0
		for score in game.completed_scores:
			total += score
		text_at(Vector2(405, 419), "用时 %.1f 秒   ·   已通关光能 %d   ·   重试 %d 次" % [game.last_attempt_seconds, total, game.deaths], 16, game.MUTED)
