extends CharacterBody2D
var jump_height: float = -75.0

var real_position: Vector2
var velocity_rotation: float
var jumping: bool = false
var jump_length: float
var jump_timer: float = 0.0
var delay_length: float
var delay_timer: float = 0.0

func jump() -> void:
	jumping = true
	jump_timer = 0.0
	jump_length = randf_range(0.8, 1.2)
	delay_timer = 0.0
	delay_length = randf_range(0.8, 1.2)

# Where t is [0; 1], basic symetric sine wave where 0 returns 0, 0.5 - 1 and 1 - 0
func jump_formula(t: float) -> float:
	return 1 - (cos(t * TAU) / 2 + 0.5)

func init(direction: float, vel: Vector2) -> void:
	velocity_rotation = direction
	velocity = vel.rotated(direction)
	real_position = position
	$AnimatedSprite2D.play(Array($AnimatedSprite2D.sprite_frames.get_animation_names()).pick_random())
	jump()

func _process(delta: float) -> void:
	if jumping:
		jump_timer += delta
		jumping = jump_timer < jump_length

		real_position += velocity * delta
		$Shadow.global_position = real_position
		position = real_position
		position.y += jump_formula(clamp(jump_timer / jump_length, 0.0, 1.0)) * jump_height
	else:
		delay_timer += delta
		if delay_timer >= delay_length:
			jump()

	$Shadow.visible = jumping
	$CollisionShape2D.disabled = jumping
	$AnimatedSprite2D.speed_scale = not jumping

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
