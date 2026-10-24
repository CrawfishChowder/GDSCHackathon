extends CanvasLayer

@onready var prompt_label: Label = $PromptLabel


func set_prompt(text: String) -> void:
	if text.is_empty():
		prompt_label.visible = false
		prompt_label.text = ""
	else:
		prompt_label.text = "[E] " + text
		prompt_label.visible = true

