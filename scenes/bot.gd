class_name Bot
extends CharacterBody2D

enum Action { WAIT, WALK, TURN, EMBARK }

var actions_probabilities = [
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
	Action.EMBARK,
	Action.EMBARK,
]
var character_type: CharacterType = Globals.character_types.pick_random()
@onready var agent: NavigationAgent2D = %NavigationAgent2D
var action := Action.WAIT
var is_dead := false:
	set(value):
		is_dead = value
		%Shadow.visible = not is_dead
		%Blood.visible = is_dead


func _ready() -> void:
	agent.max_speed = character_type.SPEED
	%Sprite.sprite_frames = character_type.sprite_frames
	%Sprite.scale.x = -1.0 if randi_range(0, 1) == 0 else 1.0
	_on_wait_timer_timeout()


func wait() -> void:
	%WaitTimer.wait_time = randf_range(3.0, 10.0)
	%WaitTimer.start()


func _physics_process(_delta: float) -> void:
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

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = lerp(
		velocity,
		safe_velocity,
		0.1 if action == Action.WAIT else 0.5,
	).limit_length(
		character_type.SPEED * (0.2 if action == Action.WAIT else 1.0)
	)
	if velocity.length() > 0 and abs(velocity.x) > 0.5:
		%Sprite.play('walk')
		%Sprite.scale.x = 1.0 if velocity.x > 0.0 else -1.0
		%Sprite.speed_scale = velocity.length() / character_type.SPEED
	else:
		%Sprite.play('default')
		%Sprite.speed_scale = 1.0
	move_and_slide()


func get_collision_shape() -> CollisionShape2D:
	return $CollisionShape2D


func _on_wait_timer_timeout() -> void:
	action = actions_probabilities.pick_random()
	if action == Action.WAIT:
		wait()
	elif action == Action.TURN:
		%Sprite.scale.x = -%Sprite.scale.x
		action = Action.WAIT
		wait()
	elif action == Action.EMBARK:
		agent.target_position = Vector2(Globals.width, Globals.height)
	else:
		agent.target_position = Globals.get_random_position()
