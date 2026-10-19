extends SceneTree
var failures: int = 0
var checks: int = 0
var game: Node
var launch_count: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)

func sample(time: float) -> Dictionary:
	game.clock.last_judged_beat = -100
	return game.clock.judge_at(time)

func tick(seconds: float = 1.0 / 60.0) -> void:
	game.clock.frozen_seconds += seconds
	await physics_frame
	await process_frame

func run() -> void:
	game = load("res://campaign/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.clock.calibration_ms = 0.0
	check(sample(2.080).grade == "准确", "+80ms is perfect")
	check(sample(1.920).grade == "准确", "-80ms is perfect")
	check(sample(2.081).grade == "良好", "+81ms is good")
	check(sample(2.150).grade == "良好", "+150ms is good")
	check(sample(1.850).grade == "良好", "-150ms is good")
	check(sample(2.151).grade == "偏拍", "+151ms misses")
	check(sample(1.849).grade == "偏拍", "-151ms misses")
	game.clock.last_judged_beat = -100
	check(game.clock.judge_at(2.0).accepted, "first jump on a beat accepted")
	check(not game.clock.judge_at(2.02).accepted, "same beat cannot score twice")
	game.clock.calibration_ms = 100.0
	check(sample(2.1).grade == "准确", "calibration shifts input judgement")
	game.clock.calibration_ms = -100.0
	check(sample(1.9).grade == "准确", "negative calibration accepts earlier input")
	game.clock.calibration_ms = 0.0
	game.start_room(0)
	game.clock.stop()
	game.clock.frozen_seconds = 2.1
	game.player.automation = true
	var bridge: Node = game.bridges[0]
	bridge.activate(4.0)
	await process_frame
	check(not bridge.shape_node.disabled, "activated bridge is physically solid")
	bridge.update_at(7.25)
	check(bridge.active and is_equal_approx(bridge.remaining, 0.75), "bridge lives through its final warning beat")
	bridge.update_at(8.0)
	await process_frame
	check(not bridge.active and bridge.shape_node.disabled, "bridge disappears at exactly four beats")
	game.start_room(1)
	game.clock.stop()
	game.clock.frozen_seconds = 2.1
	var laser: Node = game.lasers[0]
	laser.update_at(5.0)
	check(laser.warning and not laser.active, "laser warning starts one beat before fire")
	check(not laser.hits(laser.global_position), "warning line is harmless")
	laser.update_at(6.0)
	check(laser.active and not laser.warning, "laser fires on following beat")
	check(laser.hits(laser.global_position), "active beam has damage region")
	laser.update_at(7.0)
	check(not laser.active and not laser.warning, "beam clears after one beat")
	# Exercise real CharacterBody2D takeoff, not synthetic score calls.
	game.start_room(0)
	game.clock.stop()
	game.clock.frozen_seconds = 2.0
	game.player.automation = true
	for i in range(40):
		await tick(0.0)
	check(game.player.is_on_floor(), "player settles onto starting platform")
	launch_count = 0
	game.player.took_off.connect(func(): launch_count += 1)
	game.player.auto_jump = true
	await tick(0.0)
	await tick(0.0)
	check(launch_count == 1, "one grounded jump emits one launch")
	game.player.auto_jump = true
	await tick(0.0)
	check(launch_count == 1, "airborne jump cannot retrigger launch or score")
	game.toggle_pause()
	var paused_time: float = game.clock.seconds()
	await physics_frame
	await process_frame
	check(is_equal_approx(game.clock.seconds(), paused_time), "pause freezes shared clock")
	game.toggle_pause()
	check(absf(game.clock.seconds() - paused_time) < 0.05, "resume preserves clock position")
	# Retry resets all attempt state and the audio timeline.
	game.room_score = 900
	game.bridges[0].activate(8.0)
	game.start_room(0)
	check(game.room_score == 0 and game.room_perfect == 0 and game.room_good == 0 and game.room_miss == 0, "retry clears room scoring")
	check(not game.bridges[0].active and game.clock.seconds() < 0.1, "retry resets bridges and music")
	game.start_room(1)
	game.clock.stop()
	game.clock.frozen_seconds = 3.05
	game.player.position = game.lasers[0].position
	await tick(0.0)
	await tick(0.0)
	check(game.state == "dead", "touching active beam fails the room")
	game.start_room(1)
	game.clock.stop()
	game.clock.frozen_seconds = 3.1
	game.player.automation = true
	game.player.position = Vector2(game.lasers[0].position.x - 23.0, 493.0)
	await tick(0.0)
	await tick(0.0)
	game.player.auto_direction = 1.0
	game.player.auto_jump = true
	for i in range(46):
		await tick(0.0)
	check(game.state == "playing" and game.player.position.x > game.lasers[0].position.x + game.lasers[0].width + 11.0, "normal jump can clear an active horizontal beam")
	game.start_room(0)
	game.clock.stop()
	game.clock.frozen_seconds = 2.1
	game.player.position.y = 820.0
	await tick(0.0)
	check(game.state == "dead", "falling into void fails the room")
	game.completed_scores.clear()
	# Automated playthrough uses normal motion and normal jump signals.
	# The clock is stepped deterministically; physics and hazards remain enabled.
	for room in range(3):
		await traverse(room)
	check(game.completed_scores.size() == 3, "all three rooms contribute once to the journey total")
	print("TREADLIGHT TESTS: %d checks, %d failures" % [checks, failures])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)

func traverse(room: int) -> void:
	game.start_room(room)
	game.clock.stop()
	game.clock.frozen_seconds = 2.1
	game.player.automation = true
	var waiting_bridge: Node = null
	var crossed_bridges: Dictionary = {}
	var ticks: int = 0
	while game.state == "playing" and ticks < 2400:
		ticks += 1
		var p: CharacterBody2D = game.player
		p.auto_direction = 1.0
		# Step up small ledges with the same jump height as rhythm jumps.
		for platform in game.platforms:
			if platform.position.x > p.position.x and platform.position.x - p.position.x < 55.0 and platform.position.y < p.position.y + 16.0 and p.is_on_floor():
				p.auto_jump = true
		for bridge in game.bridges:
			if not crossed_bridges.has(bridge) and p.position.x > bridge.position.x - 75.0 and p.position.x < bridge.position.x:
				waiting_bridge = bridge
				p.auto_direction = 0.0
				var timing := fposmod(game.clock.seconds(), 0.5)
				if p.is_on_floor() and (timing < 0.02 or timing > 0.48):
					p.auto_jump = true
					p.auto_direction = 1.0
					crossed_bridges[bridge] = true
					waiting_bridge = null
		for laser in game.lasers:
			if p.position.x > laser.position.x - 45 and p.position.x < laser.position.x - 16:
				var phase := fposmod(game.clock.beat() - laser.offset_beats, 8.0)
				if phase > 3.5 and phase < 7.1:
					p.auto_direction = 0.0
		await tick()
	check(game.state == ("complete" if room == 2 else "clear"), "room %d can be completed through actual physics (x=%.0f, state=%s)" % [room + 1, game.player.position.x, game.state])
	check(crossed_bridges.size() == game.bridges.size(), "room %d crosses each required light bridge" % (room + 1))
	check(game.room_score >= game.bridges.size() * 60, "room %d awards rhythm score" % (room + 1))
	print("ROOM %d: %s, %.1fs simulated, score=%d, x=%.0f" % [room + 1, game.state, ticks / 60.0, game.room_score, game.player.position.x])
