# Monitor display override API

`NormalOperations` is always present in `stage_1_room.tscn` and belongs to the
`monitor_display_service` group. It keeps all six default displays running and
places an opaque override layer above a default only while that monitor is
claimed.

## Stable monitor IDs

| ID | Physical monitor |
| --- | --- |
| `console_left` | Left command-console monitor |
| `console_center` | Center command-console monitor |
| `console_right` | Right command-console monitor |
| `door_north` | North bulkhead access monitor |
| `door_east` | East bulkhead access monitor |
| `door_west` | West bulkhead access monitor |

## Claim and release

The supplied display must be a `PackedScene` whose root is a `Control` or
`Node2D`. A root `Control` is resized to the selected monitor's render
resolution automatically. Draw an opaque background when the display needs a
color other than the service's black override backdrop.

```gdscript
extends Node

const ALERT_DISPLAY := preload("res://path/to/team_alert_display.tscn")

var monitor_displays: Node


func _ready() -> void:
	monitor_displays = get_tree().get_first_node_in_group(
		&"monitor_display_service"
	)
	if not monitor_displays.claim_monitor(
		&"console_center", self, ALERT_DISPLAY
	):
		push_warning("Center monitor is already owned by another scene.")


func _exit_tree() -> void:
	# Optional: owner removal releases claims automatically. Explicit release is
	# useful when this scene remains alive after its monitor content should end.
	if is_instance_valid(monitor_displays):
		monitor_displays.release_monitor(&"console_center", self)
```

Call `claim_monitor()` once per desired monitor. Claims are independent, and a
claim made by another owner is rejected rather than replaced. Use
`release_monitor(id, self)` for one display or `release_all(self)` for every
display held by the caller. Removing the owner scene automatically removes all
of its overrides and reveals the still-running defaults.

`get_monitor_ids()`, `get_monitor_resolution(id)`, and
`is_monitor_claimed(id)` are available for inspection.
