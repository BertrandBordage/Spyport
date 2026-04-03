class_name Player
extends CharacterBody2D
 
enum PlayerIndex { ONE = 0, TWO = 1, THREE = 2, FOUR = 3 }
enum Direction { UP, DOWN, LEFT, RIGHT }

const SPEED := 200.0

const ACTIONS_MAPPING: Dictionary[PlayerIndex, Dictionary] = {
	PlayerIndex.ONE: {
		Direction.UP: "player_0_up",
		Direction.DOWN: "player_0_down",
		Direction.LEFT: "player_0_left",
		Direction.RIGHT: "player_0_right",
	},
	PlayerIndex.TWO: {
		Direction.UP: "player_1_up",
		Direction.DOWN: "player_1_down",
		Direction.LEFT: "player_1_left",
		Direction.RIGHT: "player_1_right",
	},
	PlayerIndex.THREE: {
		Direction.UP: "player_2_up",
		Direction.DOWN: "player_2_down",
		Direction.LEFT: "player_2_left",
		Direction.RIGHT: "player_2_right",
	},
	PlayerIndex.FOUR: {
		Direction.UP: "player_3_up",
		Direction.DOWN: "player_3_down",
		Direction.LEFT: "player_3_left",
		Direction.RIGHT: "player_3_right",
	},
}

@export var player_index: PlayerIndex = PlayerIndex.ONE
@onready var player_mapping := ACTIONS_MAPPING[player_index]

func _physics_process(_delta: float) -> void:
	velocity = SPEED * Input.get_vector(
		player_mapping[Direction.LEFT],
		player_mapping[Direction.RIGHT],
		player_mapping[Direction.UP],
		player_mapping[Direction.DOWN],
	)
	if velocity.length() > 0.0:
		%Sprite.scale.x = -1.0 if velocity.x < 0 else 1.0
		move_and_slide()
