extends Control

# MAIN
@onready var background : Node2D = %BackGround
@onready var title : TextureRect = $Title
@onready var clouds : Node2D = $BackGround/Clouds
@onready var extras : Node2D = $BackGround/Extras
@onready var camera: Camera2D = %Camera2D


# EXTRAS (figurants)
const extra_scene = preload("res://scenes/menus/extra_for_menu.tscn")
const SPAWN_LEFT : Vector2 = Vector2(-100,600)
const SPAWN_RIGHT : Vector2 = Vector2(1380,600)
const SPAWN_MARGIN : float = 100
const SPAWN_TIMER_RESET = 1.0
var spawn_timer : float = 1.0

# SCORES
@onready var info_panel : NinePatchRect = %InfoPanel
@onready var panel_text : RichTextLabel = %Text
const START_BBCODE_TEXT : String = "[pulse freq=2.0 color=#ffffff40 ease=-20.0]Press any key[/pulse]"
var scores : Array = [13,null,2,35]

func _ready() -> void :
	# Show AIRPORT and TITLE
	await get_tree().create_timer(1).timeout
	await move_airport()
	await get_tree().create_timer(1).timeout
	fade_title()
	await get_tree().create_timer(1).timeout
	# Ready to press A
	show_panel()
	
	# ---
	
	# Show score
	#show_panel(score)
	
	# Get OUT
	#await fade_title(0)
	#move_airport(-720)
	# load scene ?


func _process(delta):
	spawn_timer = spawn_timer - delta
	if spawn_timer < 0 :
		spawn_timer = SPAWN_TIMER_RESET
		spawn_extra()


func move_airport(y_value : int = 0):
	var tween = create_tween()
	tween.tween_property(camera, "global_position:y", y_value, 3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

func fade_title(alpha_value : float = 255) :
	var tween = create_tween()
	tween.tween_property(title, "modulate:a", alpha_value , 2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

## If Array is empty, it will show START_BBCODE_TEXT
func show_panel(score : Array = []) :
	panel_text.text = ""
	if score.size() > 0 : # Show score
		var tween = create_tween()
		tween.tween_property(info_panel, "size:y", 280 , 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		await tween.finished
		var final_text = "[center]- SCORE -[/center]\n"
		for i in range(4) : # Add score 4 times
			var score_int = score[i]
			var score_str
			if !score_int : # if score null
				score_str = "\nPlayer "+ str(i+1) + ("".lpad(9))
			else :
				score_str = "\nPlayer "+ str(i+1) + (str(score_int).lpad(9))
			final_text += score_str
		panel_text.text = final_text
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
