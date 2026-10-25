# Interactor: RayCast3D attached to player camera detecting interactable objects.
# Updates HUD prompt when looking at interactables and triggers interact() on keypress.
# Signals: target_changed(prompt: String).
extends RayCast3D

signal target_changed(prompt: String)

const DEFAULT_PROMPT := "Interact"

var _current_target: Node = null
var _last_prompt: String = ""


func _ready() -> void:
	target_position = Vector3(0, 0, -3)
	collide_with_areas = true
	collide_with_bodies = true
	collision_mask = 3
	if owner is CollisionObject3D:
		add_exception(owner)


func _physics_process(_delta: float) -> void:
	var new_target: Node = _find_interactable(get_collider() as Node)
	var new_prompt: String = _prompt_for(new_target)
	if new_target != _current_target or new_prompt != _last_prompt:
		_current_target = new_target
		_last_prompt = new_prompt
		target_changed.emit(new_prompt)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _current_target != null:
		if is_instance_valid(_current_target) and _current_target.has_method("interact"):
			_current_target.interact(owner)
			var vp := get_viewport()
			if vp != null:
				vp.set_input_as_handled()


# Walks up collider hierarchy to find an enabled node providing interact(by).
func _find_interactable(node: Node) -> Node:
	while node != null:
		if node.has_method("interact"):
			var enabled_val: Variant = node.get("enabled")
			if enabled_val == null or bool(enabled_val):
				return node
			return null
		node = node.get_parent()
	return null


func _prompt_for(target: Node) -> String:
	if target == null:
		return ""
	var prompt: Variant = target.get("prompt_text")
	if prompt == null and target.has_method("get_interaction_prompt"):
		prompt = target.call("get_interaction_prompt")
	if prompt is String and not String(prompt).is_empty():
		return String(prompt)
	return DEFAULT_PROMPT
