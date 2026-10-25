extends Node

# CONTRACT STUB (Claude). T9b1 implements the bodies; do not change signatures.
# Procedural sound library + audio buses ("SFX", "Voice", "Radio").
# Ids: click, beep, beep_error, success, fail, clunk, creak, hiss, step, static,
#      heartbeat, flatline, alarm_ping, hum, siren
# Recorded files live in res://assets/sfx/<id>.ogg (step has step_1..3 variants);
# ids without a file are generated procedurally.

const IDS := ["click", "beep", "beep_error", "success", "fail", "clunk", "creak",
	"hiss", "step", "static", "heartbeat", "flatline", "alarm_ping", "hum", "siren"]


# Plays a one-shot. `at` = Vector3 world position for 3D sound, or null for 2D.
# Returns the player node (or null for an unknown id).
func play(id: String, at: Variant = null, volume_db: float = 0.0, bus: String = "SFX") -> Node:
	return null


# The generated stream for an id (for callers that need their own looping player).
func get_stream(id: String) -> AudioStream:
	return null
