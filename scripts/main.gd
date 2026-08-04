extends Node
@export var mob_scenes: Array[PackedScene]
@export var boss_scenes: Array[PackedScene]
@export var powerup_scene: PackedScene

@export var mob_spawn_speed_initial: float = 0.5
@export var boss_spawn_speed_initial: float = 15.0
@export var powerup_spawn_speed_initial: float = 7.5
@export var score_speed: float = 1.0

var mob_spawn_speed: float = mob_spawn_speed_initial
var boss_spawn_speed: float = boss_spawn_speed_initial
var powerup_spawn_speed: float = powerup_spawn_speed_initial

var mob_timer: float = mob_spawn_speed_initial
var boss_timer: float = boss_spawn_speed_initial
var powerup_timer: float = powerup_spawn_speed_initial
var score_timer: float = score_speed
var attack_timer: float = 0
var slow_timer: float = 0

var start_timers: bool = false
var is_playing: bool = false
var score: int = 0

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
	mob_spawn_speed = mob_spawn_speed_initial * 3
	boss_spawn_speed = boss_spawn_speed_initial * 3
	slow_timer += duration
	$Vignette.apply(Color.WEB_GRAY, 0.5, slow_timer)

func powerup_shield(_duration: float) -> void:
	$Player.powerup_shield()

func powerup_score(_duration: float) -> void:
	score += 20
	$HUD.update_score(score)

func powerup_clear(_duration: float) -> void:
	score += get_tree().get_node_count_in_group("mobs") * 3
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
	start_timers = false
	is_playing = false
	$HUD.game_over()
	$Music.stop()
	$DeathSound.play()

func new_game():
	is_playing = true
	score = 0
	attack_timer = 0
	slow_timer = 0
	score_timer = score_speed
	powerup_timer = powerup_spawn_speed_initial
	mob_timer = mob_spawn_speed_initial
	boss_timer = boss_spawn_speed_initial

	get_tree().call_group("mobs", "queue_free")
	get_tree().call_group("powerups", "queue_free")

	$Player.start($StartPosition.position)
	$StartTimer.start()
	$Music.play()

	$HUD.update_score(score)
	$HUD.show_message("Get Ready...")

func _process(delta: float) -> void:
	if not is_playing: return
	if attack_timer > 0.0:
		attack_timer = max(0.0, attack_timer - delta)
		if attack_timer == 0.0:
			$Player.powerup_attack_stop()
	if slow_timer > 0.0:
		slow_timer = max(0.0, slow_timer - delta)
		if slow_timer == 0.0:
			mob_spawn_speed = mob_spawn_speed_initial
			boss_spawn_speed = boss_spawn_speed_initial
	$HUD.display_powerup_info(attack_timer, slow_timer)

	if not start_timers: return
	mob_timer -= delta
	boss_timer -= delta
	powerup_timer -= delta
	score_timer -= delta
	
	if mob_timer <= 0.0:
		spawn_mob()
		mob_timer += mob_spawn_speed * randf_range(0.8, 1.2)
	if boss_timer <= 0.0:
		spawn_boss()
		boss_timer += boss_spawn_speed * randf_range(0.8, 1.2)
	if powerup_timer <= 0.0:
		spawn_powerup()
		powerup_timer += powerup_spawn_speed * randf_range(0.8, 1.2)
	if score_timer <= 0.0:
		score += 1
		$HUD.update_score(score)
		score_timer += score_speed

func spawn_death_particles(texture: Texture, position: Vector2) -> void:
	if not $HUD.particles_enabled: return
	var particles: GPUParticles2D = $DeathParticles.duplicate()
	particles.texture = texture
	particles.position = position
	add_child(particles)

	particles.emitting = true
	await particles.finished
	particles.queue_free()

func spawn_mob() -> void:
	var mob = mob_scenes.pick_random().instantiate()
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()
	mob.position = mob_spawn_location.position

	add_child(mob)
	mob.init(mob_spawn_location.rotation + randf_range(PI / 4, 3*PI / 4))

func spawn_boss() -> void:
	var boss = boss_scenes.pick_random().instantiate()
	var boss_spawn_location = $MobPath/MobSpawnLocation
	boss_spawn_location.progress_ratio = randf()
	boss.position = boss_spawn_location.position

	add_child(boss)
	boss.init(boss_spawn_location.rotation + randf_range(PI / 4, 3*PI / 4))

func spawn_powerup() -> void:
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

func _on_player_enemy_killed(enemy: Node2D) -> void:
	var sounds = $KillSounds.get_children()
	sounds[randi() % sounds.size()].play()
	score += 3
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

func _on_start_timer_timeout() -> void:
	start_timers = true

func _on_hud_start_game() -> void:
	new_game()
