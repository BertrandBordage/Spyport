extends Control

# MAIN
@onready var background : Node2D = $BackGround
@onready var title : TextureRect = $Title

# SCORES
@onready var info_panel : NinePatchRect = $BackGround/InfoPannel
@onready var panel_text : RichTextLabel = $BackGround/InfoPannel/MarginContainer/RichTextLabel
const START_BBCODE_TEXT : String = "[center][pulse freq=2.0 color=#ffffff40 ease=-20.0]Press A to Start[/pulse][/center]"
var scores : Array = [13,null,2,35]

func _ready() -> void :
	await get_tree().create_timer(1).timeout
	await move_airport()
	await get_tree().create_timer(1).timeout
	fade_title()
	await get_tree().create_timer(1).timeout
	show_pannel(scores)
	await get_tree().create_timer(2).timeout
	show_pannel()
	await get_tree().create_timer(2).timeout
	await fade_title(0)
	move_airport(-720)


func move_airport(y_value : int = 0):
	var tween = get_tree().create_tween()
	tween.tween_property(background, "global_position:y", y_value, 3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	pass

func fade_title(alpha_value : float = 255) :
	var tween = get_tree().create_tween()
	tween.tween_property(title, "modulate:a", alpha_value , 2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

## If Array is empty, it will show START_BBCODE_TEXT
func show_pannel(score : Array = []) :
	panel_text.text = ""
	if score.size() > 0 : # Show score
		var tween = get_tree().create_tween()
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
		var tween = get_tree().create_tween()
		tween.tween_property(info_panel, "size:y", 80 , 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		await tween.finished
		panel_text.text = START_BBCODE_TEXT
