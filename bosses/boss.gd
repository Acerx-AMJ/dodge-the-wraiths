extends CharacterBody2D

@export var servant_scenes: Array[PackedScene]
@export var velocity_min: float = 75.0
@export var velocity_max: float = 150.0
@export var servant_spawn_speed: float = 2.0

var player: Node2D
var spawn_timer: float = servant_spawn_speed / 2.0

func init(_direction: float) -> void:
	player = $"../Player"
	var direction = position.angle_to_point(player.position)
	rotation = direction
	velocity = Vector2(randf_range(velocity_min, velocity_max), 0.0).rotated(direction)
	$AnimatedSprite2D.play(Array($AnimatedSprite2D.sprite_frames.get_animation_names()).pick_random())

func _process(delta: float) -> void:
	position += velocity * delta

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		var servant = servant_scenes.pick_random().instantiate()
		servant.position = position
		get_parent().add_child(servant)
		servant.init(position.angle_to_point(player.position) + randf_range(-PI / 16, PI / 16))

		spawn_timer += servant_spawn_speed * randf_range(0.8, 1.2)
		var texture = $AnimatedSprite2D.sprite_frames.get_frame_texture($AnimatedSprite2D.animation, $AnimatedSprite2D.get_frame())
		get_parent().spawn_death_particles(texture, position)
		$SummonSound.play()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
