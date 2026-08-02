extends Node

@export var mob_scenes: Array[PackedScene]
@export var powerup_scene: PackedScene
@export var min_speed = 150.0
@export var max_speed = 250.0
@export var mob_spawn_speed = 0.5
@export var powerup_spawn_speed = 7.5

@export var score_per_second = 1
@export var score_from_killing_enemy = 3

var shield_timer = 0
var attack_timer = 0
var slow_timer = 0
var score = 0
var is_playing = false

var powerup_types = [{
	"function": "powerup_slow",
	"duration": 10.0,
	"sprite": "res://art/powerup_slow.png"
}, {
	"function": "powerup_shield",
	"duration": 7.5,
	"sprite": "res://art/powerup_shield.png"
}, {
	"function": "powerup_score",
	"duration": 0.0,
	"sprite": "res://art/powerup_score.png"
}, {
	"function": "powerup_clear",
	"duration": 0.0,
	"sprite": "res://art/powerup_clear.png"
}, {
	"function": "powerup_attack",
	"duration": 5.0,
	"sprite": "res://art/powerup_attack.png"
}]

func powerup_slow(duration: float) -> void:
	$MobTimer.wait_time = mob_spawn_speed * 4
	slow_timer += duration

func powerup_shield(duration: float) -> void:
	$Player.powerup_shield()
	shield_timer += duration

func powerup_score(_duration: float) -> void:
	score += 10
	$HUD.update_score(score)

func powerup_clear(_duration: float) -> void:
	score += get_tree().get_node_count_in_group("mobs") * score_from_killing_enemy
	$HUD.update_score(score)
	get_tree().call_group("mobs", "queue_free")

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
	shield_timer = 0
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
	shield_timer = update_timer(shield_timer, delta, $Player.powerup_shield_stop)
	slow_timer   = update_timer(slow_timer,   delta, func(): $MobTimer.wait_time = mob_spawn_speed)
	$HUD.display_powerup_info(attack_timer, shield_timer, slow_timer)

func _on_player_enemy_killed() -> void:
	score += score_from_killing_enemy
	$HUD.update_score(score)

func _on_player_hit() -> void:
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

	powerup.position = Vector2(randf_range(0.0, $ColorRect.size.x), randf_range(0.0, $ColorRect.size.y)) # Cheaty
	powerup.function = powerup_type["function"]
	powerup.duration = powerup_type["duration"]
	powerup.get_node("Sprite2D").texture = texture
	powerup.get_node("Particles").texture = texture
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
