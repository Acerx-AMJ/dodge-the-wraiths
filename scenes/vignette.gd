extends TextureRect

var color: Color = Color.BLACK
var alpha: float = 0.0
var fade_time: float = 0.0
var fade_timer: float = 0.0

func apply(vignette_color: Color, vignette_alpha: float, vignette_fade_time: float):
	color = vignette_color
	alpha = vignette_alpha
	fade_time = vignette_fade_time
	fade_timer = vignette_fade_time

func _process(delta: float) -> void:
	if fade_timer <= 0 or not $"../HUD".vignette_enabled:
		fade_timer = 0.0
		modulate.a = 0.0
		return
	fade_timer -= delta
	modulate = color
	modulate.a = alpha * (fade_timer / fade_time)
