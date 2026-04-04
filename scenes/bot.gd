class_name Bot
extends CharacterBody2D

enum Action { WAIT, WALK, TURN, EMBARK, ATTACK }

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
	if is_dead:
		return

	velocity = lerp(
		velocity,
		safe_velocity,
		0.1 if action == Action.WAIT else 0.5,
	).limit_length(
		character_type.SPEED * (0.2 if action == Action.WAIT else 1.0)
	)
	if velocity.length() > 0 and abs(velocity.x) > 0.5:
		%Sprite.play('walk')
		%Sprite.speed_scale = clampf(velocity.length() / character_type.SPEED, 0.25, 1.0)
		%Visuals.scale.x = 1.0 if velocity.x > 0.0 else -1.0
	else:
		%Sprite.play('default')
		%Sprite.speed_scale = 1.0
	move_slide_and_collide()


func get_collision_shape() -> CollisionShape2D:
	return %CollisionShape2D


func _on_wait_timer_timeout() -> void:
	action = actions_probabilities.pick_random()
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
