extends Sprite2D

var seen_body_position


# We do this on the shadow because it has the correct Z index
# to be below all character sprites.
func _draw() -> void:
	if seen_body_position != null:
		draw_line(
			to_local(global_position),
			to_local(seen_body_position),
			Color("#612447"),
			-1,
			true,
		)
