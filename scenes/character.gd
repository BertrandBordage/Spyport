class_name Character
extends CharacterBody2D

enum Action { WAIT, WALK, TURN, EMBARK, ATTACK, PANIC, FLEE }
enum PlayerIndex { ONE = 0, TWO = 1, THREE = 2, FOUR = 3, BOT = -1 }

const player_component_scene: PackedScene = preload("res://scenes/player_component.tscn")
const dead_component_scene: PackedScene = preload("res://scenes/dead_component.tscn")

var bot_actions_probabilities = [
	Action.WAIT,
	Action.WAIT,
	Action.WAIT,
	Action.WAIT,
	Action.WAIT,
	Action.WAIT,
	Action.WALK,
	Action.WALK,
	Action.TURN,
	Action.TURN,
	Action.TURN,
	Action.EMBARK,
]

var player_index: PlayerIndex = PlayerIndex.ONE:
	set(value):
		player_index = value
		action = Action.WAIT
		update_collision()
		if not is_bot:
			player_component = player_component_scene.instantiate()
			player_component.character = self
			add_child(player_component)
var character_type: CharacterType = Globals.character_types.pick_random()
@onready var visuals: Node2D = %Visuals
@onready var shadow: Shadow = %Shadow
@onready var sprite: AnimatedSprite2D = %Sprite
@onready var head_marker: Marker2D = %HeadMarker
@onready var agent: NavigationAgent2D = %NavigationAgent2D
var player_component: PlayerComponent
var dead_component: DeadComponent

var action := Action.WAIT:
	set(value):
		action = value
		_on_action_changed()
var action_target: ActionTarget
var is_dead := false:
	set(value):
		is_dead = value
		shadow.visible = not is_dead
		sprite.z_index = (
			-1 if is_dead else 0 # Makes the body "part of the ground" when dead.
		)
		update_collision()
		if is_dead:
			sprite.play("dead")
			%WaitTimer.stop()
			%Danger.visible = false
			agent.avoidance_enabled = false
			sprite.rotation = randf_range(-PI/6, PI/6)
			dead_component = dead_component_scene.instantiate()
			dead_component.character = self
			visuals.add_child(dead_component)
var is_bot: bool:
	get:
		return player_index == PlayerIndex.BOT
var has_panicked: bool = false
var path_update_frame := randi_range(0, 59)
var seen_dead: Character

func _ready() -> void:
	agent.max_speed = character_type.SPEED
	sprite.sprite_frames = character_type.sprite_frames
	visuals.scale.x = -1.0 if randi_range(0, 1) == 0 else 1.0
	shadow.character = self
	_on_wait_timer_timeout()

func move_slide_and_collide() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is RigidBody2D:
			collider.apply_central_impulse(
				-collision.get_normal() * character_type.PUSH_STRENGTH
				# Proportional to the character velocity when touching.
				* abs(collision.get_travel().dot(collision.get_normal()))
			)

	move_and_slide()

func update_collision() -> void:
	set_collision_layer_value(1, not is_dead)
	set_collision_mask_value(2, action not in [Action.EMBARK, Action.FLEE])

## We do not use a property setter because they are not recursive,
## so actions could not trigger actions if this was a setter.
func _on_action_changed() -> void:
	action_target = null
	if action == Action.WAIT:
		wait()
		return
	%WaitTimer.stop()
	if action == Action.WALK:
		agent.target_position = Globals.get_random_position(%CollisionShape2D)
	elif action == Action.TURN:
		turn()
	elif action == Action.EMBARK:
		embark()
	elif action == Action.PANIC:
		panic()
	elif action == Action.FLEE:
		flee()

func turn() -> void:
	visuals.scale.x = -visuals.scale.x
	action = Action.WAIT

func _compare_target_distance(target_a: ActionTarget, target_b: ActionTarget) -> float:
	return global_position.distance_squared_to(target_b.global_position) > global_position.distance_squared_to(target_a.global_position)

func set_action_target() -> void:
	var candidates := Globals.level_state.action_targets[action].duplicate()
	candidates.sort_custom(_compare_target_distance)
	action_target = candidates[0]
	agent.target_position = action_target.global_position

func embark() -> void:
	set_action_target()
	update_collision()

func panic() -> void:
	has_panicked = true
	update_collision()
	%Danger.visible = true
	%PanicPlayer.play()
	var tween := create_tween()
	tween.tween_property(%Danger, "scale:y", 1.0, 0.2)
	await get_tree().create_timer(3.0).timeout
	action = Action.FLEE

func flee() -> void:
	seen_dead = null
	%Danger.visible = false
	%Danger.scale.y = 0.0
	set_action_target()
	update_collision()

func wait() -> void:
	%WaitTimer.wait_time = randf_range(3.0, 10.0)
	if not is_inside_tree():
		await ready
	%WaitTimer.start()

func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	if action == Action.ATTACK:
		move_slide_and_collide()
		return

	if is_bot:
		agent.velocity = Vector2.ZERO
		if action in [Action.WAIT, Action.PANIC]:
			return

		if Engine.get_physics_frames() % 60 == path_update_frame:
			# Updates the pathfinding.
			agent.target_position = agent.target_position

		if action in [Action.EMBARK, Action.FLEE]:
			if agent.is_navigation_finished():
				queue_free()
				return
		if agent.is_navigation_finished():
			action = Action.WAIT
		elif action in [Action.WALK, Action.EMBARK, Action.FLEE]:
			agent.velocity = character_type.SPEED * global_position.direction_to(
				agent.get_next_path_position()
			) * clampf(
				agent.distance_to_target() / agent.target_desired_distance,
				0.0,
				1.0,
			)

func _process(_delta: float) -> void:
	if action in [Action.PANIC, Action.FLEE]:
		shadow.queue_redraw()

func apply_generic_velocity() -> void:
	if velocity.length() > 0.0:
		sprite.play('walk' if velocity.length() > 1.0 else 'default')
		sprite.speed_scale = clampf(velocity.length() / character_type.SPEED, 0.25, 1.0)
		if abs(velocity.x) > 0.5:
			visuals.scale.x = 1.0 if velocity.x > 0.0 else -1.0
		move_slide_and_collide()
	else:
		sprite.play('default')
		sprite.speed_scale = 1.0

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	if is_dead or not is_bot:
		return

	if action == Action.PANIC:
		velocity = Vector2.ZERO
		apply_generic_velocity()
		return

	velocity = lerp(
		velocity,
		safe_velocity,
		0.1 if action == Action.WAIT else 0.5,
	).limit_length(
		character_type.SPEED * (0.2 if action == Action.WAIT else 1.0)
	)
	apply_generic_velocity()


func get_collision_shape() -> CollisionShape2D:
	return %CollisionShape2D

func _on_wait_timer_timeout() -> void:
	if not is_bot:
		return
	action = bot_actions_probabilities.pick_random()


func _exit_tree() -> void:
	Globals.character_count_changed.emit()
