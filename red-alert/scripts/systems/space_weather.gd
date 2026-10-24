extends Node

# CONTRACT STUB (Claude). T4b implements the bodies; do not change signatures.
# Latest real solar flare from NASA DONKI (external API #1), with offline fallback.

# flare: {"class_type": "M1.2", "peak_time": "2026-10-20T13:45Z", "source": "live" | "offline"}
signal flare_loaded(flare: Dictionary)

var latest_flare: Dictionary = {}


# Parses a DONKI FLR JSON array body; returns the most recent flare dict or {}.
func parse_response(body: String) -> Dictionary:
	return {}


# X-class 0.8, M-class 0.9, otherwise 1.0. Scales malfunction time limits.
func difficulty_multiplier() -> float:
	return 1.0
