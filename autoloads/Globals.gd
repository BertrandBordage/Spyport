extends Node

signal player_joined(character: Character)
signal player_died(character: Character)

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
enum Objective { EXIT }
var objectives: Dictionary[Objective, Marker2D] = {}
var spawner: Node2D
var physics_state: PhysicsDirectSpaceState2D
var shape_params := PhysicsShapeQueryParameters2D.new()


func get_random_position(collision_shape: CollisionShape2D) -> Vector2:
	while true:
		var position := Vector2(randf_range(0, width), randf_range(90, height))
		if is_empty_space(position, collision_shape):
			return position
	return Vector2.ZERO


func is_empty_space(
	position: Vector2, collision_shape: CollisionShape2D,
) -> bool:
	shape_params.shape = collision_shape.shape
	shape_params.transform = collision_shape.transform.translated(position)
	return physics_state.intersect_shape(shape_params, 1).size() == 0

func spawn_child_in_empty_space(
	instance: PhysicsBody2D, collision_shape: CollisionShape2D,
) -> void:
	shape_params.shape = collision_shape.shape
	instance.position = Globals.get_random_position(collision_shape)
	spawner.add_child.call_deferred(instance)
