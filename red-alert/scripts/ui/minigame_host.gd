extends CanvasLayer

var current: Minigame = null


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	MalfunctionManager.player_died.connect(_on_player_died)
	MalfunctionManager.malfunction_fixed.connect(_on_malfunction_fixed)


func _unhandled_input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed("ui_cancel"):
		close()
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()


func open(scene: PackedScene, malfunction_id: String) -> void:
	if is_open() or scene == null:
		return

	var instance: Node = scene.instantiate()
	if not instance is Minigame:
		instance.queue_free()
		return

	current = instance as Minigame
	add_child(current)

	current.completed.connect(func() -> void:
		var sfx: Node = get_node_or_null("/root/Sfx")
		if sfx != null and sfx.has_method("play"):
			sfx.play("success")
		MalfunctionManager.fix(malfunction_id)
		close()
	)
	current.cancelled.connect(func() -> void:
		close()
	)
	current.failed.connect(func(reason: String) -> void:
		var sfx: Node = get_node_or_null("/root/Sfx")
		if sfx != null and sfx.has_method("play"):
			sfx.play("beep_error")
			var tree_for_timer := get_tree()
			if tree_for_timer != null:
				tree_for_timer.create_timer(0.25, true, false, true).timeout.connect(func() -> void:
					var sfx_fail: Node = get_node_or_null("/root/Sfx")
					if sfx_fail != null and sfx_fail.has_method("play"):
						sfx_fail.play("fail")
				)
			else:
				sfx.play("fail")
		if current != null:
			var to_free := current
			current = null
			to_free.queue_free()
		MalfunctionManager.kill(malfunction_id, "mistake", reason)
	)

	var tree := get_tree()
	if tree != null:
		tree.paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	if current == null:
		return

	var to_free := current
	current = null
	to_free.queue_free()

	var tree := get_tree()
	if tree != null:
		tree.paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func is_open() -> bool:
	return current != null


func _on_player_died(_cause_id: String, _display_name: String) -> void:
	if current == null:
		return

	var to_free := current
	current = null
	to_free.queue_free()


func _on_malfunction_fixed(_id: String) -> void:
	close()
