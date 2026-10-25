# Manages minigame overlays across the station, routing completed, failed,
# and cancelled signals, pausing the game during minigames, and reliably
# restoring mouse look and unpausing when minigames dismiss.
extends CanvasLayer

var current: Minigame = null


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	var mm: Node = get_node_or_null("/root/MalfunctionManager")
	if mm != null and mm.has_signal("player_died"):
		mm.player_died.connect(_on_player_died)
	if mm != null and mm.has_signal("malfunction_fixed"):
		mm.malfunction_fixed.connect(_on_malfunction_fixed)


func _unhandled_input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed("ui_cancel"):
		close()
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()


# Instantiates and displays a minigame scene over the viewport.
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
		var mm: Node = get_node_or_null("/root/MalfunctionManager")
		if mm != null and mm.has_method("fix"):
			mm.fix(malfunction_id)
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
					if not is_inside_tree():
						return
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
		var mm: Node = get_node_or_null("/root/MalfunctionManager")
		if mm != null and mm.has_method("kill"):
			mm.kill(malfunction_id, "mistake", reason)
		if mm != null and bool(mm.get("running")):
			_resume_play()
	)

	var tree := get_tree()
	if tree != null:
		tree.paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# Closes any active minigame and unpauses gameplay.
func close() -> void:
	if current == null:
		return

	var to_free := current
	current = null
	to_free.queue_free()

	_resume_play()


# Unpauses tree and restores mouse look via player or direct capture.
func _resume_play() -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.paused = false
	var scene := tree.current_scene
	var player: Node = scene.get_node_or_null("FirstPersonPlayer") if scene != null else null
	if player != null and player.has_method("resume_mouse_look"):
		player.resume_mouse_look()
	else:
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
