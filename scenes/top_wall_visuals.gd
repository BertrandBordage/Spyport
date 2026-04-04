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
	if Globals.players_characters.size() >= 2:
		%Help.visible = false
		%ScoresContainer.visible = true
	players_labels[character.player_index].visible = true

func _on_character_died(character: Character, killer: Character) -> void:
	Globals.players_scores[killer.player_index] += 1 if character.is_bot else 5
	if not character.is_bot:
		Globals.players_scores[character.player_index] -= 5
	players_labels[killer.player_index].text = "Player %d score: %d" % [
		killer.player_index,
		Globals.players_scores[killer.player_index]
	]
