class_name Bot
extends AnimatableBody2D


var character_type: CharacterType = Globals.character_types.pick_random()


func _ready() -> void:
	%Sprite.sprite_frames = character_type.sprite_frames


func get_collision_shape() -> CollisionShape2D:
	return $CollisionShape2D
