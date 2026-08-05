extends Node
@export var mob_scenes: Array[PackedScene]
@export var boss_scenes: Array[PackedScene]
@export var powerup_scene: PackedScene

@export var mob_spawn_speed: float = 0.5
@export var boss_spawn_speed: float = 12.0
@export var powerup_spawn_speed: float = 7.5
@export var score_speed: float = 1.0

var mob_timer: float = mob_spawn_speed
var boss_timer: float = boss_spawn_speed
var powerup_timer: float = powerup_spawn_speed
var score_timer: float = score_speed
var attack_timer: float = 0
var slow_timer: float = 0

var start_timers: bool = false
var is_playing: bool = false
var is_slowed: bool = false
var score: int = 0

# Name, function
# There must be a function 'NAME', sound effect in res://sounds/'NAME'.wav and sprite in res://art/'NAME'.png
# Not the best way to handle it but it reduces boilerplate
var powerup_types = [
	["powerup_slow", func() -> void:
		is_slowed = true
		slow_timer += 10.0],
	["powerup_shield", func() -> void:
		$Player.powerup_shield()],
	["powerup_score", func() -> void:
		score += 20
		$HUD.update_score(score)],
	["powerup_clear", func() -> void:
		score += get_tree().get_node_count_in_group("mobs") * 3
		$HUD.update_score(score)
		$Camera2D.shake(15.0, 5.0)
		$Vignette.apply(Color.DARK_RED, 1.0, 1.5)

		for enemy in get_tree().get_nodes_in_group("mobs"):
			var sprite = enemy.get_node("AnimatedSprite2D")
			var texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.get_frame())
			spawn_death_particles(texture, enemy.position)
			enemy.queue_free()],
	["powerup_attack", func() -> void:
		$Player.powerup_attack()
		attack_timer += 5.0],
]

func game_over():
	start_timers = false
	is_playing = false
	$HUD.game_over()
	$Music.stop()
	$DeathSound.play()

func new_game():
	is_playing = true
	is_slowed = false
	score = 0
	attack_timer = 0
	slow_timer = 0
	score_timer = score_speed
	powerup_timer = powerup_spawn_speed
	mob_timer = mob_spawn_speed
	boss_timer = boss_spawn_speed

	get_tree().call_group("mobs", "queue_free")
	get_tree().call_group("powerups", "queue_free")

	$Player.start($ViewportSize.size / 2)
	$Music.play()

	$HUD.update_score(score)
	$HUD.show_message("Get Ready...")

	await get_tree().create_timer(2.0).timeout
	start_timers = true

func _process(delta: float) -> void:
	if not is_playing: return
	if attack_timer > 0.0:
		attack_timer = max(0.0, attack_timer - delta)
		if attack_timer == 0.0:
			$Player.powerup_attack_stop()
	if slow_timer > 0.0:
		slow_timer = max(0.0, slow_timer - delta)
		if slow_timer == 0.0:
			is_slowed = false
	$HUD.display_powerup_info(attack_timer, slow_timer)

	if not start_timers: return
	var slowed = delta / 3.0 if is_slowed else delta
	mob_timer -= slowed
	boss_timer -= slowed
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

# [0] - location, [1] - rotation, [2] - flip V
func get_spawn_location() -> Array:
	var size = $ViewportSize.size
	var side = randi() % 4
	if side % 2: # right and left
		return [Vector2(size.x if side == 1 else 0, randf_range(100.0, size.y - 200.0)), PI if side == 1 else TAU, side == 1]
	else: # top and bottom
		return [Vector2(randf_range(100.0, size.x - 200.0), 0 if side == 0 else size.y), PI / 2 if side == 0 else 3 * PI / 2, false]

func spawn_mob() -> void:
	var mob = mob_scenes.pick_random().instantiate()
	var spawn = get_spawn_location()
	mob.position = spawn[0]
	add_child(mob)
	mob.init(spawn[1] + randf_range(-PI / 4, PI / 4), spawn[2])

func spawn_boss() -> void:
	var boss = boss_scenes.pick_random().instantiate()
	var spawn = get_spawn_location()
	boss.position = spawn[0]
	add_child(boss)
	boss.init(spawn[1] + randf_range(-PI / 4, PI / 4), spawn[2])

func spawn_powerup() -> void:
	var powerup_type = powerup_types.pick_random()
	var powerup = powerup_scene.instantiate()
	var texture = load(str("res://art/", powerup_type[0], ".png"))

	powerup.position = Vector2(randf_range(0.0, $ViewportSize.size.x), randf_range(0.0, $ViewportSize.size.y)) # Cheaty
	powerup.function = powerup_type[1]
	powerup.get_node("Sprite2D").texture = texture
	powerup.get_node("Particles").texture = texture
	powerup.get_node("Sound").stream = load(str("res://sounds/", powerup_type[0], ".wav"))
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

func _on_hud_start_game() -> void:
	new_game()
