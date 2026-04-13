class_name DeadComponent
extends Node2D


var character: Character
@onready var blood: Sprite2D = %Blood
@onready var dead_alert_collision_shape: CollisionShape2D = %DeadAlertCollisionShape
var others_in_range: Array[Character] = []


func _ready() -> void:
	blood.rotation = randf_range(-PI/6, PI/6)
	var tween := create_tween()
	tween.tween_property(
		blood, 'scale', Vector2(1.5, 1.5), 5.0,
	).set_ease(Tween.EASE_OUT)


func _physics_process(_delta: float) -> void:
	for other_character in others_in_range:
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
			other_character.seen_dead = character
			other_character.action = Character.Action.PANIC
			others_in_range.erase(other_character)


func _on_dead_alert_area_body_entered(body: Node2D) -> void:
	if body is Character and body.is_bot and not body.has_panicked:
		others_in_range.append(body as Character)


func _on_dead_alert_area_body_exited(body: Node2D) -> void:
	if body in others_in_range:
		others_in_range.erase(body)
