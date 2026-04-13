class_name PlayerComponent
extends Node2D


var character: Character
@onready var attack_area: Area2D = %AttackArea
@onready var attack_collision_shape: CollisionShape2D = %AttackCollisionShape
@onready var attack_player: AudioStreamPlayer2D = %AttackPlayer
@onready var dash_player: AudioStreamPlayer2D = %DashPlayer
@onready var steps_player: AudioStreamPlayer2D = %StepsPlayer
@onready var steps_timer: Timer = %StepsTimer


func _unhandled_input(event: InputEvent) -> void:
	if character.is_dead:
		return

	if character.action != Character.Action.ATTACK and event.is_action_pressed(character.player_mapping[Character.Action.ATTACK]):
		character.action = character.Action.ATTACK
		character.sprite.play("attack")
		attack_collision_shape.disabled = false
		var attack_direction := (
			Vector2(signf(character.visuals.scale.x), 0.0) if character.velocity.length() < 0.2
			else character.velocity.normalized()
		)
		%AttackArea.rotation = attack_direction.angle()
		%DashPlayer.play()
		var tween := create_tween()
		tween.tween_property(
			character, "velocity",
			-character.character_type.ATTACK_CHARGE_SPEED * attack_direction,
			0.2,
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_callback(on_attack_action)


func on_attack_action() -> void:
	if character.is_dead:
		return

	for body in attack_area.get_overlapping_bodies():
		if body is Character and body != character:
			body.is_dead = true
			Globals.character_died.emit(body, character)
			attack_player.play()
	attack_collision_shape.disabled = true
	var tween := create_tween()
	tween.tween_property(
		character, "velocity",
		-character.character_type.ATTACK_SPEED * character.velocity.normalized(),
		0.1,
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(on_attack_end)


func on_attack_end() -> void:
	character.action = Character.Action.WAIT


func _on_steps_timer_timeout() -> void:
	if character.is_dead or character.velocity.length() <= 1.0:
		return

	steps_player.play()
	steps_timer.start(0.3 / clampf(character.velocity.length() / character.character_type.SPEED, 0.3, 1.0))
