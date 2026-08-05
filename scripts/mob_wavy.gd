extends CharacterBody2D
@export var velocity_min: float = 175.0
@export var velocity_max: float = 300.0

var initial_velocity: Vector2
var initial_rotation: float
var timer: float = PI

func init(direction: float) -> void:
	var vel = Vector2(randf_range(velocity_min, velocity_max), 0.0)
	rotation = direction
	velocity = vel.rotated(direction)
	initial_velocity = vel
	initial_rotation = direction
	$AnimatedSprite2D.flip_v = (rotation > PI / 2 and rotation < 3 * PI / 2)
	$AnimatedSprite2D.play(Array($AnimatedSprite2D.sprite_frames.get_animation_names()).pick_random())

func _process(delta: float) -> void:
	timer += delta
	rotation = initial_rotation + sin(timer * 2.0) * 0.4
	velocity = initial_velocity.rotated(rotation)
	position += velocity * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
