extends SceneTree

# End-to-end playthrough: title -> Start shift -> fix every crisis through its
# real path (station + minigame, or the breaker) -> survive -> shift complete.

var mm: Node
var host: Node
var room: Node


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	get_root().get_tree().paused = false
	quit(1)


func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text.contains(text):
		return node
	for child in node.get_children():
		var found := _find_button(child, text)
		if found != null:
			return found
	return null


func _frames(n: int) -> void:
	for i in n:
		await process_frame


# Opens the station's minigame and returns it, or null.
func _open(station_path: String, id: String) -> Node:
	mm.trigger(id)
	if not mm.is_active(id):
		return null
	room.get_node(station_path).interact(room.get_node("FirstPersonPlayer"))
	await _frames(2)
	return host.current


func _check_fixed(id: String, expected_fixes: int) -> bool:
	await _frames(3)
	return mm.active_id == "" and mm.fixes_count == expected_fixes and not paused


func _initialize() -> void:
	await process_frame
	mm = root.get_node("MalfunctionManager")
	host = root.get_node("MinigameHost")
	root.get_node("SaveData").set_value("tutorial_done", true)

	change_scene_to_file("res://scenes/ui/title_screen.tscn")
	await _frames(2)
	_find_button(current_scene, "Start shift").pressed.emit()
	await _frames(5)
	room = current_scene
	if room == null or room.name != "Stage1IndustrialRoom" or not mm.running:
		return _fail("Start shift did not start a run in the room")

	# O2: keypad code.
	var game: Node = await _open("MainConsole/LeftStation/O2Station", "o2")
	if game == null:
		return _fail("O2 minigame did not open")
	for digit in String(game.code):
		game.press_key(digit)
	game.press_key("ENTER")
	if not await _check_fixed("o2", 1):
		return _fail("O2 not fixed via keypad")

	# Reactor: repeat the sequence once playback finishes.
	game = await _open("MainConsole/CenterStation/ReactorStation", "reactor")
	if game == null:
		return _fail("reactor minigame did not open")
	for i in 60:
		if game.accepting_input:
			break
		await create_timer(0.1).timeout
	for index in game.sequence:
		game.press(index)
	if not await _check_fixed("reactor", 2):
		return _fail("reactor not fixed via sequence")

	# CO2: adapter checklist in order.
	game = await _open("MainConsole/RightStation/CO2Station", "co2")
	if game == null:
		return _fail("CO2 minigame did not open")
	for step in 4:
		game.press_step(step)
	if not await _check_fixed("co2", 3):
		return _fail("CO2 not fixed via adapter checklist")

	# Dust storm: valid power split.
	game = await _open("WallFixtures/SolarPanelStation/FixStation", "dust_storm")
	if game == null:
		return _fail("dust storm minigame did not open")
	game.set_allocation(0, 45)
	game.set_allocation(1, 25)
	game.set_allocation(2, 15)
	game.engage()
	if not await _check_fixed("dust_storm", 4):
		return _fail("dust storm not fixed via power balance")

	# Power: Eddie's breaker, cover open then main breaker OFF -> ON.
	mm.trigger("power")
	var breaker := room.get_node("WallFixtures/NorthDoorBreakerBox")
	breaker.interact(null)
	breaker.toggle_main_breaker()
	breaker.toggle_main_breaker()
	if not await _check_fixed("power", 5):
		return _fail("power not fixed via breaker cycle")

	# Survive to the end of the shift.
	mm.survived_seconds = mm.SHIFT_LENGTH - 0.05
	await create_timer(0.3).timeout
	var shift_complete := room.get_node("FirstPersonPlayer/HUD/ShiftComplete")
	if not shift_complete.is_showing():
		return _fail("shift complete screen not shown")

	print("PASS")
	paused = false
	quit(0)
