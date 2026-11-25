extends Node
## Estado da investigação (salvo) e preferências (salvas à parte).
## Tudo que muda o mundo passa por aqui, para que o salvamento seja um só lugar.

signal sanity_changed(value: float)
signal inventory_changed
signal flag_changed(name: String)
signal settings_changed

const SAVE_PATH := "user://investigacao.json"
const PREFS_PATH := "user://preferencias.json"
const SCHEMA := 1

# ---------------------------------------------------------------- investigação
var seed_value := 0
var view := "foyer"
var sanity := 100.0
var flags: Dictionary = {}
var solved: Dictionary = {}
var hints: Dictionary = {}
var inventory: Array = []
var drafts: Dictionary = {}
var play_time := 0.0

# ---------------------------------------------------------------- preferências
var gore := true
var effects := true
var vga := false
var music_volume := 0.8
var sfx_volume := 0.9
var fullscreen := false

var qa := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	qa = "--qa" in OS.get_cmdline_user_args()
	load_prefs()
	apply_prefs()


func _process(delta: float) -> void:
	if not get_tree().paused:
		play_time += delta


# ---------------------------------------------------------------- jogo novo
func new_game() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	seed_value = rng.randi() % 1000000
	view = "foyer"
	sanity = 100.0
	flags = {}
	solved = {}
	hints = {}
	inventory = []
	drafts = {}
	play_time = 0.0
	sanity_changed.emit(sanity)
	inventory_changed.emit()


## Semente estável de um enigma: o mesmo enigma é o mesmo na mesma volta.
func puzzle_seed(id: String) -> int:
	return hash(str(seed_value) + ":" + id)


# ---------------------------------------------------------------- bandeiras
func flag(name: String) -> bool:
	return bool(flags.get(name, false))


func set_flag(name: String, value: bool = true) -> void:
	if flag(name) == value:
		return
	flags[name] = value
	flag_changed.emit(name)


func is_solved(id: String) -> bool:
	return bool(solved.get(id, false))


func mark_solved(id: String, by_host: bool = false) -> void:
	solved[id] = true
	if by_host:
		flags["host_solved_" + id] = true
	flag_changed.emit("solved_" + id)
	save_game()


func hint_level(id: String) -> int:
	return int(hints.get(id, 0))


func use_hint(id: String) -> int:
	var level := hint_level(id) + 1
	hints[id] = level
	return level


# ---------------------------------------------------------------- sanidade
func change_sanity(amount: float) -> void:
	var before := sanity
	sanity = clampf(sanity + amount, 0.0, 100.0)
	if not is_equal_approx(before, sanity):
		sanity_changed.emit(sanity)


## 0 = lúcida, 1 = no limite. Usado pelos efeitos de alucinação.
func madness() -> float:
	return clampf(1.0 - sanity / 100.0, 0.0, 1.0)


# ---------------------------------------------------------------- inventário
func give(item: String) -> void:
	if item in inventory:
		return
	inventory.append(item)
	inventory_changed.emit()


func has(item: String) -> bool:
	return item in inventory


# ---------------------------------------------------------------- salvamento
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) and not qa


func save_game() -> void:
	if qa:
		return
	var data := {
		"schema": SCHEMA, "seed": seed_value, "view": view, "sanity": sanity,
		"flags": flags, "solved": solved, "hints": hints, "inventory": inventory,
		"drafts": drafts, "time": play_time,
	}
	var tmp := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(SAVE_PATH))


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("schema", 0)) != SCHEMA:
		return false
	seed_value = int(parsed.get("seed", 0))
	view = str(parsed.get("view", "foyer"))
	sanity = float(parsed.get("sanity", 100.0))
	flags = parsed.get("flags", {})
	solved = parsed.get("solved", {})
	hints = parsed.get("hints", {})
	inventory = parsed.get("inventory", [])
	drafts = parsed.get("drafts", {})
	play_time = float(parsed.get("time", 0.0))
	sanity_changed.emit(sanity)
	inventory_changed.emit()
	return true


# ---------------------------------------------------------------- preferências
func save_prefs() -> void:
	var f := FileAccess.open(PREFS_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"gore": gore, "effects": effects, "vga": vga, "music": music_volume,
		"sfx": sfx_volume, "fullscreen": fullscreen,
	}))


func load_prefs() -> void:
	if not FileAccess.file_exists(PREFS_PATH):
		return
	var p = JSON.parse_string(FileAccess.get_file_as_string(PREFS_PATH))
	if typeof(p) != TYPE_DICTIONARY:
		return
	gore = bool(p.get("gore", true))
	effects = bool(p.get("effects", true))
	vga = bool(p.get("vga", false))
	music_volume = float(p.get("music", 0.8))
	sfx_volume = float(p.get("sfx", 0.9))
	fullscreen = bool(p.get("fullscreen", false))


func apply_prefs() -> void:
	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
	settings_changed.emit()
