class_name TopWallVisuals
extends ColorRect

@onready var players_labels = {
	Character.PlayerIndex.ONE: %Player1Score,
	Character.PlayerIndex.TWO: %Player2Score,
	Character.PlayerIndex.THREE: %Player3Score,
	Character.PlayerIndex.FOUR: %Player4Score,
}

func _ready() -> void:
	Globals.player_joined.connect(_on_player_joined)
	Globals.character_died.connect(_on_character_died)


func _on_player_joined(character: Character) -> void:
	if Globals.level_state.players_characters.size() >= 2:
		%Help.visible = false
		%ScoresContainer.visible = true
	players_labels[character.player_index].visible = true

func _on_character_died(character: Character, killer: Character) -> void:
	var players_scores := Globals.level_state.players_scores
	players_scores[killer.player_index] += 1 if character.is_bot else 5
	if not character.is_bot:
		players_scores[character.player_index] -= 5
	for player_index in players_labels:
		players_labels[player_index].text = "Player %d score: [bold]%d[/bold]" % [
			player_index + 1,
			players_scores[player_index]
		]
