extends Node

const WIDTH := 1280
const HEIGHT := 720
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


func get_random_position():
	return Vector2(randf_range(0, WIDTH), randf_range(0, HEIGHT))
