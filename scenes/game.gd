class_name Game
extends Node2D

# We load instead of preloading, to avoid this error: https://github.com/godotengine/godot/issues/102073
var main_menu_scene: PackedScene = load("res://scenes/menus/main_menu.tscn")
@onready var fade: ColorRect = %Fade

func _ready() -> void:
	Globals.game_over.connect(_on_game_over)
	fade.color.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 0.0, 3.0).set_ease(Tween.EASE_OUT)
	tween.tween_callback(hide_fade)


func hide_fade() -> void:
	fade.visible = false


func _on_game_over() -> void:
	fade.visible = true
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 3.0).set_ease(Tween.EASE_OUT)
	tween.tween_callback(back_to_menu)


func back_to_menu() -> void:
	var menu: MainMenu = main_menu_scene.instantiate()
	queue_free()
	get_tree().root.add_child(menu)
