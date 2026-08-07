extends Node
var velocity: Vector2
var alive_timer: float
var fade_timer: float
var total_fade_time: float

func init(position: Vector2, vel: Vector2, alive_time: float, fade_time: float):
	$Label.position = position
	velocity = vel
	alive_timer = alive_time
	fade_timer = fade_time
	total_fade_time = fade_time

func _process(delta: float) -> void:
	$Label.position += velocity * delta
	velocity += Vector2(0.0, 98.0 * delta)
	velocity.x *= 1.0 - delta

	alive_timer -= delta
	if alive_timer <= 0.0:
		fade_timer -= delta
		$Label.modulate.a = max(0.0, fade_timer / total_fade_time)
		if fade_timer <= 0.0:
			queue_free()
