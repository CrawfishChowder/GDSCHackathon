extends SceneTree

var got := {}


func _fail(reason: String) -> void:
	paused = false
	print("FAIL: " + reason)
	quit(1)


func _pass() -> void:
	paused = false
	print("PASS")
	quit(0)


func _find_named_node(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child: Node in node.get_children():
		var found: Node = _find_named_node(child, target_name)
		if found != null:
			return found
	return null


func _find_button_by_text(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text:
		return node as Button
	for child: Node in node.get_children():
		var found: Button = _find_button_by_text(child, text)
		if found != null:
			return found
	return null


func _find_label_containing(node: Node, needle: String) -> Label:
	if node is Label and (node as Label).text.contains(needle):
		return node as Label
	for child: Node in node.get_children():
		var found: Label = _find_label_containing(child, needle)
		if found != null:
			return found
	return null


func _initialize() -> void:
	await process_frame

	var title_scene := load("res://scenes/ui/title_screen.tscn") as PackedScene
	if title_scene == null:
		return _fail("Failed to load title_screen.tscn")

	var screen: Node = title_scene.instantiate()
	if screen == null:
		return _fail("Failed to instantiate title_screen.tscn")

	root.add_child(screen)
	await process_frame
	await process_frame

	# 1. Assert a TitleBackground child exists with a ShaderMaterial
	var bg_child: CanvasItem = null
	for child: Node in screen.get_children():
		if child.name == "TitleBackground" or (child is ColorRect and child.material is ShaderMaterial):
			bg_child = child as CanvasItem
			break
	if bg_child == null:
		bg_child = _find_named_node(screen, "TitleBackground") as CanvasItem

	if bg_child == null:
		return _fail("TitleBackground child not found on title screen")

	if not (bg_child.material is ShaderMaterial):
		return _fail("TitleBackground material is not a ShaderMaterial")

	# 2. Assert that the "Start shift" button still exists
	var start_btn: Button = _find_button_by_text(screen, "Start shift")
	if start_btn == null:
		return _fail("'Start shift' button not found on title screen")

	# 3. Assert that the footer text contains "Geaux Hack"
	var footer: Label = _find_label_containing(screen, "Geaux Hack")
	if footer == null:
		return _fail("Footer label containing 'Geaux Hack' not found on title screen")

	screen.queue_free()
	await process_frame
	_pass()
