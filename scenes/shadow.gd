class_name Shadow
extends Sprite2D


const line_color := Color("#612447")
var character: Character


# We do this on the shadow because it has the correct Z index
# to be below all character sprites.
func _draw() -> void:
	if character.seen_dead != null:
		draw_line(
			to_local(character.head_marker.global_position),
			to_local(
				character.seen_dead.dead_component.dead_alert_collision_shape.global_position
			),
			line_color,
			-1,
			true,
		)
