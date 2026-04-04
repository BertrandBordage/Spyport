class_name Character
extends CharacterBody2D

enum Action { WAIT, WALK, TURN, EMBARK, ATTACK }
enum PlayerIndex { ONE = 0, TWO = 1, THREE = 2, FOUR = 3, BOT = -1 }
enum Direction { UP, DOWN, LEFT, RIGHT }

const ACTIONS_MAPPING: Dictionary[PlayerIndex, Dictionary] = {
	PlayerIndex.ONE: {
		Direction.UP: "player_0_up",
		Direction.DOWN: "player_0_down",
		Direction.LEFT: "player_0_left",
		Direction.RIGHT: "player_0_right",
		Action.ATTACK: "player_0_attack",
	},
	PlayerIndex.TWO: {
		Direction.UP: "player_1_up",
		Direction.DOWN: "player_1_down",
		Direction.LEFT: "player_1_left",
		Direction.RIGHT: "player_1_right",
		Action.ATTACK: "player_1_attack",
	},
	PlayerIndex.THREE: {
		Direction.UP: "player_2_up",
		Direction.DOWN: "player_2_down",
		Direction.LEFT: "player_2_left",
		Direction.RIGHT: "player_2_right",
		Action.ATTACK: "player_2_attack",
	},
	PlayerIndex.FOUR: {
		Direction.UP: "player_3_up",
		Direction.DOWN: "player_3_down",
		Direction.LEFT: "player_3_left",
		Direction.RIGHT: "player_3_right",
		Action.ATTACK: "player_3_attack",
	},
	PlayerIndex.BOT: {},
}

var bot_actions_probabilities = [
	Action.WAIT,
	Action.WAIT,
	Action.WAIT,
	Action.WAIT,
	Action.WAIT,
	Action.WAIT,
	Action.WALK,
	Action.TURN,
	Action.TURN,
	Action.TURN,
	#Action.EMBARK,
	#Action.EMBARK,
]

@export var player_index: PlayerIndex = PlayerIndex.ONE:
	set(value):
		player_index = value
		player_mapping = ACTIONS_MAPPING[player_index]
@onready var player_mapping := ACTIONS_MAPPING[player_index]
var character_type: CharacterType = Globals.character_types.pick_random()
@onready var agent: NavigationAgent2D = %NavigationAgent2D
var action := Action.WAIT
var is_dead := false:
	set(value):
		is_dead = value
		%Sprite.play("dead")
		%Shadow.visible = not is_dead
		%Sprite.z_index = (
			-1 if is_dead else 0 # Makes the body "part of the ground" when dead.
		)
		if is_dead:
			%WaitTimer.stop()
			%CollisionShape2D.disabled = true
			%Blood.visible = is_dead
			%Blood.scale = Vector2.ZERO
			var tween := create_tween()
			tween.tween_property(
				%Blood, 'scale', Vector2(1.5, 1.5), 5.0,
			).set_ease(Tween.EASE_OUT)
var is_bot: bool:
	get:
		return player_index == PlayerIndex.BOT

func _ready() -> void:
	agent.max_speed = character_type.SPEED
	%Sprite.sprite_frames = character_type.sprite_frames
	%Visuals.scale.x = -1.0 if randi_range(0, 1) == 0 else 1.0
	_on_wait_timer_timeout()

func move_slide_and_collide() -> void:
	move_and_slide()
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is RigidBody2D:
			collider.apply_central_impulse(
				collision.get_normal() * character_type.PUSH_STRENGTH
				# Proportional to the player velocity when touching.
				* collision.get_travel().dot(collision.get_normal())
			)

func wait() -> void:
	%WaitTimer.wait_time = randf_range(3.0, 10.0)
	%WaitTimer.start()

func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	if action == Action.ATTACK:
		move_slide_and_collide()
		return

	if is_bot:
		agent.velocity = Vector2.ZERO
		if action == Action.WAIT:
			return
		if agent.is_navigation_finished():
			action = Action.WAIT
			wait()
		else:
			agent.velocity = character_type.SPEED * global_position.direction_to(
				agent.get_next_path_position()
			) * clampf(
				agent.distance_to_target() / agent.target_desired_distance,
				0.0,
				1.0,
			)
	else:
		velocity = character_type.SPEED * Input.get_vector(
			player_mapping[Direction.LEFT],
			player_mapping[Direction.RIGHT],
			player_mapping[Direction.UP],
			player_mapping[Direction.DOWN],
		)
		apply_generic_velocity()

func apply_generic_velocity() -> void:
	if velocity.length() > 0.0 and abs(velocity.x) > 0.5:
		%Sprite.play('walk')
		%Sprite.speed_scale = clampf(velocity.length() / character_type.SPEED, 0.25, 1.0)
		%Visuals.scale.x = 1.0 if velocity.x > 0.0 else -1.0
	else:
		%Sprite.play('default')
		%Sprite.speed_scale = 1.0
	move_slide_and_collide()

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	if is_dead or not is_bot:
		return

	velocity = lerp(
		velocity,
		safe_velocity,
		0.1 if action == Action.WAIT else 0.5,
	).limit_length(
		character_type.SPEED * (0.2 if action == Action.WAIT else 1.0)
	)
	apply_generic_velocity()

func _unhandled_input(event: InputEvent) -> void:
	if is_bot:
		return

	if action != Action.ATTACK and event.is_action_pressed(player_mapping[Action.ATTACK]):
		action = Action.ATTACK
		%Sprite.play("attack")
		%AttackCollisionShape.disabled = false
		var tween := create_tween()
		tween.tween_property(
			self, "velocity:x",
			-character_type.ATTACK_CHARGE_SPEED * signf(%Visuals.scale.x),
			0.2,
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_callback(on_attack_action)


func get_collision_shape() -> CollisionShape2D:
	return %CollisionShape2D


func on_attack_action() -> void:
	for body in %AttackArea.get_overlapping_bodies():
		if body is Character and body != self:
			body.is_dead = true
	%AttackCollisionShape.disabled = true
	var tween := create_tween()
	tween.tween_property(
		self, "velocity:x",
		character_type.ATTACK_SPEED * signf(%Visuals.scale.x),
		0.1,
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(on_attack_end)

func on_attack_end() -> void:
	action = Action.WAIT

func _on_wait_timer_timeout() -> void:
	if not is_bot:
		return
	action = bot_actions_probabilities.pick_random()
	if action == Action.WAIT:
		wait()
	elif action == Action.TURN:
		%Visuals.scale.x = -%Visuals.scale.x
		action = Action.WAIT
		wait()
	elif action == Action.EMBARK:
		agent.target_position = Vector2(Globals.width, Globals.height)
	else:
		agent.target_position = Globals.get_random_position()
