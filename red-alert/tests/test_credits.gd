extends SceneTree


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	paused = false
	quit(1)


func _initialize() -> void:
	await process_frame

	var cs_script := load("res://scripts/ui/credits_screen.gd") as GDScript
	if cs_script == null:
		return _fail("Failed to load credits_screen.gd")

	var credits = cs_script.new()
	if credits == null:
		return _fail("Failed to instantiate credits_screen")

	root.add_child(credits)
	await process_frame

	if not credits.has_method("full_text"):
		return _fail("credits_screen does not have full_text() method")

	var text: String = credits.full_text()
	if not text.contains("Sonniss"):
		return _fail("full_text does not contain 'Sonniss'")

	if not text.contains("Godot"):
		return _fail("full_text does not contain 'Godot'")

	if not text.contains("Brandon Braswell"):
		return _fail("full_text does not contain 'Brandon Braswell'")

	var got := {}
	credits.connect("closed", func() -> void: got["closed"] = true)
	var back_btn := credits.find_child("BackButton", true, false) as Button
	if back_btn == null:
		return _fail("BackButton not found in credits_screen")
	back_btn.pressed.emit()
	if not got.get("closed", false):
		return _fail("BackButton did not emit closed signal")

	credits.queue_free()
	await process_frame

	var title_scene := load("res://scenes/ui/title_screen.tscn") as PackedScene
	if title_scene == null:
		return _fail("Failed to load title_screen.tscn")

	var title_screen = title_scene.instantiate()
	if title_screen == null:
		return _fail("Failed to instantiate title_screen")

	root.add_child(title_screen)
	await process_frame

	var found_btn: Button = null
	var buttons: Array[Node] = title_screen.find_children("*", "Button", true, false)
	for btn in buttons:
		if btn is Button and "Credits" in btn.text:
			found_btn = btn
			break

	if found_btn == null:
		return _fail("Could not find button containing 'Credits' on title screen")

	found_btn.pressed.emit()
	await process_frame

	var title_credits: Control = null
	for child in title_screen.get_children():
		if child.has_method("full_text"):
			title_credits = child
			break

	if title_credits == null or not title_credits.visible:
		return _fail("Credits screen was not opened by Credits button on title screen")

	title_credits.closed.emit()
	await process_frame
	if title_credits.visible:
		return _fail("Credits screen was not hidden after closed signal")

	title_screen.queue_free()
	await process_frame

	paused = false
	print("PASS")
	quit(0)
