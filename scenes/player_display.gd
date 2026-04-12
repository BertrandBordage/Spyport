class_name PlayerDisplay
extends Node2D


@export var player_index: Character.PlayerIndex = Character.PlayerIndex.ONE
var character: Character
const SHAKING_DISTANCE := 150.0


func _ready() -> void:
	Globals.player_joined.connect(_on_player_joined)
	Globals.character_died.connect(_on_character_died)
	%Name.texture = {
		Character.PlayerIndex.ONE: preload("res://assets/ui/player1.png"),
		Character.PlayerIndex.TWO: preload("res://assets/ui/player2.png"),
		Character.PlayerIndex.THREE: preload("res://assets/ui/player3.png"),
		Character.PlayerIndex.FOUR: preload("res://assets/ui/player4.png"),
	}[player_index]
	if player_index == Character.PlayerIndex.ONE:
		blink()

func blink() -> void:
	if not is_instance_valid(character):
		var tween := create_tween().set_loops(10)
		tween.tween_property(%EmptySprite, "modulate:a", 0.0, 0.25).set_delay(0.5)
		tween.tween_property(%EmptySprite, "modulate:a", 1.0, 0.25)


func _on_player_joined(_character: Character) -> void:
	if _character.player_index == player_index:
		character = _character
		%EmptySprite.visible = false
		%Sprite.sprite_frames = character.character_type.sprite_frames
		%Sprite.animation = "default"
		%Sprite.visible = true
	elif _character.player_index == player_index - 1:
		blink()

func _on_character_died(_character: Character, _killer: Character) -> void:
	if _character == character:
		set_shaking(0.0)
		%Sprite.animation = "dead"
	if _killer == character:
		set_shaking(0.0)


func set_shaking(value: float) -> void:
	%Sprite.set_instance_shader_parameter("shaking", value)


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(character):
		return

	if character.is_dead:
		return

	var closest_distance: float = INF
	for other in Globals.level_state.players_characters.values():
		if other == character or other.is_dead:
			continue

		var distance := character.global_position.distance_to(other.global_position)
		if distance < closest_distance:
			closest_distance = distance
	if not is_inf(closest_distance):
		set_shaking(
			clampf(
				(SHAKING_DISTANCE - closest_distance) / SHAKING_DISTANCE,
				0.0,
				1.0,
			)
		)
