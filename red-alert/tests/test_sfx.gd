extends SceneTree


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame

	var sfx: Node = root.get_node_or_null("Sfx")
	if sfx == null:
		var script := load("res://scripts/systems/sfx.gd") as GDScript
		if script == null:
			return _fail("Failed to load sfx.gd")
		sfx = script.new()
		root.add_child(sfx)
		await process_frame

	# 1. Assert buses exist
	for bus_name in ["SFX", "Voice", "Radio"]:
		var idx := AudioServer.get_bus_index(bus_name)
		if idx == -1:
			return _fail("Audio bus '%s' not found" % bus_name)

	# 2. Assert every id in IDS gives a non-null get_stream
	var ids: Variant = sfx.get("IDS")
	if not (ids is Array) or (ids as Array).is_empty():
		return _fail("Sfx.IDS is empty or missing")
	for id in (ids as Array):
		var id_str := String(id)
		var stream: Variant = sfx.call("get_stream", id_str)
		if stream == null:
			return _fail("get_stream('%s') returned null" % id_str)
		if not (stream is AudioStream):
			return _fail("get_stream('%s') is not an AudioStream" % id_str)

	# 3. play("click") returns a node
	var player_node: Variant = sfx.call("play", "click")
	if player_node == null:
		return _fail("play('click') returned null")
	if not (player_node is Node):
		return _fail("play('click') did not return a Node")

	# 4. play 3D sound returns an AudioStreamPlayer3D
	var player_3d: Variant = sfx.call("play", "click", Vector3(1.0, 2.0, 3.0))
	if player_3d == null or not (player_3d is AudioStreamPlayer3D):
		return _fail("play('click', Vector3) did not return AudioStreamPlayer3D")

	# 5. play unknown id returns null
	var unknown_res: Variant = sfx.call("play", "unknown_audio_id_test")
	if unknown_res != null:
		return _fail("play('unknown_audio_id_test') did not return null")

	print("PASS")
	quit(0)
