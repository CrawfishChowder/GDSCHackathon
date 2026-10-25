extends Area3D


func interact(_interactor: Node = null) -> void:
	get_parent().call("toggle_main_breaker")


func get_interaction_prompt() -> String:
	return str(get_parent().call("get_main_breaker_prompt"))