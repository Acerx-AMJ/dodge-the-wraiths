extends CharacterBody2D
@export var demon_scene: PackedScene
@export var velocity_min: float = 75.0
@export var velocity_max: float = 150.0
@export var demon_summon_time: float = 3.0

var demon_summon_timer: float = demon_summon_time / 2.0
var initial_velocity: Vector2
var initial_rotation: float
var timer: float = PI

func init(direction: float) -> void:
	var vel = Vector2(randf_range(velocity_min, velocity_max), 0.0)
	rotation = direction
	velocity = vel.rotated(direction)
	initial_velocity = vel
	initial_rotation = direction
	$AnimatedSprite2D.flip_v = (direction >= PI and direction <= 3 * PI / 2)
	$AnimatedSprite2D.play(Array($AnimatedSprite2D.sprite_frames.get_animation_names()).pick_random())

func summon_demon(angle: float) -> void:
	var demon = demon_scene.instantiate()
	demon.position = position
	get_parent().add_child(demon)
	demon.init(angle + randf_range(-PI / 4, PI / 4))

func _process(delta: float) -> void:
	timer += delta
	rotation = initial_rotation + sin(timer * 2.0) * 0.4
	velocity = initial_velocity.rotated(rotation)
	position += velocity * delta

	demon_summon_timer -= delta
	if demon_summon_timer <= 0.0:
		for i in range(3):
			summon_demon(i * TAU / 3)
		demon_summon_timer += demon_summon_time
		var texture = $AnimatedSprite2D.sprite_frames.get_frame_texture($AnimatedSprite2D.animation, $AnimatedSprite2D.get_frame())
		get_parent().spawn_death_particles(texture, position)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
