extends Node

@warning_ignore("unused_signal")
signal player_joined(character: Character)
signal character_died(character: Character, killer: Character)
signal character_count_changed
signal game_over

var width := DisplayServer.window_get_size().x
var height := DisplayServer.window_get_size().y
var character_types: Array[CharacterType] = [
	preload("res://resources/characters/janitor.tres"),
	preload("res://resources/characters/stewardess.tres"),
	preload("res://resources/characters/guard.tres"),
	preload("res://resources/characters/businessman.tres"),
	preload("res://resources/characters/tourist.tres"),
	preload("res://resources/characters/girl.tres"),
	preload("res://resources/characters/manager.tres"),
]
var level_state: LevelState
var physics_state: PhysicsDirectSpaceState2D
var shape_params := PhysicsShapeQueryParameters2D.new()


func _ready() -> void:
	character_died.connect(_on_character_died)
	character_count_changed.connect(_on_character_count_changed)


func _on_character_died(_character: Character, _killer: Character) -> void:
	character_count_changed.emit()


func _on_character_count_changed() -> void:
	if level_state.spawner.get_available_characters().size() == 0:
		game_over.emit()


func is_empty_space(
	position: Vector2, collision_shape: CollisionShape2D,
) -> bool:
	shape_params.shape = collision_shape.shape
	shape_params.transform = collision_shape.transform.translated(position)
	return physics_state.intersect_shape(shape_params, 1).size() == 0


func get_random_position(collision_shape: CollisionShape2D) -> Vector2:
	while true:
		var position := Vector2(randf_range(0, width), randf_range(90, height))
		if is_empty_space(position, collision_shape):
			return position
	return Vector2.ZERO


func spawn_child_in_empty_space(
	instance: PhysicsBody2D, collision_shape: CollisionShape2D,
) -> void:
	shape_params.shape = collision_shape.shape
	instance.position = get_random_position(collision_shape)
	level_state.spawner.add_child.call_deferred(instance)
