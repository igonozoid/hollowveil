extends SceneTree
## Pré-gera as faixas da trilha em game/music/*.wav com a síntese de
## scripts/audio/synth.gd. Sem isso, o jogo gera cada faixa na primeira vez
## que ela toca (alguns segundos de silêncio).
## Uso: godot --headless --path game --script res://tools/bake_music.gd [-- --all]
## Sem --all, só gera as faixas que ainda não têm arquivo.

func _init() -> void:
	var Synth = load("res://scripts/audio/synth.gd")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://music"))
	var all := "--all" in OS.get_cmdline_user_args()
	for id in Synth.TRACKS:
		if not all and FileAccess.file_exists("res://music/%s.wav" % id):
			continue
		var t0 := Time.get_ticks_msec()
		var wav: AudioStreamWAV = Synth.to_wav(Synth.render_track(Synth.TRACKS[id]), true)
		var err := wav.save_to_wav("res://music/%s.wav" % id)
		print(id, ": ", error_string(err), " em ", (Time.get_ticks_msec() - t0) / 1000.0, "s")
	quit()
