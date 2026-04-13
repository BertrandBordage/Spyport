class_name TopWallVisuals
extends ColorRect

@onready var players_labels = {
	Character.PlayerIndex.ONE: %Player1Score,
	Character.PlayerIndex.TWO: %Player2Score,
	Character.PlayerIndex.THREE: %Player3Score,
	Character.PlayerIndex.FOUR: %Player4Score,
}
var help_text_index := 0
var skipped_help_text_indexes: Array[int] = []

func _ready() -> void:
	Globals.player_joined.connect(_on_player_joined)
	Globals.character_died.connect(_on_character_died)
	%Help.text = get_help_texts()[help_text_index]


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
	for player_index in players_scores:
		players_labels[player_index].text = "Player %d score: %d" % [
			player_index + 1,
			players_scores[player_index]
		]

	for skipped_index in [1, 2, 3, 4]:
		if skipped_index not in skipped_help_text_indexes:
			skipped_help_text_indexes.append(skipped_index)


func get_keyboard_names(actions: Array[String]) -> String:
	var output: Array[String] = []
	for action in actions:
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				output.append(
					OS.get_keycode_string(
						DisplayServer.keyboard_get_label_from_physical(
							event.physical_keycode
						))
					)
				continue
	return "/".join(output)


func get_help_texts() -> Array[String]:
	return [
		"[pulse freq=2.0 ease=-20.0]Press A on 2 to 4 gamepads to start playing with your friends![/pulse]",
		"[pulse freq=2.0 ease=-20.0]Find your spy, locate other spies and kill them![/pulse]",
		"Gamepad controls:\nLeft stick to move, A to kill",
		"Keyboard controls (Player 1):\n%s to move, %s to kill" % [
			get_keyboard_names(["player_0_up", "player_0_left", "player_0_down", "player_0_right"]),
			get_keyboard_names(["player_0_attack"])
		],
		"Keyboard controls (Player 2):\n%s to move, %s to kill" % [
			get_keyboard_names(["player_1_up", "player_1_left", "player_1_down", "player_1_right"]),
			get_keyboard_names(["player_1_attack"])
		],
		"Players respawn as a new spy after a few seconds",
		"Keep fighting until you are the last one standing!",
	]


func _on_update_timer_timeout() -> void:
	if Globals.level_state.players_characters.size() > 0:
		%Help.visible = not %Help.visible
		%ScoresContainer.visible = not %ScoresContainer.visible
	if %Help.visible:
		var help_texts := get_help_texts()

		if Globals.level_state.players_characters.size() >= 2 and 0 not in skipped_help_text_indexes:
			skipped_help_text_indexes.append(0)

		while true:
			help_text_index = help_text_index + 1 % help_texts.size()
			if help_text_index not in skipped_help_text_indexes:
				break

		%Help.text = help_texts[help_text_index % help_texts.size()]
