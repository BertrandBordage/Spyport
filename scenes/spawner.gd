class_name Spawner
extends Node2D

const character_scene := preload("res://scenes/character.tscn")
const trolley_scene := preload("res://scenes/obstacles/trolley.tscn")

@onready var physics_state := get_world_2d().direct_space_state
var shape_params := PhysicsShapeQueryParameters2D.new()


func spawn_child_in_empty_space(
	instance: PhysicsBody2D, collision_shape: CollisionShape2D,
) -> void:
	shape_params.shape = collision_shape.shape
	while true:
		instance.position = Globals.get_random_position()
		shape_params.transform = collision_shape.transform.translated(instance.position)
		if physics_state.intersect_shape(shape_params, 1).size() == 0:
			add_child.call_deferred(instance)
			break


func _ready() -> void:
	for i in range(4):
		var character: Character = character_scene.instantiate()
		character.player_index = i as Character.PlayerIndex
		var collision_shape := character.get_collision_shape()
		spawn_child_in_empty_space(character, collision_shape)
	
	for _i in range(300):
		var bot: Character = character_scene.instantiate()
		bot.player_index = Character.PlayerIndex.BOT
		var collision_shape := bot.get_collision_shape()
		spawn_child_in_empty_space(bot, collision_shape)

	for i in range(20):
		var trolley: Trolley = trolley_scene.instantiate()
		var collision_shape := trolley.get_collision_shape()
		spawn_child_in_empty_space(trolley, collision_shape)
