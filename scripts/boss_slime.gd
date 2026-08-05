extends CharacterBody2D
@export var velocity_min: float = 75.0
@export var velocity_max: float = 150.0
@export var jump_height: float = -120.0
@export var jump_length_min: float = 1.6
@export var jump_length_max: float = 2.4

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
	jump_length = randf_range(jump_length_min, jump_length_max)
	delay_timer = 0.0
	delay_length = randf_range(jump_length_min, jump_length_max)

func init(direction: float) -> void:
	velocity_rotation = direction
	velocity = Vector2(randf_range(velocity_min, velocity_max), 0.0).rotated(direction)
	real_position = position
	$AnimatedSprite2D.play(Array($AnimatedSprite2D.sprite_frames.get_animation_names()).pick_random())
	jump()

func _process(delta: float) -> void:
	if jumping:
		jump_timer += delta
		jumping = jump_timer < jump_length
		if jump_timer >= jump_length:
			$LandSound.play()

		real_position += velocity * delta
		$Shadow.global_position = real_position
		position = real_position

		var t = min(jump_timer / jump_length, 1.0)
		var y = 4.0 * t * (1.0 - t)
		position.y += y * jump_height
		scale.y = 1.0 + y * 0.5
		scale.x = 1.0 + max(0.0, cos(t * TAU) / 2)
	else:
		scale.x = min(scale.x + delta * 3.0, 1.0) if scale.x < 1.0 else max(scale.x - delta * 3.0, 1.0)
		delay_timer += delta
		if delay_timer >= delay_length:
			jump()

	$Shadow.visible = jumping
	$CollisionShape2D.disabled = jumping
	$AnimatedSprite2D.speed_scale = not jumping

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
