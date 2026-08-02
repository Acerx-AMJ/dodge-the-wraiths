extends CharacterBody2D
var initial_velocity
var initial_rotation
var timer = TAU

func init(direction: float, vel: Vector2) -> void:
	rotation = direction
	velocity = vel.rotated(direction)
	initial_velocity = vel
	initial_rotation = direction
	$AnimatedSprite2D.play(Array($AnimatedSprite2D.sprite_frames.get_animation_names()).pick_random())

func _process(delta: float) -> void:
	timer += delta
	rotation = initial_rotation + sin(timer * 2.0) * 0.4
	velocity = initial_velocity.rotated(rotation)
	position += velocity * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
