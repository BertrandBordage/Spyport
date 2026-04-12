class_name Game
extends NavigationRegion2D

@onready var fade: ColorRect = %Fade

func _ready() -> void:
	fade.color.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 0.0, 3.0).set_ease(Tween.EASE_OUT)
