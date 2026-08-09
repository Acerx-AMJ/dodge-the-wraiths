extends Area2D
signal hit
signal enemy_killed

@export var speed: float = 300.0
@export var acceleration: float = 2500.0
@export var deceleration: float = 4000.0
@export var invincibility_duration: float = 1.5
@export var bounce_coefficient: float = 2.0

var invincible: bool = false
var shielded: bool = false
var attack_mode: bool = false
var slippery: bool = false
var bouncy: bool = false
var confused: bool = false
var invincibility_timer: float = invincibility_duration
var velocity: Vector2 = Vector2.ZERO

var shadows: Array[Sprite2D]
var shadow_count: int = 3

func powerup_shield() -> void:
	shielded = true
	$ShieldSprite.show()

func powerup_shield_stop() -> void:
	invincible = true
	shielded = false
	$ShieldSprite.hide()

func powerup_attack() -> void:
	attack_mode = true
	$AttackSprite.show()

func powerup_attack_stop() -> void:
	invincible = true
	attack_mode = false
	$AttackSprite.hide()

func toggle_visibility(should_be_visible: bool) -> void:
	visible = should_be_visible
	for shadow in shadows:
		shadow.visible = should_be_visible

func start(pos: Vector2) -> void:
	position = pos
	for shadow in shadows:
		shadow.position = pos
	toggle_visibility(true)

	powerup_shield_stop()
	powerup_attack_stop()
	$CollisionShape2D.disabled = false
	invincible = false
	slippery = false
	bouncy = false
	confused = false
	velocity = Vector2()
	invincibility_timer = invincibility_duration

func _ready() -> void:
	var shadow_alpha_unit = 1.0 / (shadow_count + 1.0)
	for i in range(shadow_count):
		var shadow = Sprite2D.new()
		shadow.position = $Sprite.position
		shadow.texture = $Sprite.texture
		shadow.scale = $Sprite.scale - Vector2((i + 1.0) * 0.1, (i + 1.0) * 0.1)
		shadow.modulate.a = 1.0 - (i + 1.0) * shadow_alpha_unit - shadow_alpha_unit * 0.5
		shadow.hide()

		$Shadows.add_child(shadow)
		shadows.push_back(shadow)

func _process(delta: float) -> void:
	var raw_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = -raw_direction if confused else raw_direction
	var vel = direction.normalized() * speed
	var raw_rate = acceleration if (direction.x != 0.0 || direction.y != 0.0) else deceleration
	var rate = raw_rate / 5.0 if slippery else raw_rate
	velocity = velocity.move_toward(vel, rate * delta)

	position += velocity * delta
	if bouncy and (position.y < 0.0 or position.y > get_viewport_rect().size.y):
		velocity.y *= -bounce_coefficient
	if bouncy and (position.x < 0.0 or position.x > get_viewport_rect().size.x):
		velocity.x *= -bounce_coefficient

	position = position.clamp(Vector2.ZERO, get_viewport_rect().size)

	if global_position.distance_squared_to(shadows.back().global_position) > 1.0:
		for i in range(shadow_count):
			shadows[i].global_position = shadows[i].global_position.lerp(global_position, 5.0 * delta * (shadow_count - i))

	if invincible:
		invincibility_timer -= delta
		toggle_visibility(not visible)

		if invincibility_timer <= 0.0:
			invincibility_timer = invincibility_duration
			invincible = false
			toggle_visibility(true)

func _on_body_entered(body: Node2D) -> void:
	if invincible and not attack_mode: return # Avoid using shield when invincible

	if attack_mode or shielded:
		if bouncy:
			velocity *= position.direction_to(body.position) * -bounce_coefficient

		enemy_killed.emit(body, body.is_in_group("boss"))
		body.queue_free()
		if not attack_mode and shielded:
			powerup_shield_stop()
		return

	if not invincible: # Avoid dying instantly upon shield usage
		hit.emit()
		toggle_visibility(false)
		$CollisionShape2D.set_deferred("disabled", true)
