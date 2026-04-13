class_name Character
extends CharacterBody2D

enum Action { WAIT, WALK, TURN, EMBARK, ATTACK, PANIC, FLEE }
enum PlayerIndex { ONE = 0, TWO = 1, THREE = 2, FOUR = 3, BOT = -1 }

@warning_ignore("unused_signal")
signal action_changed(action: Action)

const player_component_scene: PackedScene = preload("res://scenes/player_component.tscn")
const bot_component_scene: PackedScene = preload("res://scenes/bot_component.tscn")
const dead_component_scene: PackedScene = preload("res://scenes/dead_component.tscn")

var player_index: PlayerIndex = PlayerIndex.ONE:
	set(value):
		player_index = value
		action = Action.WAIT
		update_collision()
		if not is_bot:
			if bot_component != null:
				bot_component.queue_free()
			if player_component == null:
				player_component = player_component_scene.instantiate()
				player_component.character = self
				add_child(player_component)
var character_type: CharacterType = Globals.character_types.pick_random()
@onready var visuals: Node2D = %Visuals
@onready var shadow: Sprite2D = %Shadow
@onready var sprite: AnimatedSprite2D = %Sprite
@onready var head_marker: Marker2D = %HeadMarker
@onready var agent: NavigationAgent2D = %NavigationAgent2D
var player_component: PlayerComponent
var bot_component: BotComponent
var dead_component: DeadComponent

var action := Action.WAIT:
	set(value):
		action = value
		action_changed.emit(action)
var is_dead := false:
	set(value):
		is_dead = value
		shadow.visible = not is_dead
		sprite.z_index = (
			-1 if is_dead else 0 # Makes the body "part of the ground" when dead.
		)
		update_collision()
		if is_dead:
			sprite.play("dead")
			agent.avoidance_enabled = false
			sprite.rotation = randf_range(-PI/6, PI/6)
			if player_component != null:
				player_component.queue_free()
			if bot_component != null:
				bot_component.queue_free()
			dead_component = dead_component_scene.instantiate()
			dead_component.character = self
			visuals.add_child(dead_component)
var is_bot: bool:
	get:
		return player_index == PlayerIndex.BOT
var has_panicked: bool = false
var seen_dead: Character

func _ready() -> void:
	agent.max_speed = character_type.SPEED
	sprite.sprite_frames = character_type.sprite_frames
	visuals.scale.x = -1.0 if randi_range(0, 1) == 0 else 1.0
	bot_component = bot_component_scene.instantiate()
	bot_component.character = self
	# Add it to the head, so the line of sight will be behind the sprite.
	head_marker.add_child(bot_component)

func move_slide_and_collide() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is RigidBody2D:
			collider.apply_central_impulse(
				-collision.get_normal() * character_type.PUSH_STRENGTH
				# Proportional to the character velocity when touching.
				* abs(collision.get_travel().dot(collision.get_normal()))
			)

	move_and_slide()

func update_collision() -> void:
	set_collision_layer_value(1, not is_dead)
	set_collision_mask_value(2, action not in [Action.EMBARK, Action.FLEE])


func apply_generic_velocity() -> void:
	if velocity.length() > 0.0:
		sprite.play('walk' if velocity.length() > 1.0 else 'default')
		sprite.speed_scale = clampf(velocity.length() / character_type.SPEED, 0.25, 1.0)
		if abs(velocity.x) > 0.5:
			visuals.scale.x = 1.0 if velocity.x > 0.0 else -1.0
		move_slide_and_collide()
	else:
		sprite.play('default')
		sprite.speed_scale = 1.0


func get_collision_shape() -> CollisionShape2D:
	return %CollisionShape2D


func _exit_tree() -> void:
	Globals.character_count_changed.emit()
