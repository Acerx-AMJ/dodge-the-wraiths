extends CharacterBody2D

func init(direction: float, vel: Vector2) -> void:
	rotation = direction
	velocity = vel.rotated(direction)
	$AnimatedSprite2D.play(Array($AnimatedSprite2D.sprite_frames.get_animation_names()).pick_random())

func _process(delta: float) -> void:
	position += velocity * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
