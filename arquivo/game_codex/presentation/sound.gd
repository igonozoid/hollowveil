extends Node

var effects := AudioStreamPlayer.new()

func _ready() -> void:
	add_child(effects)
	if DisplayServer.get_name() == "headless":
		return
	var wind := AudioStreamPlayer.new()
	add_child(wind)
	wind.stream = _wave(4.0, 47.0, 61.0, true)
	wind.volume_db = -26
	wind.play()

func cue(kind: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	effects.stop()
	match kind:
		"tick": effects.stream = _wave(0.04, 870, 1280)
		"turn": effects.stream = _wave(0.10, 340, 512)
		"wrong": effects.stream = _wave(0.3, 106, 153)
		"open": effects.stream = _wave(0.85, 196, 294)
	effects.volume_db = -14 if kind == "tick" else -8
	effects.play()

func _wave(seconds: float, first: float, second: float, loop := false) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var samples := int(seconds * stream.mix_rate)
	var pcm := PackedByteArray()
	pcm.resize(samples * 2)
	for index in samples:
		var t := float(index) / stream.mix_rate
		var envelope := 0.5 - 0.5 * cos(TAU * t / seconds) if loop else exp(-6.0 * t / seconds)
		var amplitude := (sin(TAU * first * t) + 0.32 * sin(TAU * second * t)) * envelope
		pcm.encode_s16(2 * index, int(amplitude * 11000))
	stream.data = pcm
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = samples
	return stream
