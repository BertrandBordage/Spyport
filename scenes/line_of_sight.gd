class_name LineOfSightLayer
extends Node2D


const line_color := Color("6124467f")
@onready var character: Character = get_parent().character


func _draw() -> void:
	if character.seen_dead != null:
		draw_line(
			to_local(character.head_marker.global_position),
			to_local(character.seen_dead.dead_component.dead_alert_collision_shape.global_position),
			line_color,
			-1,
			true,
		)


func _process(_delta: float) -> void:
	if character.action in [Character.Action.PANIC, Character.Action.FLEE]:
		queue_redraw()
