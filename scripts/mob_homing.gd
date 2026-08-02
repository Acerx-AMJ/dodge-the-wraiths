extends CharacterBody2D
var player
var initial_velocity

func init(direction: float, vel: Vector2) -> void:
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
