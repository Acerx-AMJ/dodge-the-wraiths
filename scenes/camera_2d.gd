extends Camera2D

var shake_fade: float = 0.0
var shake_strength: float = 0.0
var original_offset: Vector2 = offset

func shake(strength: float, fade: float):
	shake_strength = strength
	shake_fade = fade

func _process(delta: float) -> void:
	if shake_strength <= 0 or not $"../HUD".camera_shake_enabled:
		shake_strength = 0
		return
	shake_strength = lerp(shake_strength, 0.0, shake_fade * delta)
	offset = original_offset + Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
