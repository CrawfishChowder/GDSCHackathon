extends Node3D

@onready var sit_point: Marker3D = $SitPoint
@onready var stand_point: Marker3D = $StandPoint

var occupant: Node3D
var prompt_text: String:
	get:
		return "Stand up" if is_instance_valid(occupant) else "Sit down"


func interact(interactor: Node = null) -> void:
	if interactor == null or not interactor.has_method("sit_in"):
		return
	if is_instance_valid(occupant) and occupant != interactor:
		return
	# Pressing E on your own chair stands you up (the Interactor keeps targeting it).
	if occupant == interactor and interactor.has_method("stand_up"):
		interactor.stand_up()
		return

	if interactor.sit_in(self):
		occupant = interactor


func get_sit_transform() -> Transform3D:
	return sit_point.global_transform


func get_stand_transform() -> Transform3D:
	return stand_point.global_transform


func release(interactor: Node) -> void:
	if occupant == interactor:
		occupant = null
