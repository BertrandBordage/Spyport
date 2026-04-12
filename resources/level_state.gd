class_name LevelState
extends Resource


var players_characters: Dictionary[Character.PlayerIndex, Character] = {}
var players_scores: Dictionary[Character.PlayerIndex, int] = {
	Character.PlayerIndex.ONE: 0,
	Character.PlayerIndex.TWO: 0,
	Character.PlayerIndex.THREE: 0,
	Character.PlayerIndex.FOUR: 0,
}
var action_targets: Dictionary[Character.Action, Array] = {}
var spawner: Spawner
