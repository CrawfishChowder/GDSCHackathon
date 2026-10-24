extends Node

# CONTRACT STUB (Claude). T4c implements the bodies; do not change signatures.
# Live "people in space right now" from Open Notify (external API #2).

signal loaded(count: int, names: Array)

var count: int = -1
var names: Array[String] = []
var source: String = "pending"  # "pending" | "live" | "offline"


# Parses an Open Notify astros.json body; returns true on success and fills count/names.
func parse_response(body: String) -> bool:
	return false


# e.g. "Right now, 10 people are in space: A, B, C..." or an offline message.
func summary_line() -> String:
	return ""
