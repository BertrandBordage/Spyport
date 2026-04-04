extends Node

var width := DisplayServer.window_get_size().x
var height := DisplayServer.window_get_size().y
var character_types: Array[CharacterType] = [
	preload("res://resources/characters/janitor.tres"),
	preload("res://resources/characters/stewardess.tres"),
	preload("res://resources/characters/guard.tres"),
	preload("res://resources/characters/businessman.tres"),
	preload("res://resources/characters/businessman.tres"),
	preload("res://resources/characters/businessman.tres"),
	preload("res://resources/characters/tourist.tres"),
	preload("res://resources/characters/tourist.tres"),
	preload("res://resources/characters/tourist.tres"),
]
var players_characters: Dictionary[Character.PlayerIndex, Character] = {}


func get_random_position():
	return Vector2(randf_range(0, width), randf_range(90, height))
