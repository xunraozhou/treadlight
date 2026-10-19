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
	game.start_room(2)
	game.clock.stop()
	game.clock.frozen_seconds = 6.55
	game.player.position = Vector2(765, 485)
	game.player.enabled = false
	game.state = "paused"
	game.bridges[0].activate(12.0)
	game.scroll_x = 400.0
	game.world.position.x = -400.0
	game.state = "playing"
	game.message = "准确  -12 ms  ·  光桥已唤醒 / 4 拍"
	# Capture one ordinary gameplay frame with the light bridge active.
	await save_frame("gameplay")
	game.toggle_pause()
	await save_frame("pause")
	game.queue_free()
	await process_frame
	quit()
