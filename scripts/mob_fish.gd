extends CharacterBody2D
@export var velocity_min: float = 150.0
@export var velocity_max: float = 250.0
@export var slow_down_speed_min: float = 0.7
@export var slow_down_speed_max: float = 1.3
@export var dash_zone: float = 15.0

var initial_velocity: Vector2
var slow_down_speed: float = randf_range(slow_down_speed_min, slow_down_speed_max)

func init(direction: float) -> void:
	rotation = direction
	initial_velocity = Vector2(randf_range(velocity_min, velocity_max), 0.0).rotated(direction)
	velocity = Vector2(0, 0)
	$AnimatedSprite2D.flip_v = (rotation > PI / 2 and rotation < 3 * PI / 2)
	$AnimatedSprite2D.play(Array($AnimatedSprite2D.sprite_frames.get_animation_names()).pick_random())

func _process(delta: float) -> void:
	if abs(velocity.x) < dash_zone and abs(velocity.y) < dash_zone:
		velocity = initial_velocity
	position += velocity * delta
	velocity *= 1.0 - delta * slow_down_speed
	$AnimatedSprite2D.speed_scale = velocity.length() / velocity_max

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
