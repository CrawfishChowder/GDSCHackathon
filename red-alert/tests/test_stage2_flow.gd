extends SceneTree


func _initialize() -> void:
	# Autoload names are not identifiers in a --script main loop; look them up.
	var mm: Node = root.get_node("MalfunctionManager")
	var mh: Node = root.get_node("MinigameHost")


	var room_scene := load("res://scenes/stage1/stage_1_room.tscn") as PackedScene
	if room_scene == null:
		print("FAIL: Failed to load stage_1_room.tscn")
		quit(1)
		return

	var room := room_scene.instantiate()
	if room == null:
		print("FAIL: Failed to instantiate stage_1_room.tscn")
		quit(1)
		return

	root.add_child(room)
	await process_frame

	if not mm.running:
		print("FAIL: mm.running is false after instantiating room")
		quit(1)
		return

	var o2_station: Node = room.get_node_or_null("MainConsole/LeftStation/O2Station")
	if o2_station == null:
		o2_station = room.find_child("O2Station", true, false)
	if o2_station == null:
		print("FAIL: O2Station node not found")
		quit(1)
		return

	var reactor_station: Node = room.get_node_or_null("MainConsole/CenterStation/ReactorStation")
	if reactor_station == null:
		reactor_station = room.find_child("ReactorStation", true, false)
	if reactor_station == null:
		print("FAIL: ReactorStation node not found")
		quit(1)
		return

	mm.trigger("o2")
	if not o2_station.enabled:
		print("FAIL: O2Station is not enabled after trigger(\"o2\")")
		quit(1)
		return
	if reactor_station.enabled:
		print("FAIL: ReactorStation is enabled after trigger(\"o2\")")
		quit(1)
		return

	o2_station.interact(null)
	if not mh.is_open():
		print("FAIL: MinigameHost.is_open() is false after O2Station.interact(null)")
		quit(1)
		return
	if not paused:
		print("FAIL: Tree is not paused while minigame is open")
		quit(1)
		return

	if mh.current == null:
		print("FAIL: MinigameHost.current is null")
		quit(1)
		return

	mh.current.complete()
	if mm.active_id != "":
		print("FAIL: mm.active_id is not empty after complete()")
		quit(1)
		return
	if mm.fixes_count != 1:
		print("FAIL: mm.fixes_count is not 1 after complete()")
		quit(1)
		return
	if paused:
		print("FAIL: Tree is still paused after minigame completion")
		quit(1)
		return

	mm.trigger("reactor")
	if not mm.is_active("reactor"):
		print("FAIL: MalfunctionManager failed to trigger reactor")
		quit(1)
		return

	mm.time_left = 0.05
	await create_timer(0.3, true, false, true).timeout

	var game_over: Node = room.get_node_or_null("FirstPersonPlayer/HUD/GameOver")
	if game_over == null:
		game_over = room.find_child("GameOver", true, false)
	if game_over == null:
		print("FAIL: HUD GameOver node not found")
		quit(1)
		return

	if not game_over.is_showing():
		print("FAIL: GameOver.is_showing() is false after countdown expiry")
		quit(1)
		return

	print("PASS")
	quit(0)
