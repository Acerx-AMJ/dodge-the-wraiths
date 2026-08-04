extends CharacterBody2D
@export var velocity_min: float = 150.0
@export var velocity_max: float = 250.0

var initial_velocity: Vector2

func init(direction: float) -> void:
	rotation = direction
	initial_velocity = Vector2(randf_range(velocity_min, velocity_max), 0.0).rotated(direction)
	velocity = Vector2(0, 0)
	$AnimatedSprite2D.play(Array($AnimatedSprite2D.sprite_frames.get_animation_names()).pick_random())

func _process(delta: float) -> void:
	if abs(velocity.x) < 15 and abs(velocity.y) < 15:
		velocity = initial_velocity
	position += velocity * delta
	velocity *= 1.0 - delta
	$AnimatedSprite2D.speed_scale = velocity.length() / 250

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
