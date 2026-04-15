class_name PlayerComponent
extends Node2D

enum Direction { UP, DOWN, LEFT, RIGHT }

const GAMEPAD_ACTIONS := {
	Direction.UP: "gamepad_up",
	Direction.DOWN: "gamepad_down",
	Direction.LEFT: "gamepad_left",
	Direction.RIGHT: "gamepad_right",
	Character.Action.ATTACK: "gamepad_attack",
}

var character: Character
@onready var attack_area: Area2D = %AttackArea
@onready var attack_collision_shape: CollisionShape2D = %AttackCollisionShape
@onready var attack_player: AudioStreamPlayer2D = %AttackPlayer
@onready var dash_player: AudioStreamPlayer2D = %DashPlayer
@onready var steps_player: AudioStreamPlayer2D = %StepsPlayer
@onready var steps_timer: Timer = %StepsTimer
@onready var player_mapping := build_mapping()


func build_gamepad_mapping() -> Dictionary:
	var mapping := {}
	for action_or_direction in GAMEPAD_ACTIONS:
		var action: String = GAMEPAD_ACTIONS[action_or_direction]
		var device_action := "%s_%d" % [action, character.join_event.device]
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				if not InputMap.has_action(device_action):
					InputMap.add_action(device_action)
				var device_event := event.duplicate()
				device_event.device = character.join_event.device
				InputMap.action_add_event(device_action, device_event)
		mapping[action_or_direction] = device_action
	return mapping

func build_mapping() -> Dictionary:
	if character.join_event is InputEventJoypadButton:
		return build_gamepad_mapping()
	if character.join_event.is_action_pressed("keyboard_attack_0"):
		return {
			Direction.UP: "keyboard_up_0",
			Direction.DOWN: "keyboard_down_0",
			Direction.LEFT: "keyboard_left_0",
			Direction.RIGHT: "keyboard_right_0",
			Character.Action.ATTACK: "keyboard_attack_0",
		}
	return {
		Direction.UP: "keyboard_up_1",
		Direction.DOWN: "keyboard_down_1",
		Direction.LEFT: "keyboard_left_1",
		Direction.RIGHT: "keyboard_right_1",
		Character.Action.ATTACK: "keyboard_attack_1",
	}

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
