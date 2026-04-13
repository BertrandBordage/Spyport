class_name Trolley
extends RigidBody2D


var textures := [
	preload("res://assets/obstacles/trolley0.png"),
	preload("res://assets/obstacles/trolley1.png"),
	preload("res://assets/obstacles/trolley2.png"),
	preload("res://assets/obstacles/trolley3.png"),
]

func _ready() -> void:
	%Sprite.texture = textures.pick_random()
	%Sprite.scale.x = -1.0 if randi_range(0, 1) == 0 else 1.0


func get_collision_shape() -> CollisionShape2D:
	return $CollisionShape2D
