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
@onready var steps_player: AudioStreamPlayer2D = %StepsPlayer
@onready var steps_timer: Timer = %StepsTimer
@onready var player_mapping := build_mapping()
@onready var attack_component: AttackComponent = $AttackComponent


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

func _ready() -> void:
	attack_component.character = character

func _unhandled_input(event: InputEvent) -> void:
	if character.is_dead:
		return

	if character.action != Character.Action.ATTACK and event.is_action_pressed(
		player_mapping[Character.Action.ATTACK]
	):
		attack_component.start_attack()


func _physics_process(_delta: float) -> void:
	if character.action == Character.Action.ATTACK:
		character.move_slide_and_collide()
		return

	character.velocity = character.type.SPEED * Input.get_vector(
		player_mapping[Direction.LEFT],
		player_mapping[Direction.RIGHT],
		player_mapping[Direction.UP],
		player_mapping[Direction.DOWN],
	)
	if character.velocity.length() > 0 and steps_timer.is_stopped():
		_on_steps_timer_timeout()
	character.apply_generic_velocity()


func _on_steps_timer_timeout() -> void:
	if character.is_dead or character.velocity.length() <= 1.0:
		return

	steps_player.play()
	steps_timer.start(0.3 / clampf(character.velocity.length() / character.type.SPEED, 0.3, 1.0))
