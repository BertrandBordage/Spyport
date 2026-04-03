class_name Spawner
extends Node2D

const bot_scene := preload("res://scenes/bot.tscn")


func _ready() -> void:
	var physics_state := get_world_2d().direct_space_state
	var shape_params := PhysicsShapeQueryParameters2D.new()
	for _i in range(1000):
		var bot: Bot = bot_scene.instantiate()
		var collision_shape := bot.get_collision_shape()
		shape_params.shape = collision_shape.shape
		while true:
			bot.position = Vector2(randf_range(0, 1280), randf_range(0, 720))
			shape_params.transform = collision_shape.transform.translated(bot.position)
			if physics_state.intersect_shape(shape_params, 1).size() == 0:
				add_child.call_deferred(bot)
				break
