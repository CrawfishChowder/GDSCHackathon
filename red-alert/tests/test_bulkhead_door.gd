extends SceneTree

var _opened_fired: bool = false


func _initialize() -> void:
	var door_scene := load("res://scenes/stage1/components/sealed_bulkhead_door.tscn") as PackedScene
	if door_scene == null:
		print("FAIL: Failed to load door scene")
		quit(1)
		return

	var door := door_scene.instantiate() as BulkheadDoor
	if door == null:
		print("FAIL: Failed to instantiate door scene")
		quit(1)
		return

	root.add_child(door)

	if not door.is_sealed():
		print("FAIL: Door should be sealed initially")
		quit(1)
		return

	door.opened.connect(func() -> void: _opened_fired = true)
	door.unseal()

	await create_timer(1.6).timeout

	if door.is_sealed():
		print("FAIL: Door is still sealed after unseal")
		quit(1)
		return

	var door_collision := door.get_node_or_null("DoorCollision") as CollisionShape3D
	if door_collision == null or not door_collision.disabled:
		print("FAIL: DoorCollision was not disabled")
		quit(1)
		return

	if not _opened_fired:
		print("FAIL: opened signal did not fire")
		quit(1)
		return

	print("PASS")
	quit(0)

