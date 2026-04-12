class_name ActionTarget
extends Marker2D


@export var action: Character.Action = Character.Action.WAIT


func _ready() -> void:
	var action_targets := Globals.level_state.action_targets
	if action not in action_targets:
		action_targets[action] = []
	action_targets[action].append(self)
