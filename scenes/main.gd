extends Node
@export var mob_scenes: Array[PackedScene]
@export var boss_scenes: Array[PackedScene]
@export var powerup_scene: PackedScene

@export var mob_spawn_speed: float = 0.5
@export var boss_spawn_speed: float = 12.0
@export var boss_game_mode_spawn_speed: float = 2.0
@export var powerup_spawn_speed: float = 7.5
@export var score_speed: float = 1.0
@export var party_modifier_speed: float = 3.0

var mob_timer: float = mob_spawn_speed
var boss_timer: float = boss_spawn_speed
var powerup_timer: float = powerup_spawn_speed
var score_timer: float = score_speed
var party_modifier_timer: float = party_modifier_speed
var attack_timer: float = 0.0
var slow_timer: float = 0.0
var double_timer: float = 0.0
var powerup_increased_rate_timer: float = 0.0

var can_spawn_mobs: bool = true
var can_spawn_bosses: bool = true
var can_spawn_powerups: bool = true

var start_timers: bool = false
var is_playing: bool = false
var is_slowed: bool = false
var is_powerup_rate_increased: bool = false
var is_score_doubled: bool = false
var current_game_mode: GameMode.GameMode
var score: int = 0

var music_pool: Array[Node]
var current_music: AudioStreamPlayer2D

func play_random_song() -> void:
	if current_music and current_music.playing:
		current_music.stop()

	var picked: AudioStreamPlayer2D = music_pool.pick_random()
	while music_pool.size() > 1 and picked == current_music:
		picked = music_pool.pick_random()

	current_music = picked
	current_music.play()
	current_music.finished.connect(func():
		await get_tree().create_timer(randf_range(1.0, 6.0)).timeout
		play_random_song())

func _ready() -> void:
	music_pool = $Music.get_children()
	play_random_song()

# Name, function
# There must be a function 'NAME', sound effect in res://sounds/'NAME'.wav and sprite in res://art/'NAME'.png
# Not the best way to handle it but it reduces boilerplate
var powerup_types = [
	["powerup_slow", func(_powerup: Area2D) -> void:
		is_slowed = true
		slow_timer += 10.0],
	["powerup_shield", func(_powerup: Area2D) -> void:
		$Player.powerup_shield()],
	["powerup_score", func(powerup: Area2D) -> void:
		add_score(20)
		spawn_text_fx(powerup.position, Color.YELLOW, 20)],
	["powerup_clear", func(_powerup: Area2D) -> void:
		$Camera2D.shake(15.0, 5.0)
		$Vignette.apply(Color.DARK_RED, 1.0, 1.5)
		time_scale(0.2, 0.3)

		for enemy in get_tree().get_nodes_in_group("mobs"):
			kill_enemy(enemy)],
	["powerup_attack", func(_powerup: Area2D) -> void:
		$Player.powerup_attack()
		attack_timer += 5.0],
	["powerup_double", func(_powerup: Area2D) -> void:
		is_score_doubled = true
		double_timer += 10.0]]

var party_modifiers: Array[Callable] = [
	func() -> void:
		$HUD.display_modifier("+Powerups")
		var powerup_count = randi_range(1, 4)
		for i in range(powerup_count):
			spawn_powerup(),
	func() -> void:
		$HUD.display_modifier("Powerup Exchange")
		var powerup_reward = randi_range(15, 30)
		add_score(get_tree().get_node_count_in_group("powerups") * powerup_reward)
		$Vignette.apply(Color.YELLOW, 1.0, 1.5)

		for powerup in get_tree().get_nodes_in_group("powerups"):
			spawn_text_fx(powerup.position, Color.YELLOW, powerup_reward)
			powerup.queue_free(),
	func() -> void:
		$HUD.display_modifier("Random Powerup")
		powerup_types.pick_random()[1].call($Player),
	func() -> void:
		$HUD.display_modifier("+Powerup Rate")
		is_powerup_rate_increased = true
		powerup_increased_rate_timer += 10.0,
	func() -> void:
		$HUD.display_modifier("+Enemies")
		var enemy_count = randi_range(3, 7)
		for i in range(enemy_count):
			spawn_mob(),
	func() -> void:
		$HUD.display_modifier("-Enemies")
		var enemy_count = randi_range(2, 5)
		while get_tree().get_node_count_in_group("mobs") > 0 and enemy_count > 0:
			var enemy = get_tree().get_nodes_in_group("mobs").pick_random()
			enemy.remove_from_group("mobs")
			kill_enemy(enemy)
			enemy_count -= 1,
	func() -> void:
		$HUD.display_modifier("+Boss")
		spawn_boss(),
	func() -> void:
		$HUD.display_modifier("+Enemy Type")
		var mob_scene = mob_scenes.pick_random()
		var mob_count = randi_range(3, 7)

		for i in range(mob_count):
			var mob = mob_scene.instantiate()
			var spawn = get_spawn_location()
			mob.position = spawn[0]
			mob.scale *= randf_range(0.85, 1.15)
			add_child(mob)
			mob.init(spawn[1] + randf_range(-PI / 4, PI / 4)),
	func() -> void:
		$HUD.display_modifier("Teleport")
		$Player.invincibility_timer = $Player.invincibility_duration
		$Player.invincible = true
		$Player.position = Vector2(randf_range(0.0, $ViewportSize.size.x), randf_range(0.0, $ViewportSize.size.y))]

