extends Node
## Trilha, efeitos e ambiente. Tudo sintetizado (synth.gd) em threads de fundo
## na primeira vez que é pedido; depois fica em memória.

signal lightning(strength: float)

const Synth := preload("res://scripts/audio/synth.gd")
## Faixas pré-geradas por tools/bake_music.gd (a mesma síntese, feita antes).
const BAKED := "res://music/%s.wav"
const SFX_NAMES := ["step", "step2", "door", "creak", "locked", "slam", "squelch", "splat",
	"pop", "heart", "whisper", "sting", "thunder", "tile", "card", "saw", "cough", "scream",
	"laugh", "solved", "wrong", "candle", "planchette", "crunch", "hover", "tick", "wind",
	"drip", "bell", "ice", "cry"]

var _sfx: Dictionary = {}
var _tracks: Dictionary = {}
var _pending: Dictionary = {}
var _mutex := Mutex.new()
var _ready_queue: Array = []
var _players: Array = []
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _wind: AudioStreamPlayer
var _current := ""
var _wanted := ""
var ambient_on := false
var _creak_t := 6.0
var _thunder_t := 14.0
var _tasks: Array = []
## Sem threads (versão para navegador): os efeitos são gerados um por quadro.
var _sfx_backlog: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "Sfx"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus)
			AudioServer.set_bus_send(idx, "Master")
	_music_a = _make_player("Music")
	_music_b = _make_player("Music")
	_wind = _make_player("Sfx")
	for i in 12:
		_players.append(_make_player("Sfx"))
	apply_volumes()
	State.settings_changed.connect(apply_volumes)
	if DisplayServer.get_name() == "headless":
		return
	if OS.has_feature("threads"):
		_tasks.append(WorkerThreadPool.add_task(_build_sfx))
	else:
		_sfx_backlog = SFX_NAMES.duplicate()
		# O vento primeiro, para o ambiente começar logo.
		_sfx_backlog.erase("wind")
		_sfx_backlog.push_front("wind")


func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func apply_volumes() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(State.music_volume, 0.001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sfx"), linear_to_db(maxf(State.sfx_volume, 0.001)))


func _build_sfx() -> void:
	for n in SFX_NAMES:
		var samples := Synth.make(n)
		_mutex.lock()
		_ready_queue.append(["sfx", n, samples])
		_mutex.unlock()


func _render_track(id: String) -> void:
	var samples := Synth.render_track(Synth.TRACKS[id])
	_mutex.lock()
	_ready_queue.append(["track", id, samples])
	_mutex.unlock()


func _process(delta: float) -> void:
	if not _sfx_backlog.is_empty():
		var n: String = _sfx_backlog.pop_front()
		_ready_queue.append(["sfx", n, Synth.make(n)])
	_mutex.lock()
	var q := _ready_queue.duplicate()
	_ready_queue.clear()
	_mutex.unlock()
	for item in q:
		if item[0] == "sfx":
			_sfx[item[1]] = Synth.to_wav(item[2], item[1] == "wind")
			if item[1] == "wind" and ambient_on:
				_start_wind()
		else:
			_tracks[item[1]] = Synth.to_wav(item[2], true)
			_pending.erase(item[1])
			if item[1] == _wanted:
				_switch(item[1])
	if ambient_on:
		_creak_t -= delta
		if _creak_t <= 0.0:
			_creak_t = randf_range(5.0, 14.0)
			play(["creak", "creak", "step2", "whisper"].pick_random(), randf_range(-20.0, -12.0), randf_range(0.7, 1.1))
		_thunder_t -= delta
		if _thunder_t <= 0.0:
			_thunder_t = randf_range(18.0, 40.0)
			var strength := randf_range(0.5, 1.0)
			lightning.emit(strength)
			get_tree().create_timer(randf_range(0.3, 1.4)).timeout.connect(
				func(): play("thunder", lerpf(-14.0, -4.0, strength), randf_range(0.8, 1.1)))


func play(name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not _sfx.has(name):
		return
	for p: AudioStreamPlayer in _players:
		if not p.playing:
			p.stream = _sfx[name]
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return


func music(id: String) -> void:
	_wanted = id
	if id == "" :
		_switch("")
		return
	if not _tracks.has(id) and ResourceLoader.exists(BAKED % id):
		_tracks[id] = load(BAKED % id)
	if _tracks.has(id):
		_switch(id)
	elif not _pending.has(id) and DisplayServer.get_name() != "headless" and OS.has_feature("threads"):
		_pending[id] = true
		_tasks.append(WorkerThreadPool.add_task(_render_track.bind(id)))


## Pré-gera as faixas mais usadas sem tocar.
func warm(ids: Array) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for id in ids:
		if not _tracks.has(id) and ResourceLoader.exists(BAKED % id):
			_tracks[id] = load(BAKED % id)
		if not _tracks.has(id) and not _pending.has(id) and OS.has_feature("threads"):
			_pending[id] = true
			_tasks.append(WorkerThreadPool.add_task(_render_track.bind(id)))


func _switch(id: String) -> void:
	if id == _current:
		return
	_current = id
	var old := _music_a if _music_a.playing else _music_b
	var nxt := _music_b if old == _music_a else _music_a
	if old.playing:
		var tw := create_tween()
		tw.tween_property(old, "volume_db", -60.0, 1.6)
		tw.tween_callback(old.stop)
	if id == "":
		return
	nxt.stream = _tracks[id]
	nxt.volume_db = -50.0
	nxt.play()
	create_tween().tween_property(nxt, "volume_db", -6.0, 2.0)


func set_ambient(on: bool) -> void:
	ambient_on = on
	if on:
		_start_wind()
	else:
		create_tween().tween_property(_wind, "volume_db", -60.0, 1.0)


func _start_wind() -> void:
	if not _sfx.has("wind"):
		return
	if not _wind.playing:
		_wind.stream = _sfx["wind"]
		_wind.volume_db = -40.0
		_wind.play()
	create_tween().tween_property(_wind, "volume_db", -16.0, 2.0)


func _exit_tree() -> void:
	for t in _tasks:
		WorkerThreadPool.wait_for_task_completion(t)
