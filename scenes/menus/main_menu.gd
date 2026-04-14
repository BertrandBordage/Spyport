class_name MainMenu
extends Control

# MAIN
@onready var background : Node2D = %BackGround
@onready var title : TextureRect = $Title
@onready var clouds : Node2D = $BackGround/Clouds
@onready var extras : Node2D = $BackGround/Extras
@onready var camera: Camera2D = %Camera2D

const game_scene: PackedScene = preload("res://scenes/game.tscn")


# EXTRAS (figurants)
const extra_scene = preload("res://scenes/menus/extra_for_menu.tscn")
const SPAWN_LEFT : Vector2 = Vector2(-100,600)
const SPAWN_RIGHT : Vector2 = Vector2(1380,600)
const SPAWN_MARGIN : float = 100

# SCORES
@onready var info_panel : NinePatchRect = %InfoPanel
@onready var panel_text : RichTextLabel = %Text
const START_BBCODE_TEXT : String = "[pulse freq=2.0 color=#ffffff40 ease=-20.0]Press any key[/pulse]"
var can_skip := false

func _ready() -> void :
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Globals.level_state == null:
		await get_tree().create_timer(0.5).timeout
		await pan_camera()
		await get_tree().create_timer(1).timeout
		fade_title()
		show_panel()
	else:
		camera.global_position.y = 0.0
		title.modulate.a = 1.0
		await show_panel(Globals.level_state.players_scores)
	can_skip = true


func _unhandled_input(event: InputEvent) -> void:
	if can_skip and (event is InputEventJoypadButton or event is InputEventKey):
		var tween := create_tween().set_parallel()
		tween.tween_property(self, "modulate:v", 0.0, 1.0)
		tween.tween_property($AudioStreamPlayer, "volume_linear", 0.0, 1.0)
		await tween.finished
		var game: Game = game_scene.instantiate()
		queue_free()
		get_tree().root.add_child(game)


func pan_camera():
	var tween = create_tween()
	tween.tween_property(camera, "global_position:y", 0.0, 3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

func fade_title() -> void:
	var tween = create_tween()
	tween.tween_property(title, "modulate:a", 1.0 , 2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

## If Array is empty, it will show START_BBCODE_TEXT
func show_panel(scores: Dictionary[Character.PlayerIndex, int] = {}) :
	panel_text.text = ""
	if scores.size() > 0 : # Show score
		var tween = create_tween().set_parallel()
		tween.tween_property(info_panel, "global_position:y", -64, 1).as_relative().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(info_panel, "size:y", 375 , 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		await tween.finished
		var final_text := ["[center]- SCORE -[/center]\n"]
		var sorted_player_indexes := scores.keys()
		sorted_player_indexes.sort()
		for player_index in sorted_player_indexes: # Add score 4 times
			var score := scores[player_index]
			final_text.append("Player %d%s" % [player_index + 1, str(score).lpad(9)])
		final_text.append("\n%s" % START_BBCODE_TEXT)
		panel_text.text = "\n".join(final_text)
	else : # Show Press A
		var tween = create_tween()
		tween.tween_property(info_panel, "size:y", 80 , 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		await tween.finished
		panel_text.text = START_BBCODE_TEXT

func spawn_extra() :
	# VARIABLES
	var left_direction = [true,false].pick_random()
	var extra_position : Vector2 = SPAWN_LEFT
	if left_direction :
		extra_position = SPAWN_RIGHT
	extra_position.y += randf_range(-SPAWN_MARGIN, SPAWN_MARGIN)
	
	# SPAWN
	var extra_instance = extra_scene.instantiate()
	# ANIMATION
	var types : PackedStringArray = extra_instance.sprite_frames.get_animation_names()
	var indexes : int = types.size() # can't do pick_random here
	var type : String = types[randi_range(0,indexes-1)]
	await get_tree().create_timer(randf_range(0.0,0.4)).timeout # Decal animation for async
	extra_instance.play(type)
	extra_instance.flip_h = left_direction
	# NODE
	extras.add_child(extra_instance)
	extra_instance.global_position = extra_position
	
	# MOVE
	var distance = 1300
	var time = randf_range(10.0,16.0)
	if left_direction :
		distance *= -1
	var tween = create_tween()
	tween.tween_property(extra_instance, "position:x", distance, time)
	await tween.finished
	extra_instance.queue_free()


func _on_spawn_timer_timeout() -> void:
	spawn_extra()
