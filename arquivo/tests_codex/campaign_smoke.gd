extends SceneTree

const MAIN := preload("res://main.tscn")
const STATE := preload("res://session/checkpoint.gd")
var game: Node
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	print(("OK " if condition else "FAIL ") + description)
	failures += int(not condition)

func press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventAction.new()
	event.action = action
	Input.parse_input_event(event)
	await process_frame

func walk(action: StringName, seconds: float) -> void:
	Input.action_press(action)
	await create_timer(seconds, true, true).timeout
	Input.action_release(action)
	await physics_frame

func run() -> void:
	if "--qa" in OS.get_cmdline_user_args():
		await run_qa()
		return
	var slot := STATE.new()
	check(not slot.solved and not FileAccess.file_exists(slot.path), "slot ausente")
	game = MAIN.instantiate()
	root.add_child(game)
	await process_frame
	check(game.menu.visible and game.menu.splash,"splash")
	game.menu.finish_splash()
	game.menu._options()
	check(game.menu.page == "options","configurações")
	game.preferences.volume = 0.0
	game.preferences.effects = false
	game.menu.options_changed.emit()
	check(AudioServer.is_bus_mute(0) and not game.film_layer.visible,"volume e efeitos aplicados")
	game.menu.open_main()
	game.menu._new_game()
	check(game.playing and game.overlay.visible,"nova investigação")
	await press("ui_cancel")
	await press("campaign_map")
	check(game.map_view.visible and game.map_view.chapter == 0 and not game.map_view.exit_open,"mapa do corredor")
	var x_at_map: float = game.actor.position.x
	await walk("walk_right",0.2)
	check(is_equal_approx(game.actor.position.x,x_at_map),"mapa suspende movimento")
	await press("campaign_map")
	check(not game.map_view.visible,"mapa fecha por M")
	await press("tutorial")
	check(game.overlay.visible and game.message.get_parsed_text().contains("painel de rondas"),"tutorial disponível por H")
	await press("ui_cancel")
	await walk("walk_left",1.4)
	check(is_equal_approx(game.actor.position.x,48.0),"limite esquerdo")
	await walk("walk_right",2.03)
	await press("inspect")
	check(game.overlay.visible and game.message.get_parsed_text().contains("PAINEL DE RONDAS"),"pista por interação")
	check(game.state.tutorial_step == 1,"tutorial avança com a pista")
	await press("ui_cancel")
	await walk("walk_right",4.98)
	await press("inspect")
	check(game.overlay.visible and game.message.get_parsed_text().contains("trinco está preso"),"porta bloqueada")
	await press("ui_cancel")
	await walk("walk_left",1.79)
	await press("inspect")
	check(game.clock.visible,"abre close-up")
	var x: float = game.actor.position.x
	await walk("walk_right",0.4)
	check(is_equal_approx(game.actor.position.x,x),"close-up suspende movimento")
	game.clock.test_button.pressed.emit()
	check(not game.state.solved and game.clock.feedback.text.contains("fechado"),"tentativa incorreta")
	game.clock.ring_buttons[0].pressed.emit()
	await press("ui_cancel")
	await press("inspect")
	check(game.clock.values == [1,0,0] and is_equal_approx(game.actor.position.x,x),"rascunho após fechar")
	game.queue_free()
	await process_frame
	await process_frame
	game = MAIN.instantiate()
	root.add_child(game)
	await process_frame
	game.menu.finish_splash()
	game.menu.resume_requested.emit()
	check(game.preferences.volume == 0.0 and not game.preferences.effects,"configurações persistem")
	check(game.state.rings == [1,0,0],"rascunho após reiniciar a cena")
	check(game.state.tutorial_step == 2,"etapa do tutorial salva")
	await press("inspect")
	game.clock.ring_buttons[0].pressed.emit()
	for i in 3:
		game.clock.ring_buttons[1].pressed.emit()
		game.clock.ring_buttons[2].pressed.emit()
	game.clock.test_button.pressed.emit()
	check(game.state.solved and game.room.unlocked,"solução libera porta")
	game.clock.test_button.pressed.emit()
	check(game.state.read_record and game.overlay.visible,"registro")
	await press("ui_cancel")
	await press("ui_cancel")
	await walk("walk_right",1.82)
	await press("inspect")
	check(game.on_landing and game.landing.visible and game.overlay.visible,"patamar acessível")
	await press("ui_cancel")
	await walk("walk_left",0.75)
	await press("inspect")
	check(game.state.chapter == 1 and game.overlay.visible,"entrada na Galeria")
	await press("ui_cancel")
	await walk("walk_right",1.16)
	await press("inspect")
	check(game.overlay.visible and game.message.get_parsed_text().contains("vizinhas"),"pista da Galeria")
	await press("ui_cancel")
	await walk("walk_right",3.21)
	await press("inspect")
	check(game.device.visible,"painel de lanternas")
	game.device.submit.pressed.emit()
	check(not game.state.wing_solved and game.device.feedback.text.contains("confere"),"erro no painel")
	game.device.keys[0].pressed.emit()
	await press("ui_cancel")
	game.queue_free()
	await process_frame
	await process_frame
	game = MAIN.instantiate()
	root.add_child(game)
	await process_frame
	game.menu.finish_splash()
	game.menu.resume_requested.emit()
	check(game.state.chapter == 1 and game.state.wing_draft == [1,1,0,0,0],"retomada da Galeria")
	await press("inspect")
	game.device.keys[2].pressed.emit()
	game.device.keys[4].pressed.emit()
	game.device.submit.pressed.emit()
	check(game.state.wing_solved and game.room.unlocked,"painel libera Arquivo")
	game.device.submit.pressed.emit()
	check(game.overlay.visible and game.message.get_parsed_text().contains("nomes"),"comprovante da Galeria")
	await press("ui_cancel")
	await press("ui_cancel")
	await walk("walk_right",1.82)
	await press("inspect")
	check(game.state.chapter == 2 and not game.state.wing_solved,"entrada no Arquivo")
	await press("ui_cancel")
	await walk("walk_right",4.37)
	await press("inspect")
	check(game.device.visible,"impressora de selos")
	for index in [0,1,2,1]:
		game.device.keys[index].pressed.emit()
	game.device.submit.pressed.emit()
	check(not game.state.wing_solved,"sequência errada rejeitada")
	game.device.reset.pressed.emit()
	check(game.state.wing_draft.is_empty(),"limpar rascunho")
	for index in [0,1,1,2]:
		game.device.keys[index].pressed.emit()
	game.device.submit.pressed.emit()
	check(game.state.wing_solved,"ordem autentica saída")
	await press("ui_cancel")
	await walk("walk_right",1.82)
	await press("inspect")
	check(game.state.chapter == 3 and game.overlay.visible and game.message.get_parsed_text().contains("PASSAGEM REABERTA"),"desfecho")
	await press("ui_cancel")
	check(game.menu.visible and game.menu.has_save,"volta ao menu após desfecho")
	var saved := STATE.new()
	saved.load_slot()
	check(saved.valid and saved.chapter == 3,"final persistido")
	game.menu._new_game()
	check(game.menu.confirmation.visible and game.state.chapter == 3,"confirmação antes de sobrescrever")
	game.menu.confirmation.hide()
	game.queue_free()
	await process_frame
	await process_frame
	quit(failures)


