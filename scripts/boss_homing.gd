extends CharacterBody2D
@export var velocity_min: float = 400.0
@export var velocity_max: float = 600.0
@export var slow_down_speed: float = 2.5
@export var dash_zone: float = 25.0

var initial_direction: float
var initial_velocity: Vector2
var flip: bool = false

func init(direction: float, flip_v: bool) -> void:
	rotation = direction
	initial_direction = direction
	initial_velocity = Vector2(randf_range(velocity_min, velocity_max), 0.0).rotated(direction)
	velocity = Vector2(0, 0)
	$AnimatedSprite2D.flip_v = flip_v
	$AnimatedSprite2D.play(Array($AnimatedSprite2D.sprite_frames.get_animation_names()).pick_random())

func _process(delta: float) -> void:
	if abs(velocity.x) < dash_zone and abs(velocity.y) < dash_zone:
		var direction = PI / 8 if flip else -PI / 8
		rotation = initial_direction + direction
		velocity = initial_velocity.rotated(direction)
		flip = not flip
		$DashSound.play()

	position += velocity * delta
	velocity *= 1.0 - delta * slow_down_speed
	$AnimatedSprite2D.speed_scale = velocity.length() / 250

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
