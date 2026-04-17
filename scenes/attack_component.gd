class_name AttackComponent
extends Node2D


var character: Character
@onready var attack_collision_shape: CollisionShape2D = %AttackCollisionShape
@onready var attack_area: Area2D = %AttackArea
@onready var dash_player: AudioStreamPlayer2D = %DashPlayer
@onready var attack_player: AudioStreamPlayer2D = %AttackPlayer

func start_attack() -> void:
	character.action = character.Action.ATTACK
	character.sprite.play("attack")
	attack_collision_shape.disabled = false
	var attack_direction := (
		Vector2(signf(character.visuals.scale.x), 0.0) if character.velocity.length() < 0.2
		else character.velocity.normalized()
	)
	attack_area.rotation = attack_direction.angle()
	dash_player.play()
	var tween := create_tween()
	tween.tween_property(
		character, "velocity",
		-character.type.ATTACK_CHARGE_SPEED * attack_direction,
		0.2,
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(on_attack_action)


func on_attack_action() -> void:
	if character.is_dead:
		return

	for body in attack_area.get_overlapping_bodies():
		if body is Character and body != character:
			body.die(character)
			attack_player.play()
	attack_collision_shape.disabled = true
	var tween := create_tween()
	tween.tween_property(
		character, "velocity",
		-character.type.ATTACK_SPEED * character.velocity.normalized(),
		0.1,
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(on_attack_end)


func on_attack_end() -> void:
	character.action = Character.Action.WAIT
