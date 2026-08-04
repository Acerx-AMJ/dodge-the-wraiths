extends Node

@export var mob_scenes: Array[PackedScene]
@export var powerup_scene: PackedScene
@export var min_speed = 150.0
@export var max_speed = 250.0
@export var mob_spawn_speed = 0.5
@export var powerup_spawn_speed = 7.5

@export var score_per_second = 1
@export var score_from_killing_enemy = 3

var attack_timer = 0
var slow_timer = 0
var score = 0
var is_playing = false

var powerup_types = [{
	"function": "powerup_slow",
	"duration": 10.0,
	"sprite": "res://art/powerup_slow.png",
	"sound": "res://art/slow.wav"
}, {
	"function": "powerup_shield",
	"duration": 0.0,
	"sprite": "res://art/powerup_shield.png",
	"sound": "res://art/shield.wav"
}, {
	"function": "powerup_score",
	"duration": 0.0,
	"sprite": "res://art/powerup_score.png",
	"sound": "res://art/score.wav"
}, {
	"function": "powerup_clear",
	"duration": 0.0,
	"sprite": "res://art/powerup_clear.png",
	"sound": "res://art/clear.wav"
}, {
	"function": "powerup_attack",
	"duration": 5.0,
	"sprite": "res://art/powerup_attack.png",
	"sound": "res://art/attack.wav"
}]

func powerup_slow(duration: float) -> void:
	$MobTimer.wait_time = mob_spawn_speed * 4
	slow_timer += duration
	$Vignette.apply(Color.WEB_GRAY, 0.5, slow_timer)

func powerup_shield(_duration: float) -> void:
	$Player.powerup_shield()

func powerup_score(_duration: float) -> void:
	score += 10
	$HUD.update_score(score)

func powerup_clear(_duration: float) -> void:
	score += get_tree().get_node_count_in_group("mobs") * score_from_killing_enemy
	$HUD.update_score(score)
	$Camera2D.shake(15.0, 5.0)
	$Vignette.apply(Color.DARK_RED, 1.0, 1.5)

	for enemy in get_tree().get_nodes_in_group("mobs"):
		var sprite = enemy.get_node("AnimatedSprite2D")
		var texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.get_frame())
		spawn_death_particles(texture, enemy.position)
		enemy.queue_free()

func powerup_attack(duration: float) -> void:
	$Player.powerup_attack()
	attack_timer += duration

func game_over():
	is_playing = false
	$ScoreTimer.stop()
	$PowerupTimer.stop()
	$MobTimer.stop()
	$HUD.game_over()
	$Music.stop()
	$DeathSound.play()

func new_game():
	is_playing = true
	score = 0
	attack_timer = 0
	slow_timer = 0
	$PowerupTimer.wait_time = powerup_spawn_speed
	$MobTimer.wait_time = mob_spawn_speed

	get_tree().call_group("mobs", "queue_free")
	get_tree().call_group("powerups", "queue_free")

	$Player.start($StartPosition.position)
	$StartTimer.start()
	$Music.play()

	$HUD.update_score(score)
	$HUD.show_message("Get Ready")

func update_timer(timer: float, delta: float, f: Callable) -> float:
	if timer > 0:
		timer = max(0.0, timer - delta)
		if timer == 0:
			f.call()
	return timer

func _process(delta: float) -> void:
	if not is_playing: return
	attack_timer = update_timer(attack_timer, delta, $Player.powerup_attack_stop)
	slow_timer   = update_timer(slow_timer,   delta, func(): $MobTimer.wait_time = mob_spawn_speed)
	$HUD.display_powerup_info(attack_timer, slow_timer)

func spawn_death_particles(texture: Texture, position: Vector2) -> void:
	if not $HUD.particles_enabled: return
	var particles: GPUParticles2D = $DeathParticles.duplicate()
	particles.texture = texture
	particles.position = position
	add_child(particles)

	particles.emitting = true
	await particles.finished
	particles.queue_free()

func _on_player_enemy_killed(enemy: Node2D) -> void:
	var sounds = $KillSounds.get_children()
	sounds[randi() % sounds.size()].play()
	score += score_from_killing_enemy
	$HUD.update_score(score)
	$Camera2D.shake(10.0, 7.5)
	$Vignette.apply(Color.DARK_RED, 0.5, 1.0)
	
	var sprite = enemy.get_node("AnimatedSprite2D")
	var texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.get_frame())
	spawn_death_particles(texture, enemy.position)


func _on_player_hit() -> void:
	$Camera2D.shake(15.0, 5.0)
	$Vignette.apply(Color.DARK_RED, 1.0, 3.0)
	spawn_death_particles($Player/Sprite.texture, $Player.position)
	game_over()

func _on_mob_timer_timeout() -> void:
	var mob = mob_scenes.pick_random().instantiate()
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()
	mob.position = mob_spawn_location.position

	var velocity = Vector2(randf_range(min_speed, max_speed), 0.0)
	var direction = mob_spawn_location.rotation + PI / 2 # face inwards
	direction += randf_range(-PI / 4, PI / 4)

	add_child(mob)
	mob.init(direction, velocity)

func _on_powerup_timer_timeout() -> void:
	var powerup_type = powerup_types.pick_random()
	var powerup = powerup_scene.instantiate()
	var texture = load(powerup_type["sprite"])

	powerup.position = Vector2(randf_range(0.0, $ViewportSize.size.x), randf_range(0.0, $ViewportSize.size.y)) # Cheaty
	powerup.function = powerup_type["function"]
	powerup.duration = powerup_type["duration"]
	powerup.get_node("Sprite2D").texture = texture
	powerup.get_node("Particles").texture = texture
	powerup.get_node("Sound").stream = load(powerup_type["sound"])
	add_child(powerup)
	$PowerupTimer.wait_time = powerup_spawn_speed * randf_range(0.6, 1.4)

func _on_score_timer_timeout() -> void:
	score += score_per_second
	$HUD.update_score(score)

func _on_start_timer_timeout() -> void:
	$PowerupTimer.start()
	$MobTimer.start()
	$ScoreTimer.start()

func _on_hud_start_game() -> void:
	new_game()
