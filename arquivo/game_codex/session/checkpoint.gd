extends RefCounted

var rings: Array[int] = [0, 0, 0]
var solved := false
var read_record := false
var chapter := 0
var tutorial_step := 0
var wing_draft: Array[int] = []
var wing_solved := false
var valid := false
var x := 260.0
var path := "user://checkpoint.json"

func load_slot() -> void:
	if not FileAccess.file_exists(path):
		return
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return
	var data: Variant = parser.data
	if not data is Dictionary or not _integer_in(data.get("version"),1,2):
		return
	var positions: Variant = data.get("rings")
	var saved_x: Variant = data.get("x")
	if not positions is Array or positions.size() != 3:
		return
	for value: Variant in positions:
		if not (value is float or value is int) or value != int(value) or value < 0 or value > 3:
			return
	if not (saved_x is float or saved_x is int) or not is_finite(float(saved_x)):
		return
	if not data.get("solved") is bool or not data.get("read_record") is bool:
		return
	if data.version == 2:
		var stage: Variant = data.get("chapter")
		var draft: Variant = data.get("wing_draft")
		var complete: Variant = data.get("wing_solved")
		if not _integer_in(stage,0,3) or not draft is Array or not complete is bool:
			return
		if (stage == 1 and draft.size() not in [0,5]) or (stage == 2 and draft.size() > 4):
			return
		if (stage == 0 or stage == 3) and not draft.is_empty():
			return
		for value: Variant in draft:
			if not _integer_in(value,0,1 if stage == 1 else 2):
				return
		if stage > 0 and not data.solved:
			return
		chapter = int(stage)
		wing_draft.assign(draft)
		wing_solved = complete
	var step: Variant = data.get("tutorial_step",0)
	if _integer_in(step,0,2):
		tutorial_step = int(step)
	rings.assign(positions)
	valid = true
	solved = data.solved
	read_record = solved and data.read_record
	x = clampf(float(saved_x), 48, 2032)

func _integer_in(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and value >= low and value <= high and value == int(value)

func save() -> Error:
	var pending := path + ".tmp"
	var file := FileAccess.open(pending, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({
		"version": 2, "rings": rings, "solved": solved, "read_record": read_record,
		"x": x, "chapter": chapter, "tutorial_step": tutorial_step, "wing_draft": wing_draft, "wing_solved": wing_solved
	}))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	error = DirAccess.rename_absolute(pending, path)
	if error == OK:
		valid = true
	return error
