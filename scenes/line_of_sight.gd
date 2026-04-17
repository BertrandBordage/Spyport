class_name LineOfSightLayer
extends Node2D


const line_color := Color("6124467f")
@onready var bot_component: BotComponent = get_parent()
@onready var character := bot_component.character


func _draw() -> void:
	if bot_component.seen_dead != null:
		draw_line(
			to_local(bot_component.character.head_marker.global_position),
			to_local(bot_component.seen_dead.dead_component.dead_alert_collision_shape.global_position),
			line_color,
			-1,
			true,
		)


func _process(_delta: float) -> void:
	if character.action in [Character.Action.PANIC, Character.Action.FLEE]:
		queue_redraw()
