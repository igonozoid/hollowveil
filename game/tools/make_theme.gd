extends SceneTree
## Gera resources/ui_theme.tres a partir de scripts/ui/theme.gd.
## Uso: godot --headless --path game --script res://tools/make_theme.gd

func _init() -> void:
	var t: Theme = load("res://scripts/ui/theme.gd").make()
	var err := ResourceSaver.save(t, "res://resources/ui_theme.tres")
	print("ui_theme.tres: ", error_string(err))
	quit()
