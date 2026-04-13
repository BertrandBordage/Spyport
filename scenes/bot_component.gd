class_name BotComponent
extends Node2D

var character: Character
@onready var danger: Sprite2D = %Danger
@onready var wait_timer: Timer = %WaitTimer
@onready var panic_player: AudioStreamPlayer2D = %PanicPlayer
var action_target: ActionTarget
var has_panicked: bool = false
var path_update_frame := randi_range(0, 59)


var bot_actions_probabilities = [
	Character.Action.WAIT,
	Character.Action.WAIT,
	Character.Action.WAIT,
	Character.Action.WAIT,
	Character.Action.WAIT,
	Character.Action.WAIT,
	Character.Action.WALK,
	Character.Action.WALK,
	Character.Action.TURN,
	Character.Action.TURN,
	Character.Action.TURN,
	Character.Action.EMBARK,
]


func _ready() -> void:
	character.action_changed.connect(_on_action_changed)
	character.agent.velocity_computed.connect(_on_agent_velocity_computed)
	_on_wait_timer_timeout()


func _physics_process(_delta: float) -> void:
	var action := character.action
	var agent := character.agent
	agent.velocity = Vector2.ZERO
	if action in [Character.Action.WAIT, Character.Action.PANIC]:
		return

	if Engine.get_physics_frames() % 60 == path_update_frame:
		# Updates the pathfinding.
		agent.target_position = agent.target_position

	if agent.is_navigation_finished():
		character.action = Character.Action.WAIT
	elif action in [Character.Action.WALK, Character.Action.EMBARK, Character.Action.FLEE]:
		agent.velocity = character.character_type.SPEED * character.global_position.direction_to(
			agent.get_next_path_position()
		) * clampf(
			agent.distance_to_target() / agent.target_desired_distance,
			0.0,
			1.0,
		)


func _on_agent_velocity_computed(safe_velocity: Vector2) -> void:
	if character.action == Character.Action.PANIC:
		character.velocity = Vector2.ZERO
		character.apply_generic_velocity()
		return

	character.velocity = lerp(
		character.velocity,
		safe_velocity,
		0.1 if character.action == Character.Action.WAIT else 0.5,
	).limit_length(
		character.character_type.SPEED * (0.2 if character.action == Character.Action.WAIT else 1.0)
	)
	character.apply_generic_velocity()


func _on_wait_timer_timeout() -> void:
	character.action = bot_actions_probabilities.pick_random()

func _on_action_changed(action: Character.Action) -> void:
	action_target = null
	if action == Character.Action.WAIT:
		wait()
		return
	wait_timer.stop()
	if action == Character.Action.WALK:
		character.agent.target_position = Globals.get_random_position(
			character.get_collision_shape()
		)
	elif action == Character.Action.TURN:
		turn()
	elif action == Character.Action.EMBARK:
		embark()
	elif action == Character.Action.PANIC:
		panic()
	elif action == Character.Action.FLEE:
		flee()

func turn() -> void:
	character.visuals.scale.x = -character.visuals.scale.x
	character.action = Character.Action.WAIT

func _compare_target_distance(target_a: ActionTarget, target_b: ActionTarget) -> float:
	return global_position.distance_squared_to(target_b.global_position) > global_position.distance_squared_to(target_a.global_position)

func set_action_target() -> void:
	var candidates := Globals.level_state.action_targets[character.action].duplicate()
	candidates.sort_custom(_compare_target_distance)
	action_target = candidates[0]
	character.agent.target_position = action_target.global_position

func embark() -> void:
	set_action_target()
	character.update_collision()

func panic() -> void:
	has_panicked = true
	character.update_collision()
	danger.visible = true
	panic_player.play()
	var tween := create_tween()
	tween.tween_property(danger, "scale:y", 1.0, 0.2)
	await get_tree().create_timer(3.0).timeout
	character.action = Character.Action.FLEE

func flee() -> void:
	character.seen_dead = null
	danger.visible = false
	danger.scale.y = 0.0
	set_action_target()
	character.update_collision()

func wait() -> void:
	wait_timer.wait_time = randf_range(3.0, 10.0)
	if not is_inside_tree():
		await ready
	wait_timer.start()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	character.queue_free()
