extends Area2D
@export var function: Callable
var alive_time: float = 0.0

func _process(delta: float) -> void:
	alive_time += delta
	var scale_unit = 1.0 + sin(alive_time * 2.0) * 0.075
	scale = Vector2(scale_unit, scale_unit)

func _on_area_entered(_area: Area2D) -> void:
	function.call()
	$Sound.play()
	$Sprite2D.hide()
	$CollisionShape2D.set_deferred("disabled", true)

	if $"../HUD".particles_enabled:
		$Particles.emitting = true
		var wait_time = max($Sound.stream.get_length(), $Particles.lifetime)
		await get_tree().create_timer(wait_time).timeout
	else:
		await $Sound.finished
	queue_free()
