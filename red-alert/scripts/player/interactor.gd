extends RayCast3D

signal target_changed(prompt: String)

var _current_target: Interactable = null
var _last_prompt: String = ""


func _ready() -> void:
	target_position = Vector3(0, 0, -2.2)
	collide_with_areas = true
	collide_with_bodies = true
	collision_mask = 3
	if owner is CollisionObject3D:
		add_exception(owner)


func _physics_process(_delta: float) -> void:
	var collider := get_collider()
	var new_target: Interactable = null
	if collider is Interactable and (collider as Interactable).enabled:
		new_target = collider as Interactable

	var new_prompt := new_target.prompt_text if new_target != null else ""
	if new_target != _current_target or new_prompt != _last_prompt:
		_current_target = new_target
		_last_prompt = new_prompt
		target_changed.emit(new_prompt)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _current_target != null:
		_current_target.interact(owner)
		get_viewport().set_input_as_handled()

