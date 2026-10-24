extends Node

# CONTRACT STUB (Claude). T3d implements the bodies; do not change signatures.
# Plays a voice line (res://assets/voice/<line_id>.mp3 when it exists) and
# always shows its caption on screen.


# Queue a line from data/voice_lines.json. Unknown ids are ignored.
func say(line_id: String) -> void:
	pass


func is_speaking() -> bool:
	return false