func run_qa() -> void:
	var slot := STATE.new()
	slot.x = 510.0
	check(slot.save() == OK,"checkpoint normal preparado")
	var before := FileAccess.get_file_as_string(slot.path)
	game = MAIN.instantiate()
	root.add_child(game)
	await process_frame
	check(game.qa_mode and game.state.x == 260.0,"modo teste inicia em sessão isolada")
	game.menu.finish_splash()
	game.menu._new_game()
	await press("ui_cancel")
	await press("qa_help")
	check(game.overlay.visible and game.message.get_parsed_text().contains("F8"),"lista de cheats")
	await press("ui_cancel")
	await press("qa_solve")
	check(game.state.solved and game.state.rings == [2,3,3],"cheat resolve relógio")
	await press("campaign_map")
	check(game.map_view.exit_open,"mapa reflete desbloqueio")
	await press("ui_cancel")
	await press("qa_advance")
	check(game.state.chapter == 1,"cheat avança à Galeria")
	await press("ui_cancel")
	await press("qa_solve")
	check(game.state.wing_solved and game.state.wing_draft == [1,0,1,0,1],"cheat resolve Galeria")
	await press("qa_reset")
	check(not game.state.wing_solved and game.state.wing_draft.is_empty(),"cheat reinicia ala")
	await press("qa_advance")
	await press("ui_cancel")
	await press("qa_solve")
	check(game.state.chapter == 2 and game.state.wing_draft == [0,1,1,2],"cheat resolve Arquivo")
	await press("qa_advance")
	check(game.state.chapter == 3 and game.overlay.visible,"cheat alcança o desfecho")
	check(FileAccess.get_file_as_string(slot.path) == before,"cheats preservam checkpoint normal")
	game.queue_free()
	await process_frame
	await process_frame
	quit(failures)
