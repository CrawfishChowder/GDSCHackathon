extends StaticBody3D

## Optional visual placed just in front of the otherwise dark access-monitor screen.
## Event scenes can assign this in the inspector or call set_screen_overlay() at runtime.
@export var initial_screen_overlay: PackedScene

@onready var _screen_overlay_anchor: Node3D = $LeftAccessMonitor/ScreenOverlayAnchor

var _screen_overlay: Node


func _ready() -> void:
	if initial_screen_overlay:
		set_screen_overlay(initial_screen_overlay)


func set_screen_overlay(overlay_scene: PackedScene) -> Node:
	clear_screen_overlay()
	if overlay_scene == null:
		return null

	_screen_overlay = overlay_scene.instantiate()
	_screen_overlay_anchor.add_child(_screen_overlay)
	return _screen_overlay


func clear_screen_overlay() -> void:
	if not is_instance_valid(_screen_overlay):
		_screen_overlay = null
		return

	_screen_overlay_anchor.remove_child(_screen_overlay)
	_screen_overlay.queue_free()
	_screen_overlay = null
