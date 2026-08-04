extends CanvasLayer
signal start_game

@export var savefile = "user://save_game.dat"
@export var camera_shake_enabled = true

var music_volume = 1
var sfx_volume = 1
var high_score = 0
var total_score = 0

func _ready() -> void:
	var file = FileAccess.open(savefile, FileAccess.READ)
	if file:
		var config = file.get_var()
		music_volume = config["music_volume"] if config.has("music_volume") else 1
		sfx_volume = config["sfx_volume"] if config.has("sfx_volume") else 1
		high_score = config["high_score"] if config.has("high_score") else 0
		total_score = config["total_score"] if config.has("total_score") else 0
		camera_shake_enabled = config["camera_shake_enabled"] if config.has("camera_shake_enabled") else true

	var music_bus = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_linear(music_bus, music_volume)
	$Options/MusicSlider.value = music_volume
	$Options/MusicSlider/Label.text = str("Music: ", round(100 * music_volume), "%")

	var sfx_bus = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_linear(sfx_bus, sfx_volume)
	$Options/SoundSlider.value = sfx_volume
	$Options/SoundSlider/Label.text = str("SFX: ", round(100 * sfx_volume), "%")

	$Options/CameraShake.button_pressed = camera_shake_enabled
	$ScoreLabel.text = str("HS: ", high_score)
	get_tree().set_auto_accept_quit(false)

func quit() -> void:
	var file = FileAccess.open(savefile, FileAccess.WRITE)
	file.store_var({
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"high_score": high_score,
		"total_score": total_score,
		"camera_shake_enabled": camera_shake_enabled,
	})
	get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()

func display_powerup_info(attack_timer: float, slow_timer: float) -> void:
	var text = ""
	if attack_timer > 0:
		text = str(text, "ATK ", round(attack_timer * 10.0) / 10.0, "\n")
	if slow_timer > 0:
		text = str(text, "SLW ", round(slow_timer * 10.0) / 10.0, "\n")
	$Powerups.text = text

func show_message(text: String):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()

func game_over():
	$Powerups.hide()
	show_message("Game Over!")
	await $MessageTimer.timeout

	$ScoreLabel.text = str("HS: ", high_score)
	$Message.text = "Dodge the Wraiths!"
	$Message.show()

	await get_tree().create_timer(1.0).timeout
	$MainMenu.show()

func update_score(score: int):
	$ScoreLabel.text = str(score)
	high_score = max(high_score, score)
	total_score += score

func _on_message_timer_timeout() -> void:
	$Message.hide()

func _on_start_button_pressed() -> void:
	$MainMenu.hide()
	$Powerups.show()
	$ScoreLabel.text = "0"
	start_game.emit()

func _on_quit_button_pressed() -> void:
	quit()

func _on_options_button_pressed() -> void:
	$MainMenu.hide()
	$Message.hide()
	$ScoreLabel.hide()
	$Options.show()

func _on_back_button_pressed() -> void:
	$MainMenu.show()
	$Message.show()
	$ScoreLabel.show()
	$Options.hide()

func _on_music_slider_value_changed(value: float) -> void:
	var music_bus = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_linear(music_bus, value)
	$Options/MusicSlider/Label.text = str("Music: ", round(100 * value), "%")
	music_volume = value

func _on_sound_slider_value_changed(value: float) -> void:
	var sfx_bus = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_linear(sfx_bus, value)
	$Options/SoundSlider/Label.text = str("SFX: ", round(100 * value), "%")
	sfx_volume = value

func _on_camera_shake_toggled(toggled_on: bool) -> void:
	camera_shake_enabled = toggled_on
