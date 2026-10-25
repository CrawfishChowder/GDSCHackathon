class_name FixStation
extends Interactable

@export var malfunction_id: String = ""
@export var minigame_scene: PackedScene


func _ready() -> void:
	super()
	enabled = false
	prompt_text = "Fix: " + MalfunctionManager.display_name(malfunction_id)
	MalfunctionManager.malfunction_started.connect(_on_malfunction_started)
	MalfunctionManager.malfunction_fixed.connect(_on_malfunction_fixed)
	MalfunctionManager.player_died.connect(_on_player_died)


func interact(by: Node) -> void:
	if not enabled or minigame_scene == null:
		return

	interacted.emit(by)
	MinigameHost.open(minigame_scene, malfunction_id)


func _on_malfunction_started(id: String, _display_name: String, _time_limit: float) -> void:
	enabled = (id == malfunction_id)


func _on_malfunction_fixed(_id: String) -> void:
	enabled = false


func _on_player_died(_cause_id: String, _display_name: String) -> void:
	enabled = false
