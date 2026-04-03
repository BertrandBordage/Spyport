class_name Bot
extends AnimatableBody2D


@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func get_collision_shape() -> CollisionShape2D:
	return $CollisionShape2D
