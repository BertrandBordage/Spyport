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

func _ready() -> void:
	%Sprite.sprite_frames = character_type.sprite_frames
	%Sprite.scale.x = -1.0 if randi_range(0, 1) == 0 else 1.0

func _physics_process(_delta: float) -> void:
	velocity = character_type.SPEED * Input.get_vector(
		player_mapping[Direction.LEFT],
		player_mapping[Direction.RIGHT],
		player_mapping[Direction.UP],
		player_mapping[Direction.DOWN],
	)
	if velocity.length() > 0.0:
		%Sprite.play('walk')
		%Sprite.scale.x = -1.0 if velocity.x < 0 else 1.0
		move_and_slide()
		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			var collider := collision.get_collider()
			if collider is RigidBody2D:
				collider.apply_central_impulse(
					-collision.get_normal() * character_type.PUSH_STRENGTH
				)
	else:
		%Sprite.play('default')

func get_collision_shape() -> CollisionShape2D:
	return %CollisionShape2D
