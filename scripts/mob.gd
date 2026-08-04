extends CharacterBody2D
@export var velocity_min: float = 150.0
@export var velocity_max: float = 250.0

func init(direction: float, _flip_v: bool) -> void:
	rotation = direction
	velocity = Vector2(randf_range(velocity_min, velocity_max), 0.0).rotated(direction)
	$AnimatedSprite2D.play(Array($AnimatedSprite2D.sprite_frames.get_animation_names()).pick_random())

func _process(delta: float) -> void:
	position += velocity * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
