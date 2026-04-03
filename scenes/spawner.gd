class_name Spawner
extends Node2D

const bot_scene := preload("res://scenes/bot.tscn")
const player_scene := preload("res://scenes/player.tscn")

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
		var player: Player = player_scene.instantiate()
		player.player_index = i as Player.PlayerIndex
		var collision_shape := player.get_collision_shape()
		spawn_child_in_empty_space(player, collision_shape)
	
	for _i in range(300):
		var bot: Bot = bot_scene.instantiate()
		var collision_shape := bot.get_collision_shape()
		spawn_child_in_empty_space(bot, collision_shape)
