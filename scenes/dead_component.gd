class_name DeadComponent
extends Node2D


var character: Character
var killed_by: Character
@onready var blood: Sprite2D = %Blood
@onready var dead_alert_collision_shape: CollisionShape2D = %DeadAlertCollisionShape
var others_in_range: Array[Character] = []
var killed_at: float


func _ready() -> void:
	blood.rotation = randf_range(-PI/6, PI/6)
	var tween := create_tween()
	tween.tween_property(
		blood, 'scale', Vector2(1.5, 1.5), 5.0,
	).set_ease(Tween.EASE_OUT)
	killed_at = Time.get_ticks_msec() / 1_000.0


func _physics_process(_delta: float) -> void:
	# We duplicate because we modify the array as we iterate on it.
	for other_character in others_in_range.duplicate():
		var dead_position: Vector2 = character.global_position
		var character_position: Vector2 = other_character.global_position
		if sign((dead_position - character_position).x) != sign(other_character.visuals.scale.x):
			continue  # The other character is turned away, ignore.
		# Check if the body is not hidden by anything.
		var query := PhysicsRayQueryParameters2D.create(
			character_position, dead_position, 0b1000
		)
		var result := Globals.physics_state.intersect_ray(query)
		if "collider" not in result:
			# We check again, because the character could no longer be a bot.
			if other_character.is_bot:
				other_character.bot_component.see_dead(character)
			others_in_range.erase(other_character)


func _on_dead_alert_area_body_entered(body: Node2D) -> void:
	if body is Character and body.is_bot and not body.bot_component.has_panicked:
		others_in_range.append(body as Character)


func _on_dead_alert_area_body_exited(body: Node2D) -> void:
	if body in others_in_range:
		others_in_range.erase(body)


func is_just_killed() -> bool:
	return Time.get_ticks_msec() / 1_000.0 - killed_at < 0.3
