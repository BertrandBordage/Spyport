class_name Spawner
extends Node2D

const character_scene := preload("res://scenes/character.tscn")
const trolley_scene := preload("res://scenes/obstacles/trolley.tscn")
var max_characters := randi_range(100, 300)

func _ready() -> void:
	Globals.level_state = LevelState.new()
	Globals.level_state.spawner = self
	Globals.physics_state = get_world_2d().direct_space_state
	Globals.character_died.connect(_on_character_died)

	for _i in range(max_characters):
		var character: Character = character_scene.instantiate()
		character.player_index = Character.PlayerIndex.BOT
		var collision_shape := character.get_collision_shape()
		Globals.spawn_child_in_empty_space(character, collision_shape)

	for i in range(20):
		var trolley: Trolley = trolley_scene.instantiate()
		var collision_shape := trolley.get_collision_shape()
		Globals.spawn_child_in_empty_space(trolley, collision_shape)


func get_crowded_ratio() -> float:
	return (
		get_children().filter(
			func (child): return child is Character and not child.is_dead
		).size()
		/ float(max_characters)
	)


static func is_available_character(node: Node):
	var taken_character_types: Array[CharacterType] = []
	for character in Globals.level_state.players_characters.values():
		taken_character_types.append(character.type)
	if not (is_instance_valid(node) and node is Character):
		return false
	var character: Character = node
	return (
		not character.is_dead
		and character.type not in taken_character_types
	)


func get_available_characters() -> Array[Node]:
	return get_children().filter(is_available_character)


func replace_bot_with_player(player_index: Character.PlayerIndex, join_event: InputEvent) -> void:
	var available_characters := get_available_characters()
	if available_characters.size() == 0:
		return
	var character: Character = available_characters.pick_random()
	character.join_event = join_event
	character.player_index = player_index
	Globals.level_state.add_player(character)
	Globals.player_joined.emit(character)


func get_join_event_key(join_event: InputEvent) -> String:
	# For keys we use only the key label because we do not want modifiers (ctrl/shift)
	# to affect the identification of the key.
	if join_event is InputEventKey:
		return "%d" % join_event.key_label
	return "Device %d :: %s" % [join_event.device, join_event]


func _unhandled_input(event: InputEvent) -> void:
	var state := Globals.level_state
	if event.is_action_pressed("player_join"):
		if get_join_event_key(event) in state.players_characters.values().map(
			func (character: Character): return get_join_event_key(character.join_event)
		):
			return
		var last_player_index = state.players_characters.keys().max()
		var player_index: Character.PlayerIndex = (
			0 if last_player_index == null else last_player_index + 1
		)
		if player_index in state.players_characters:
			return
		replace_bot_with_player(player_index, event)

func _on_character_died(character: Character, _killer: Character) -> void:
	if character.is_bot:
		return

	await get_tree().create_timer(5.0).timeout

	replace_bot_with_player(character.player_index, character.join_event)
