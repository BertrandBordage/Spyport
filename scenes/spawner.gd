class_name Spawner
extends Node2D

const character_scene := preload("res://scenes/character.tscn")
const trolley_scene := preload("res://scenes/obstacles/trolley.tscn")


func _ready() -> void:
	Globals.spawner = self
	Globals.physics_state = get_world_2d().direct_space_state
	
	for _i in range(300):
		var character: Character = character_scene.instantiate()
		character.player_index = Character.PlayerIndex.BOT
		var collision_shape := character.get_collision_shape()
		Globals.spawn_child_in_empty_space(character, collision_shape)

	for i in range(20):
		var trolley: Trolley = trolley_scene.instantiate()
		var collision_shape := trolley.get_collision_shape()
		Globals.spawn_child_in_empty_space(trolley, collision_shape)


static func is_available_character(node: Node):
	var taken_character_types: Array[CharacterType] = []
	for character in Globals.players_characters.values():
		taken_character_types.append(character.character_type)
	return is_instance_valid(node) and node is Character and node.character_type not in taken_character_types


func _unhandled_input(event: InputEvent) -> void:
	for player_index in range(4):
		if player_index in Globals.players_characters:
			continue
		if event.is_action_pressed(
			Character.ACTIONS_MAPPING[player_index][Character.Action.ATTACK]
		):
			var character: Character = get_children().filter(
				is_available_character
			).pick_random()
			character.player_index = player_index as Character.PlayerIndex
			Globals.players_characters[character.player_index] = character
			Globals.player_joined.emit(character)
