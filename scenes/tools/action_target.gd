class_name ActionTarget
extends Marker2D


@export var action: Character.Action = Character.Action.WAIT


func _ready() -> void:
	if action not in Globals.action_targets:
		Globals.action_targets[action] = []
	Globals.action_targets[action].append(self)
