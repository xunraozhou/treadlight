extends Node2D
## Drawn after the world so pause and result cards cover every game element.
var game: Node

func _draw() -> void:
	if game.state == "menu":
		draw_menu()
	elif game.state == "help":
		draw_help()
	else:
		draw_hud()
		if game.state != "playing":
			draw_overlay()

func text_at(at: Vector2, value: String, size: int = 18, color: Color = Color("e6f3ee")) -> void:
	draw_string(game.font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func draw_menu() -> void:
	text_at(Vector2(84, 88), "A RHYTHM PLATFORMER  /  120 BPM", 16, game.TEAL)
	draw_string(game.display_font, Vector2(78, 237), "TREADLIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 92, game.WHITE)
	text_at(Vector2(84, 298), "踏光：两拍回响", 36, game.GOLD)
	text_at(Vector2(84, 360), "起跳造路，落拍留光。", 26, game.WHITE)
	text_at(Vector2(84, 398), "让短暂的光桥，变成留得住的归途。", 18, game.MUTED)
	text_at(Vector2(84, 545), "A / D 或 ← / →  移动     空格 / W / ↑  跳跃", 18, game.WHITE)
	text_at(Vector2(84, 578), "随拍起跳造桥；两拍后落在桥上，把道路永久留下。", 17, game.MUTED)
	text_at(Vector2(84, 611), "[ / ]  判定校准：%+d ms    ·    M  音乐开关" % game.clock.calibration_ms, 16, game.MUTED)
	draw_line(Vector2(84, 652), Vector2(1196, 652), Color("29444d"), 1)
	text_at(Vector2(84, 684), "TREADLIGHT 0.2 · 律动主题原型 · 安全平台可以停留，金色道路会留下", 14, game.MUTED)
	# A miniature bridge illustrates the core mechanic on the title screen.
	draw_line(Vector2(815, 440), Vector2(1190, 440), game.TEAL, 3)
	for i in range(4):
		draw_circle(Vector2(900 + i * 42, 489), 6, game.TEAL if i < 3 else Color("29444d"))
	text_at(Vector2(840, 536), "JUMP  →  ECHO  →  RESTORE", 14, game.GOLD)

func draw_help() -> void:
	draw_rect(Rect2(265, 154, 750, 425), Color("102630"))
	draw_line(Vector2(265, 154), Vector2(1015, 154), game.TEAL, 2)
	text_at(Vector2(310, 213), "两拍回响 · 让节奏改变道路", 29, game.TEAL)
	text_at(Vector2(310, 267), "1  走近虚线桥，随底部节拍灯起跳；光桥亮起四拍。", 19)
	text_at(Vector2(310, 311), "2  保持向前，约两拍后落在桥面；踩拍落地让桥变成金色。", 18)
	text_at(Vector2(310, 355), "3  金桥永久保留，点亮全部共鸣点才能开启终点。", 19)
	text_at(Vector2(310, 399), "偏拍时普通跳跃仍有效；临时桥将消失，可从两岸再试。", 18, game.MUTED)
	text_at(Vector2(310, 443), "激光提前一拍预警。等待安全时机，也可以起跳越过。", 18, game.MUTED)

func draw_hud() -> void:
	draw_rect(Rect2(0, 0, 1280, 112), Color(game.INK, 0.94))
	text_at(Vector2(30, 48), "0%d  /  %s" % [game.room_index + 1, game.ROOM_NAMES[game.room_index]], 24)
	text_at(Vector2(30, 83), game.ROOM_HINTS[game.room_index], 16, game.MUTED)
	text_at(Vector2(766, 48), "共鸣  %d / %d" % [game.room_anchors, game.bridges.size()], 21, game.GOLD)
	text_at(Vector2(766, 81), "光能 %04d · 准确 %d / 良好 %d" % [game.room_score, game.room_perfect, game.room_good], 14, game.MUTED)
	draw_rect(Rect2(0, 624, 1280, 96), Color(game.INK, 0.96))
	var current_beat: float = game.clock.beat()
	var phase := fposmod(current_beat, 1.0)
	var beat_in_bar := int(current_beat) % 4
	for i in range(4):
		var at := Vector2(565 + i * 50, 660)
		var col: Color = game.TEAL if i == beat_in_bar else Color("2c4650")
		draw_circle(at, 8.0 + (1.0 - phase) * 3.0 if i == beat_in_bar else 8.0, col)
		draw_arc(at, 17, -PI / 2.0, -PI / 2.0 + maxf(0.01, (1.0 - phase) * TAU), 40, Color(col, 0.5), 1, true)
	text_at(Vector2(515, 705), "起跳造路  →  两拍落地留光", 15, game.MUTED)
	text_at(Vector2(30, 661), "A / D 移动     空格 起跳", 16, game.WHITE)
	text_at(Vector2(30, 692), "[ / ] 校准 %+d ms    M 音乐" % game.clock.calibration_ms, 14, game.MUTED)
	draw_rect(Rect2(940, 656, 290, 3), Color("2c4650"))
	draw_rect(Rect2(940, 656, 290 * clampf(game.player.position.x / game.room_width, 0, 1), 3), game.TEAL)
	text_at(Vector2(940, 691), "金桥永久保留 · 修复全部共鸣点", 14, game.MUTED)
	if current_beat < 4.0 and game.state == "playing":
		text_at(Vector2(535, 252), "准备  %d" % (4 - int(current_beat)), 40, game.GOLD)
	elif game.message_left > 0.0 and game.state == "playing":
		text_at(Vector2(350, 170), game.message, 22, game.grade_color)
	else:
		for bridge in game.bridges:
			if game.player.position.x > bridge.position.x - 200 and game.player.position.x < bridge.position.x and not bridge.active:
				text_at(Vector2(345, 170), "随拍起跳造路 → 向前跳 → 两拍落桥留光", 22, game.TEAL)

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
