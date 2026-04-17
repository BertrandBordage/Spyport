class_name LevelState
extends Resource


var players_characters: Dictionary[Character.PlayerIndex, Character] = {}
var players_scores: Dictionary[Character.PlayerIndex, int] = {}
var action_targets: Dictionary[Character.Action, Array] = {}
var spawner: Spawner


func add_player(character: Character) -> void:
	players_characters[character.player_index] = character
	if character.player_index not in players_scores:
		players_scores[character.player_index] = 0
