class_name PlayerDisplay
extends Node2D


@export var player_index: Character.PlayerIndex = Character.PlayerIndex.ONE
var character: Character


func _ready() -> void:
	Globals.player_joined.connect(_on_player_joined)
	Globals.player_died.connect(_on_player_died)
	%Label.text = "P%d" % (player_index + 1)


func _on_player_joined(_character: Character) -> void:
	if _character.player_index == player_index:
		character = _character
		%EmptyLabel.queue_free()
		%Sprite.sprite_frames = character.character_type.sprite_frames
		%Sprite.visible = true

func _on_player_died(_character: Character) -> void:
	if _character == character:
		%Sprite.animation = "dead"
