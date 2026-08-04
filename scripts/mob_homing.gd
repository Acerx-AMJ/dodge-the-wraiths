extends CharacterBody2D
@export var velocity_min: float = 150.0
@export var velocity_max: float = 250.0

var player: Area2D
var initial_velocity: Vector2

func init(direction: float, _flip_v: bool) -> void:
	var vel = Vector2(randf_range(velocity_min, velocity_max), 0.0)
	rotation = direction
	initial_velocity = vel
	velocity = vel.rotated(direction)
	player = get_parent().get_node("Player")
	$AnimatedSprite2D.play("idle")

func _process(delta: float) -> void:
	if player.visible:
		rotation = lerp_angle(rotation, position.angle_to_point(player.position), 0.5 * delta)
		velocity = initial_velocity.rotated(rotation)
	position += velocity * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