func quit_game():
	$Player.invincible = false
	$Player.toggle_visibility(false)
	$Player/CollisionShape2D.disabled = true
	start_timers = false
	is_playing = false

func game_over():
	start_timers = false
	is_playing = false
	$HUD.game_over()
	$DeathSound.play()

func new_game(game_mode: GameMode.GameMode):
	is_playing = true
	is_slowed = false
	is_score_doubled = false
	is_powerup_rate_increased = false
	score = 0
	attack_timer = 0.0
	slow_timer = 0.0
	double_timer = 0.0
	powerup_increased_rate_timer = 0.0
	score_timer = score_speed
	powerup_timer = powerup_spawn_speed
	mob_timer = mob_spawn_speed
	boss_timer = boss_spawn_speed
	party_modifier_timer = party_modifier_speed
	current_game_mode = game_mode

	can_spawn_mobs = (game_mode != GameMode.GameMode.BOSS)
	can_spawn_bosses = true
	can_spawn_powerups = (game_mode != GameMode.GameMode.NO_POWERUPS)

	for mob in get_tree().get_nodes_in_group("mobs"):
		mob.remove_from_group("mobs")
		mob.queue_free()
	for pup in get_tree().get_nodes_in_group("powerups"):
		pup.remove_from_group("powerups")
		pup.queue_free()
	$Player.start($ViewportSize.size / 2)
	$HUD.update_score(score)

	if game_mode == GameMode.GameMode.BOSS:
		boss_timer = boss_game_mode_spawn_speed
	elif game_mode == GameMode.GameMode.PARTY:
		party_modifiers.pick_random().call()

	if not $HUD.initial_delay_enabled:
		$HUD/Message.hide()
	else:
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
	if double_timer > 0.0:
		double_timer = max(0.0, double_timer - delta)
		if double_timer == 0.0:
			is_score_doubled = false
	if powerup_increased_rate_timer > 0.0:
		powerup_increased_rate_timer = max(0.0, powerup_increased_rate_timer - delta)
		if powerup_increased_rate_timer == 0.0:
			is_powerup_rate_increased = false
	$HUD.display_powerup_info(attack_timer, slow_timer, double_timer, powerup_increased_rate_timer)

	if not start_timers: return
	var slowed = delta / 3.0 if is_slowed else delta
	mob_timer -= slowed
	boss_timer -= slowed
	powerup_timer -= delta * 3.0 if is_powerup_rate_increased else delta
	score_timer -= delta
	party_modifier_timer -= delta

	if mob_timer <= 0.0 and can_spawn_mobs:
		spawn_mob()
		mob_timer += mob_spawn_speed * randf_range(0.8, 1.2)
	if boss_timer <= 0.0 and can_spawn_bosses:
		spawn_boss()
		var spawn_speed = boss_game_mode_spawn_speed if current_game_mode == GameMode.GameMode.BOSS else boss_spawn_speed
		boss_timer += spawn_speed * randf_range(0.8, 1.2)
	if powerup_timer <= 0.0 and can_spawn_powerups:
		spawn_powerup()
		powerup_timer += powerup_spawn_speed * randf_range(0.8, 1.2)
	if score_timer <= 0.0:
		add_score(1)
		score_timer += score_speed
	if party_modifier_timer <= 0.0 and current_game_mode == GameMode.GameMode.PARTY:
		party_modifiers.pick_random().call()
		party_modifier_timer += party_modifier_speed * randf_range(0.8, 1.2)

