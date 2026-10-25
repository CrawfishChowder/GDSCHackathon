extends SceneTree

var _entry_added_fired: bool = false
var _added_entry: Dictionary = {}


func _fail(reason: String) -> void:
	print("FAIL: " + reason)
	quit(1)


func _initialize() -> void:
	await process_frame
	var ml: Node = root.get_node_or_null("MissionLog")
	if ml == null:
		var script_res := load("res://scripts/systems/mission_log.gd")
		if script_res == null:
			return _fail("Failed to load mission_log.gd")
		ml = script_res.new()
		root.add_child(ml)
		await process_frame

	ml.connect("entry_added", func(entry: Dictionary) -> void:
		_entry_added_fired = true
		_added_entry = entry
	)

	var initial_count: int = (ml.get("entries") as Array).size()

	var entry: Dictionary = ml.call("record_death", "power", "mistake", "x")

	if entry.get("title") != "Apollo 1 fire":
		return _fail("Expected title 'Apollo 1 fire', got '%s'" % entry.get("title"))

	var last_entry: Dictionary = ml.get("last_entry")
	if last_entry != entry:
		return _fail("last_entry did not match returned entry")

	if not _entry_added_fired:
		return _fail("entry_added signal did not fire")

	if _added_entry != entry:
		return _fail("entry_added payload did not match returned entry")

	var new_count: int = (ml.get("entries") as Array).size()
	# The log is capped at 50 entries, so a full log stays at 50.
	if new_count != mini(initial_count + 1, 50):
		return _fail("Expected entries to grow by 1 (was %d, now %d)" % [initial_count, new_count])

	print("PASS")
	quit(0)
