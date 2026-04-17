class_name AttackComponent
extends Node2D

var character: Character
var cooldown := 0.0  # No cooldown by default
var last_attack := 0.0
@onready var attack_collision_shape: CollisionShape2D = %AttackCollisionShape
@onready var attack_area: Area2D = %AttackArea
@onready var dash_player: AudioStreamPlayer2D = %DashPlayer
@onready var attack_player: AudioStreamPlayer2D = %AttackPlayer

func start_attack() -> void:
	if character.action == Character.Action.ATTACK or (
		Time.get_ticks_msec() / 1_000.0 < last_attack + cooldown
	):
		return
	last_attack = Time.get_ticks_msec() / 1_000.0
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

	var made_kills := false
	for body in attack_area.get_overlapping_bodies():
		if body is Character and body != character:
			body.die(character)
			made_kills = true
	if made_kills:
		attack_player.play()
		character.vibrate(0.5, 1.0, 0.1)
	else:
		character.vibrate(0.5, 0.0, 0.1)
	attack_collision_shape.disabled = true
	var tween := create_tween()
	tween.tween_property(
		character, "velocity",
		-character.type.ATTACK_SPEED * character.velocity.normalized(),
		0.1,
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(on_attack_end)


func on_attack_end() -> void:
	character.action = Character.Action.WALK
