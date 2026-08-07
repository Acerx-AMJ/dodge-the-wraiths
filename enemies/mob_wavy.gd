extends CharacterBody2D
@export var velocity_min: float = 175.0
@export var velocity_max: float = 300.0
@export var turn_speed_min: float = 1.5
@export var turn_speed_max: float = 2.5
@export var turn_amount_min: float = 0.25
@export var turn_amount_max: float = 0.65

var initial_velocity: Vector2
var initial_rotation: float
var turn_speed: float = randf_range(turn_speed_min, turn_speed_max)
var turn_amount: float = randf_range(turn_amount_min, turn_amount_max)
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
	rotation = initial_rotation + sin(timer * turn_speed) * turn_amount
	velocity = initial_velocity.rotated(rotation)
	position += velocity * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
