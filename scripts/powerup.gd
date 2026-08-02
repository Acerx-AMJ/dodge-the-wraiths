extends Area2D
@export var function: String
@export var duration: float

func _on_area_entered(_area: Area2D) -> void:
	get_parent().get_node("PowerupSound").play()
	get_parent().call(function, duration)

	$Sprite2D.hide()
	$CollisionShape2D.set_deferred("disabled", true)
	$Particles.emitting = true
	await $Particles.finished
	queue_free()
