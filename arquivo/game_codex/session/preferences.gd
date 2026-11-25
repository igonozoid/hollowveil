extends RefCounted

const PATH := "user://preferences.cfg"
var volume := 0.8
var fullscreen := false
var effects := true

func restore() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	volume = clampf(float(config.get_value("options","volume",volume)),0.0,1.0)
	fullscreen = bool(config.get_value("options","fullscreen",fullscreen))
	effects = bool(config.get_value("options","effects",effects))

func apply() -> void:
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(volume,0.001)))
	AudioServer.set_bus_mute(0,volume == 0.0)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func save() -> Error:
	var config := ConfigFile.new()
	config.set_value("options","volume",volume)
	config.set_value("options","fullscreen",fullscreen)
	config.set_value("options","effects",effects)
	return config.save(PATH)
