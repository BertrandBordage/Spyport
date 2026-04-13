class_name PlayerComponent
extends Node2D

enum Direction { UP, DOWN, LEFT, RIGHT }

const ACTIONS_MAPPING: Dictionary[Character.PlayerIndex, Dictionary] = {
	Character.PlayerIndex.ONE: {
		Direction.UP: "player_0_up",
		Direction.DOWN: "player_0_down",
		Direction.LEFT: "player_0_left",
		Direction.RIGHT: "player_0_right",
		Character.Action.ATTACK: "player_0_attack",
	},
	Character.PlayerIndex.TWO: {
		Direction.UP: "player_1_up",
		Direction.DOWN: "player_1_down",
		Direction.LEFT: "player_1_left",
		Direction.RIGHT: "player_1_right",
		Character.Action.ATTACK: "player_1_attack",
	},
	Character.PlayerIndex.THREE: {
		Direction.UP: "player_2_up",
		Direction.DOWN: "player_2_down",
		Direction.LEFT: "player_2_left",
		Direction.RIGHT: "player_2_right",
		Character.Action.ATTACK: "player_2_attack",
	},
	Character.PlayerIndex.FOUR: {
		Direction.UP: "player_3_up",
		Direction.DOWN: "player_3_down",
		Direction.LEFT: "player_3_left",
		Direction.RIGHT: "player_3_right",
		Character.Action.ATTACK: "player_3_attack",
	},
}


var character: Character
@onready var attack_area: Area2D = %AttackArea
@onready var attack_collision_shape: CollisionShape2D = %AttackCollisionShape
@onready var attack_player: AudioStreamPlayer2D = %AttackPlayer
@onready var dash_player: AudioStreamPlayer2D = %DashPlayer
@onready var steps_player: AudioStreamPlayer2D = %StepsPlayer
@onready var steps_timer: Timer = %StepsTimer
@onready var player_mapping := ACTIONS_MAPPING[character.player_index]


func _unhandled_input(event: InputEvent) -> void:
	if character.is_dead:
		return

	if character.action != Character.Action.ATTACK and event.is_action_pressed(
		player_mapping[Character.Action.ATTACK]
	):
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


func _physics_process(_delta: float) -> void:
	if character.action == Character.Action.ATTACK:
		character.move_slide_and_collide()
		return

	character.velocity = character.character_type.SPEED * Input.get_vector(
		player_mapping[Direction.LEFT],
		player_mapping[Direction.RIGHT],
		player_mapping[Direction.UP],
		player_mapping[Direction.DOWN],
	)
	if character.velocity.length() > 0 and steps_timer.is_stopped():
		_on_steps_timer_timeout()
	character.apply_generic_velocity()


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
