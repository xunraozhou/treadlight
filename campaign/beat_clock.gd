extends Node
## One clock for input, bridges, warning lines, countdown and HUD.
## System-clock synchronization follows Godot's short-song recommendation.
const BPM: float = 120.0
const SECONDS_PER_BEAT: float = 60.0 / BPM
const PERFECT: float = 0.080
const GOOD: float = 0.150
var started_usec: int = 0
var output_delay: float = 0.0
var running: bool = false
var frozen_seconds: float = 0.0
var calibration_ms: float = 0.0
var last_judged_beat: int = -100
var music: AudioStreamPlayer

func _ready() -> void:
	music = AudioStreamPlayer.new()
	var stream := load("res://campaign/audio/awakening.wav") as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2
	music.stream = stream
	music.volume_db = -10.0
	add_child(music)
	var config := ConfigFile.new()
	if config.load("user://treadlight.cfg") == OK:
		calibration_ms = config.get_value("timing", "calibration_ms", 0.0)

func start() -> void:
	last_judged_beat = -100
	frozen_seconds = 0.0
	started_usec = Time.get_ticks_usec()
	output_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	music.play(0.0)
	running = true

func seconds() -> float:
	if not running:
		return frozen_seconds
	return maxf(0.0, (Time.get_ticks_usec() - started_usec) / 1000000.0 - output_delay)

func beat() -> float:
	return seconds() / SECONDS_PER_BEAT

func pause_clock() -> void:
	frozen_seconds = seconds()
	running = false
	music.stream_paused = true

func resume_clock() -> void:
	started_usec = Time.get_ticks_usec() - int((frozen_seconds + output_delay) * 1000000.0)
	music.stream_paused = false
	running = true

func stop() -> void:
	frozen_seconds = seconds()
	running = false
	music.stop()
	music.stream_paused = false

func judge_at(time_seconds: float) -> Dictionary:
	var calibrated := time_seconds - calibration_ms / 1000.0
	var nearest := roundi(calibrated / SECONDS_PER_BEAT)
	var error := calibrated - nearest * SECONDS_PER_BEAT
	var grade := "偏拍"
	if absf(error) <= PERFECT + 0.000001:
		grade = "准确"
	elif absf(error) <= GOOD + 0.000001:
		grade = "良好"
	var accepted := grade != "偏拍" and nearest != last_judged_beat
	if accepted:
		last_judged_beat = nearest
	return {"grade": grade, "accepted": accepted, "error_ms": error * 1000.0, "beat": nearest}

func calibrate(amount_ms: float) -> void:
	calibration_ms = clampf(calibration_ms + amount_ms, -250.0, 250.0)
	var config := ConfigFile.new()
	config.set_value("timing", "calibration_ms", calibration_ms)
	config.save("user://treadlight.cfg")
