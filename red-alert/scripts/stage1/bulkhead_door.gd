# BulkheadDoor: Animated blast door sealing room corridors.
# Slides open vertically when unsealed; updates status lights and monitors.
# Signals: opened (emitted when unseal animation finishes).
class_name BulkheadDoor
extends StaticBody3D

signal opened

enum State {
	SEALED,
	OPENING,
	OPEN,
}

const GREEN_ALBEDO := Color(0.02, 0.3, 0.05)
const GREEN_EMISSION := Color(0.05, 0.9, 0.2)

@export var starts_sealed: bool = true
@export var open_duration: float = 1.2
@export var slide_height: float = 2.5

var _state: State = State.SEALED
var _indicator_mat: StandardMaterial3D = null

@onready var door_collision: CollisionShape3D = $DoorCollision
@onready var door_slab: MeshInstance3D = $DoorSlab
@onready var sealed_indicator: MeshInstance3D = $SealedIndicator
@onready var _screen_overlay_anchor: Node3D = $LeftAccessMonitor/ScreenOverlayAnchor

# Scott: optional visual placed just in front of the access-monitor screen.
@export var initial_screen_overlay: PackedScene
var _screen_overlay: Node


func _ready() -> void:
	if initial_screen_overlay != null:
		set_screen_overlay(initial_screen_overlay)
	var base_mat: Material = sealed_indicator.material_override
	if base_mat == null and sealed_indicator.mesh != null:
		base_mat = sealed_indicator.mesh.material
	if base_mat is StandardMaterial3D:
		_indicator_mat = base_mat.duplicate() as StandardMaterial3D
		sealed_indicator.material_override = _indicator_mat

	if not starts_sealed:
		_state = State.OPEN
		door_slab.position.y += slide_height
		door_collision.disabled = true
		_set_light_green()
	elif _state == State.OPENING:
		_set_light_green()
	else:
		_state = State.SEALED


# Triggers the unsealing sequence: plays hiss SFX, lights turn green, slab slides up.
func unseal() -> void:
	if _state != State.SEALED:
		return

	_state = State.OPENING
	var sfx: Node = get_node_or_null("/root/Sfx") if is_inside_tree() else null
	if sfx != null and sfx.has_method("play"):
		sfx.play("hiss", global_position)
	if not is_node_ready():
		await ready
		if not is_inside_tree():
			return

	_set_light_green()

	var target_y: float = door_slab.position.y + slide_height
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(door_slab, "position:y", target_y, open_duration)
	tween.finished.connect(_on_open_finished)


func is_sealed() -> bool:
	return _state == State.SEALED


func _set_light_green() -> void:
	if _indicator_mat != null:
		_indicator_mat.albedo_color = GREEN_ALBEDO
		_indicator_mat.emission = GREEN_EMISSION


func _on_open_finished() -> void:
	if not is_inside_tree():
		return
	door_collision.set_deferred("disabled", true)
	_state = State.OPEN
	opened.emit()


func set_screen_overlay(overlay_scene: PackedScene) -> Node:
	clear_screen_overlay()
	if overlay_scene == null:
		return null
	_screen_overlay = overlay_scene.instantiate()
	_screen_overlay_anchor.add_child(_screen_overlay)
	return _screen_overlay


func clear_screen_overlay() -> void:
	if is_instance_valid(_screen_overlay):
		_screen_overlay.queue_free()
	_screen_overlay = null
