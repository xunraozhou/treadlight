extends SceneTree
var game: Node

func _initialize() -> void:
	call_deferred("capture")

func save_frame(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/" + name + ".png")

func capture() -> void:
	game = load("res://campaign/main.tscn").instantiate()
	root.add_child(game)
	await create_timer(0.3).timeout
	await save_frame("title")
	game.tutorial()
	await save_frame("tutorial")
	game.to_menu()
	game.start_room(0)
	game.clock.stop()
	game.clock.frozen_seconds = 2.0
	game.player.position = Vector2(715, 503)
	game.player.automation = true
	for i in range(3):
		await step(0.0)
	game.player.auto_direction = 1.0
	game.player.auto_jump = true
	for i in range(20):
		await step()
	# Both screenshots come from an actual takeoff/landing cycle.
	await save_frame("gameplay")
	for i in range(48):
		await step()
	game.player.auto_direction = 0.0
	await save_frame("restored")
	game.toggle_pause()
	await save_frame("pause")
	game.queue_free()
	await process_frame
	quit()

func step(delta: float = 1.0 / 60.0) -> void:
	game.clock.frozen_seconds += delta
	await physics_frame
	await process_frame
