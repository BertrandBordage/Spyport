class_name DeadComponent
extends Node2D


@onready var blood: Sprite2D = %Blood


func _ready() -> void:
	blood.rotation = randf_range(-PI/6, PI/6)
	var tween := create_tween()
	tween.tween_property(
		blood, 'scale', Vector2(1.5, 1.5), 5.0,
	).set_ease(Tween.EASE_OUT)