func add_score(score_to_add: int) -> void:
	score += score_to_add * 2 if is_score_doubled else score_to_add
	$HUD.update_score(score)

var time_scale_tween
func time_scale(strength: float, length: float):
	if not $HUD.slow_down_enabled: return
	if time_scale_tween:
		time_scale_tween.kill()

	Engine.time_scale = strength
	time_scale_tween = get_tree().create_tween()
	time_scale_tween.tween_property(Engine, "time_scale", 1.0, length)

func spawn_text_fx(position: Vector2, color: Color, amount: int) -> void:
	if not $HUD.text_fx_enabled: return
	var text_fx = load("res://scenes/text_fx.tscn").instantiate()
	text_fx.init(position, Vector2(randf_range(-100.0, 100.0), randf_range(-100.0, -10.0)), randf_range(0.6, 0.9), randf_range(0.3, 0.5))
	text_fx.get_node("Label").modulate = color
	text_fx.get_node("Label").text = str("+", amount * 2 if is_score_doubled else amount)
	add_child(text_fx)

func spawn_death_particles(texture: Texture, position: Vector2) -> void:
	if not $HUD.particles_enabled: return
	var particles: GPUParticles2D = $DeathParticles.duplicate()
	particles.texture = texture
	particles.position = position
	add_child(particles)

	particles.emitting = true
	await particles.finished
	particles.queue_free()

# [0] - location, [1] - rotation
func get_spawn_location() -> Array:
	var size = $ViewportSize.size
	var side = randi() % 4
	if side % 2: # right and left
		return [Vector2(size.x if side == 1 else 0, randf_range(100.0, size.y - 200.0)), PI if side == 1 else TAU]
	else: # top and bottom
		return [Vector2(randf_range(100.0, size.x - 200.0), 0 if side == 0 else size.y), PI / 2 if side == 0 else 3 * PI / 2]

func spawn_mob() -> void:
	var mob = mob_scenes.pick_random().instantiate()
	var spawn = get_spawn_location()
	mob.position = spawn[0]
	mob.scale *= randf_range(0.85, 1.15)
	add_child(mob)
	mob.init(spawn[1] + randf_range(-PI / 4, PI / 4))

func spawn_boss() -> void:
	var boss = boss_scenes.pick_random().instantiate()
	var spawn = get_spawn_location()
	boss.position = spawn[0]
	boss.scale *= randf_range(0.85, 1.15)
	add_child(boss)
	boss.init(spawn[1] + randf_range(-PI / 4, PI / 4))

func spawn_powerup() -> void:
	var powerup_type = powerup_types.pick_random()
	var powerup = powerup_scene.instantiate()
	var texture = load(str("res://assets/sprites/", powerup_type[0], ".png"))

	powerup.position = Vector2(randf_range(0.0, $ViewportSize.size.x), randf_range(0.0, $ViewportSize.size.y)) # Cheaty
	powerup.function = powerup_type[1]
	powerup.get_node("Sprite2D").texture = texture
	powerup.get_node("Particles").texture = texture
	powerup.get_node("Sound").stream = load(str("res://assets/sounds/", powerup_type[0], ".wav"))
	add_child(powerup)
	$PowerupSpawnSound.play()

func kill_enemy(enemy: Node2D) -> void:
	var sprite = enemy.get_node("AnimatedSprite2D")
	var texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.get_frame())
	spawn_death_particles(texture, enemy.position)

	var is_boss = enemy.is_in_group("boss")
	var color = Color.YELLOW if is_boss else Color.WHITE
	var display_score = 10 if is_boss else 3
	spawn_text_fx(enemy.position, color, display_score)
	add_score(display_score)
	enemy.queue_free()

func _on_player_enemy_killed(enemy: Node2D, is_boss: bool) -> void:
	var sounds = $KillSounds.get_children()
	sounds[randi() % sounds.size()].play()
	$Camera2D.shake(10.0, 7.5)
	$Vignette.apply(Color.DARK_RED, 0.5, 1.0)
	kill_enemy(enemy)
	time_scale(0.2, 0.3 if is_boss else 0.2)

func _on_player_hit() -> void:
	$Camera2D.shake(15.0, 5.0)
	$Vignette.apply(Color.DARK_RED, 1.0, 3.0)
	spawn_death_particles($Player/Sprite.texture, $Player.position)
	game_over()

func _on_hud_start_game(game_mode: GameMode.GameMode) -> void:
	new_game(game_mode)
