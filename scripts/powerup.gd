extends Area2D
@export var function: String
@export var duration: float

func _on_area_entered(_area: Area2D) -> void:
	get_parent().call(function, duration)
	$Sound.play()

	$Sprite2D.hide()
	$CollisionShape2D.set_deferred("disabled", true)
	$Particles.emitting = true

	var wait_time = max($Sound.stream.get_length(), $Particles.lifetime)
	await get_tree().create_timer(wait_time).timeout
	queue_free()
