extends RayCast3D

signal target_changed(prompt: String)

const DEFAULT_PROMPT := "Interact"

var _current_target: Node = null
var _last_prompt: String = ""
var _joy_interaction_held: bool = false


func _ready() -> void:
	target_position = Vector3(0, 0, -3)
	collide_with_areas = true
	collide_with_bodies = true
	collision_mask = 3
	if owner is CollisionObject3D:
		add_exception(owner)


func _physics_process(_delta: float) -> void:
	if _joy_interaction_held and not Input.is_action_pressed("interact"):
		_joy_interaction_held = false
	var new_target := _find_interactable(get_collider() as Node)
	var new_prompt := _prompt_for(new_target)
	if new_target != _current_target or new_prompt != _last_prompt:
		_current_target = new_target
		_last_prompt = new_prompt
		target_changed.emit(new_prompt)


func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventJoypadButton or event is InputEventJoypadMotion) and event.is_action_released("interact"):
		if not Input.is_action_pressed("interact"):
			_joy_interaction_held = false
		return
	if event.is_action_pressed("interact") and _current_target != null:
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			if _joy_interaction_held:
				get_viewport().set_input_as_handled()
				return
			_joy_interaction_held = true
		_current_target.interact(owner)
		get_viewport().set_input_as_handled()


# Any node with an interact() method counts, so the hit collider can be a child
# body (e.g. a breaker box's StaticBody3D) of the node that actually reacts.
# Nodes may expose optional `prompt_text` and `enabled` properties.
func _find_interactable(node: Node) -> Node:
	while node != null:
		if node.has_method("interact"):
			return node if node.get("enabled") != false else null
		node = node.get_parent()
	return null


func _prompt_for(target: Node) -> String:
	if target == null:
		return ""
	var prompt: Variant = target.get("prompt_text")
	# Teammates' scripts expose get_interaction_prompt() instead of prompt_text.
	if prompt == null and target.has_method("get_interaction_prompt"):
		prompt = String(target.call("get_interaction_prompt"))
	return prompt if prompt is String and not prompt.is_empty() else DEFAULT_PROMPT
