extends CharacterBody2D
@export var velocity_min: float = 150.0
@export var velocity_max: float = 250.0
@export var home_percent_min: float = 0.4
@export var home_percent_max: float = 0.6

var player: Area2D
var initial_velocity: Vector2
var home_percent: float = randf_range(home_percent_min, home_percent_max)

func init(direction: float) -> void:
	var vel = Vector2(randf_range(velocity_min, velocity_max), 0.0)
	rotation = direction
	initial_velocity = vel
	velocity = vel.rotated(direction)
	player = get_parent().get_node("Player")
	$AnimatedSprite2D.play("idle")

func _process(delta: float) -> void:
	if player.visible:
		rotation = lerp_angle(rotation, position.angle_to_point(player.position), home_percent * delta)
		velocity = initial_velocity.rotated(rotation)
	position += velocity * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
