class_name Player
extends CharacterBody2D

enum PlayerIndex { ONE = 0, TWO = 1, THREE = 2, FOUR = 3 }
enum Direction { UP, DOWN, LEFT, RIGHT }

const ACTIONS_MAPPING: Dictionary[PlayerIndex, Dictionary] = {
	PlayerIndex.ONE: {
		Direction.UP: "player_0_up",
		Direction.DOWN: "player_0_down",
		Direction.LEFT: "player_0_left",
		Direction.RIGHT: "player_0_right",
		"attack": "player_0_attack",
	},
	PlayerIndex.TWO: {
		Direction.UP: "player_1_up",
		Direction.DOWN: "player_1_down",
		Direction.LEFT: "player_1_left",
		Direction.RIGHT: "player_1_right",
		"attack": "player_1_attack",
	},
	PlayerIndex.THREE: {
		Direction.UP: "player_2_up",
		Direction.DOWN: "player_2_down",
		Direction.LEFT: "player_2_left",
		Direction.RIGHT: "player_2_right",
		"attack": "player_2_attack",
	},
	PlayerIndex.FOUR: {
		Direction.UP: "player_3_up",
		Direction.DOWN: "player_3_down",
		Direction.LEFT: "player_3_left",
		Direction.RIGHT: "player_3_right",
		"attack": "player_3_attack",
	},
}

@export var player_index: PlayerIndex = PlayerIndex.ONE
@onready var player_mapping := ACTIONS_MAPPING[player_index]
var character_type: CharacterType = Globals.character_types.pick_random()
var is_attacking := false
var is_dead := false:
	set(value):
		is_dead = value
		%Sprite.play("dead")
		%Shadow.visible = not is_dead
		%Blood.visible = is_dead
		if is_dead:
			%CollisionShape2D.disabled = true
			%Blood.visible = is_dead
			%Blood.scale = Vector2.ZERO
			var tween := create_tween()
			tween.tween_property(
				%Blood, 'scale', Vector2(1.5, 1.5), 5.0,
			).set_ease(Tween.EASE_OUT)

func _ready() -> void:
	%Sprite.sprite_frames = character_type.sprite_frames
	%Visuals.scale.x = -1.0 if randi_range(0, 1) == 0 else 1.0

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

func _physics_process(_delta: float) -> void:
	if is_dead:
		return
	if is_attacking:
		move_slide_and_collide()
		return

	velocity = character_type.SPEED * Input.get_vector(
		player_mapping[Direction.LEFT],
		player_mapping[Direction.RIGHT],
		player_mapping[Direction.UP],
		player_mapping[Direction.DOWN],
	)
	if velocity.length() > 0.0:
		%Sprite.play('walk')
		%Sprite.speed_scale = clampf(velocity.length() / character_type.SPEED, 0.25, 1.0)
		%Visuals.scale.x = -1.0 if velocity.x < 0 else 1.0
		move_slide_and_collide()
	else:
		%Sprite.play('default')
		%Sprite.speed_scale = 1.0

func _unhandled_input(_event: InputEvent) -> void:
	if not is_attacking and Input.is_action_just_pressed(player_mapping["attack"]):
		is_attacking = true
		%Sprite.play("attack")
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
		if body is Bot or body is Player and body != self:
			body.is_dead = true
	var tween := create_tween()
	tween.tween_property(
		self, "velocity:x",
		character_type.ATTACK_SPEED * signf(%Visuals.scale.x),
		0.1,
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(on_attack_end)

func on_attack_end() -> void:
	is_attacking = false
