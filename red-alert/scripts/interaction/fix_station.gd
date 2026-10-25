# FixStation: Interactive terminal Area3D linked to a specific malfunction minigame.
# Enables only when its malfunction is active and opens the minigame on interaction.
# Listens to MalfunctionManager (malfunction_started, malfunction_fixed, player_died).
class_name FixStation
extends Interactable

@export var malfunction_id: String = ""
@export var minigame_scene: PackedScene

var _last_path: String = ""


func _ready() -> void:
	super()
	enabled = false
	var mm: Node = get_node_or_null("/root/MalfunctionManager") if is_inside_tree() else null
	if mm != null and mm.has_method("display_name"):
		prompt_text = "Fix: " + String(mm.call("display_name", malfunction_id))
	else:
		prompt_text = "Fix: " + malfunction_id

	if mm != null:
		if mm.has_signal("malfunction_started") and not mm.malfunction_started.is_connected(_on_malfunction_started):
			mm.malfunction_started.connect(_on_malfunction_started)
		if mm.has_signal("malfunction_fixed") and not mm.malfunction_fixed.is_connected(_on_malfunction_fixed):
			mm.malfunction_fixed.connect(_on_malfunction_fixed)
		if mm.has_signal("player_died") and not mm.player_died.is_connected(_on_player_died):
			mm.player_died.connect(_on_player_died)


func interact(by: Node) -> void:
	if not enabled:
		return

	var scene_to_open: PackedScene = null
	if _last_path != "":
		scene_to_open = load(_last_path) as PackedScene
	if scene_to_open == null:
		scene_to_open = minigame_scene
	if scene_to_open == null:
		return

	interacted.emit(by)
	var mh: Node = get_node_or_null("/root/MinigameHost") if is_inside_tree() else null
	if mh != null and mh.has_method("open"):
		mh.call("open", scene_to_open, malfunction_id)


## Picks this crisis's minigame once, so cancelling and reopening keeps it.
## The first crisis of a run uses the original minigame, which the tutorial and briefs describe.
func choose_variant() -> void:
	if _last_path == "":
		var variants: Array = MinigameCatalog.VARIANTS.get(malfunction_id, [])
		if not variants.is_empty() and ResourceLoader.exists(String(variants[0])):
			_last_path = String(variants[0])
		return
	var picked_path: String = MinigameCatalog.pick(malfunction_id, _last_path)
	if picked_path != "":
		_last_path = picked_path


func _on_malfunction_started(id: String, _display_name: String, _time_limit: float) -> void:
	enabled = (id == malfunction_id)
	if enabled:
		choose_variant()


func _on_malfunction_fixed(_id: String) -> void:
	enabled = false


func _on_player_died(_cause_id: String, _display_name: String) -> void:
	enabled = false
