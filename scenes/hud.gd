extends CanvasLayer
signal start_game

var GAME_MODE_TOOLTIPS: Dictionary[GameMode.GameMode, String] = {
	GameMode.GameMode.NORMAL: "Normal",
	GameMode.GameMode.BOSS: "Boss",
	GameMode.GameMode.PARTY: "Random Modifiers",
	GameMode.GameMode.NO_POWERUPS: "No Powerups",
}

var GAME_MODE_ICONS: Dictionary[GameMode.GameMode, Texture] = {
	GameMode.GameMode.NORMAL: preload("res://assets/sprites/normal_gm.png"),
	GameMode.GameMode.BOSS: preload("res://assets/sprites/boss_gm.png"),
	GameMode.GameMode.PARTY: preload("res://assets/sprites/party_gm.png"),
	GameMode.GameMode.NO_POWERUPS: preload("res://assets/sprites/no_powerup_gm.png"),
}

@export var game_mode: GameMode.GameMode = GameMode.GameMode.NORMAL
@export var savefile = "user://save_game.dat"
@export var camera_shake_enabled = true
@export var particles_enabled = true
@export var vignette_enabled = true
@export var slow_down_enabled = false
@export var text_fx_enabled = true
@export var ui_delay_enabled = true
@export var initial_delay_enabled = true
@export var fullscreen = false
@export var paused = false

var music_volume = 1
var sfx_volume = 1
var high_score = 0
var total_score = 0

func _ready() -> void:
	var file = FileAccess.open(savefile, FileAccess.READ)
	if file:
		var config = file.get_var()
		if config.has("music_volume"):          music_volume = config["music_volume"]
		if config.has("sfx_volume"):            sfx_volume = config["sfx_volume"]
		if config.has("high_score"):            high_score = config["high_score"]
		if config.has("total_score"):           total_score = config["total_score"]
		if config.has("camera_shake_enabled"):  camera_shake_enabled = config["camera_shake_enabled"]
		if config.has("particles_enabled"):     particles_enabled = config["particles_enabled"]
		if config.has("vignette_enabled"):      vignette_enabled = config["vignette_enabled"]
		if config.has("slow_down_enabled"):     slow_down_enabled = config["slow_down_enabled"]
		if config.has("text_fx_enabled"):       text_fx_enabled = config["text_fx_enabled"]
		if config.has("ui_delay_enabled"):      ui_delay_enabled = config["ui_delay_enabled"]
		if config.has("initial_delay_enabled"): initial_delay_enabled = config["initial_delay_enabled"]
		if config.has("game_mode"):             game_mode = config["game_mode"]
		if config.has("fullscreen"):            fullscreen = config["fullscreen"]

	var music_bus = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_linear(music_bus, music_volume)
	%OptionsMenu/MusicSlider.value = music_volume
	%OptionsMenu/MusicSlider/Label.text = str("Music: ", round(100 * music_volume), "%")

	var sfx_bus = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_linear(sfx_bus, sfx_volume)
	%OptionsMenu/SoundSlider.value = sfx_volume
	%OptionsMenu/SoundSlider/Label.text = str("SFX: ", round(100 * sfx_volume), "%")

	%OptionsMenu/CameraShake.button_pressed = camera_shake_enabled
	%OptionsMenu/Particles.button_pressed = particles_enabled
	%OptionsMenu/Vignette.button_pressed = vignette_enabled
	%OptionsMenu/SlowDown.button_pressed = slow_down_enabled
	%OptionsMenu/TextFX.button_pressed = text_fx_enabled
	%OptionsMenu/UIDelay.button_pressed = ui_delay_enabled
	%OptionsMenu/InitDelay.button_pressed = initial_delay_enabled
	%OptionsMenu/FullScreen.button_pressed = fullscreen

	%MainMenu/GameModeButton.texture_normal = GAME_MODE_ICONS[game_mode]
	%MainMenu/GameModeButton.tooltip_text = GAME_MODE_TOOLTIPS[game_mode]

	%ScoreLabel.text = str("HS: ", high_score)
	get_tree().set_auto_accept_quit(false)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func quit() -> void:
	var file = FileAccess.open(savefile, FileAccess.WRITE)
	file.store_var({
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"high_score": high_score,
		"total_score": total_score,
		"camera_shake_enabled": camera_shake_enabled,
		"particles_enabled": particles_enabled,
		"vignette_enabled": vignette_enabled,
		"slow_down_enabled": slow_down_enabled,
		"text_fx_enabled": text_fx_enabled,
		"ui_delay_enabled": ui_delay_enabled,
		"initial_delay_enabled": initial_delay_enabled,
		"game_mode": game_mode,
		"fullscreen": fullscreen,
	})
	get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()

func display_powerup_info(attack_timer: float, slow_timer: float, double_timer: float, powerup_increased_rate_timer: float, bouncy_timer: float, slippery_timer: float, confused_timer: float) -> void:
	var text = ""
	if attack_timer > 0.0:
		text = str(text, "ATK ", round(attack_timer * 10.0) / 10.0, "\n")
	if slow_timer > 0.0:
		text = str(text, "SLOW ", round(slow_timer * 10.0) / 10.0, "\n")
	if double_timer > 0.0:
		text = str(text, "2X ", round(double_timer * 10.0) / 10.0, "\n")
	if powerup_increased_rate_timer > 0.0:
		text = str(text, "+POW ", round(powerup_increased_rate_timer * 10.0) / 10.0, "\n")
	if bouncy_timer > 0.0:
		text = str(text, "BOUNCY ", round(bouncy_timer * 10.0) / 10.0, "\n")
	if slippery_timer > 0.0:
		text = str(text, "SLIP ", round(slippery_timer * 10.0) / 10.0, "\n")
	if confused_timer > 0.0:
		text = str(text, "CONF ", round(confused_timer * 10.0) / 10.0, "\n")
	%GameMenu/Powerups.text = text

var modifier_tween
func display_modifier(text: String):
	$PartySound.play()
	%PartyModifier.text = text
	%PartyModifier.modulate.a = 1.0
	if modifier_tween:
		modifier_tween.kill()

	await get_tree().create_timer(1.5).timeout
	modifier_tween = get_tree().create_tween()
	modifier_tween.tween_property(%PartyModifier, "modulate:a", 0.0, 0.5)

func show_message(text: String):
	%Message.text = text
	%Message.show()
	%MessageTimer.start()

func stop_game(message: String):
	if not ui_delay_enabled:
		%GameMenu.hide()
		%Message.text = "Dodge the Wraiths!"
		%Message.show()
		%MainMenu.show()
		return

	%GameMenu.hide()
	show_message(message)
	await %MessageTimer.timeout

	%ScoreLabel.text = str("HS: ", high_score)
	%Message.text = "Dodge the Wraiths!"
	%Message.show()

	await get_tree().create_timer(1.0).timeout
	%MainMenu.show()

func game_over():
	stop_game("Game Over!")

func update_score(score: int):
	%ScoreLabel.text = str(score)
	high_score = max(high_score, score)
	total_score += score

func _on_message_timer_timeout() -> void:
	%Message.hide()

func _on_start_button_pressed() -> void:
	%GameMenu.show()
	%MainMenu.hide()
	%ScoreLabel.text = "0"
	start_game.emit(game_mode)

func _on_quit_button_pressed() -> void:
	quit()

func _on_options_button_pressed() -> void:
	%MainMenu.hide()
	%Message.hide()
	%ScoreLabel.hide()
	%OptionsMenu.show()

func _on_back_button_pressed() -> void:
	%ScoreLabel.show()
	%OptionsMenu.hide()

	if paused:
		%PauseMenu.show()
	else:
		%MainMenu.show()
		%Message.show()

func _on_pause_button_pressed() -> void:
	if not %Message.visible:
		paused = true
		Engine.time_scale = 0
		%PauseMenu.show()
		%GameMenu/PauseButton.hide()

func _on_continue_button_pressed() -> void:
	paused = false
	Engine.time_scale = 1
	%PauseMenu.hide()
	%GameMenu/PauseButton.show()

func _on_quit_button_pressed_paused() -> void:
	paused = false
	Engine.time_scale = 1
	%PauseMenu.hide()
	%GameMenu/PauseButton.show()

	get_parent().quit_game()
	stop_game("Forfeit!")

func _on_options_button_pressed_paused() -> void:
	%ScoreLabel.hide()
	%PauseMenu.hide()
	%OptionsMenu.show()

func _on_skip_button_pressed() -> void:
	get_parent().play_random_song()

func _on_game_mode_button_pressed() -> void:
	match game_mode:
		GameMode.GameMode.NORMAL:      game_mode = GameMode.GameMode.BOSS
		GameMode.GameMode.BOSS:        game_mode = GameMode.GameMode.PARTY
		GameMode.GameMode.PARTY:       game_mode = GameMode.GameMode.NO_POWERUPS
		GameMode.GameMode.NO_POWERUPS: game_mode = GameMode.GameMode.NORMAL
	%MainMenu/GameModeButton.texture_normal = GAME_MODE_ICONS[game_mode]
	%MainMenu/GameModeButton.tooltip_text = GAME_MODE_TOOLTIPS[game_mode]

func _on_music_slider_value_changed(value: float) -> void:
	var music_bus = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_linear(music_bus, value)
	%OptionsMenu/MusicSlider/Label.text = str("Music: ", round(100 * value), "%")
	music_volume = value

func _on_sound_slider_value_changed(value: float) -> void:
	var sfx_bus = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_linear(sfx_bus, value)
	%OptionsMenu/SoundSlider/Label.text = str("SFX: ", round(100 * value), "%")
	sfx_volume = value

func _on_camera_shake_toggled(toggled_on: bool) -> void:
	camera_shake_enabled = toggled_on

func _on_particles_toggled(toggled_on: bool) -> void:
	particles_enabled = toggled_on

func _on_vignette_toggled(toggled_on: bool) -> void:
	vignette_enabled = toggled_on

func _on_slow_down_toggled(toggled_on: bool) -> void:
	slow_down_enabled = toggled_on

func _on_text_fx_toggled(toggled_on: bool) -> void:
	text_fx_enabled = toggled_on

func _on_game_ui_toggled(toggled_on: bool) -> void:
	ui_delay_enabled = toggled_on

func _on_init_delay_toggled(toggled_on: bool) -> void:
	initial_delay_enabled = toggled_on

func _on_full_screen_toggled(toggled_on: bool) -> void:
	fullscreen = toggled_on
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
