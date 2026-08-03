extends Area2D
signal hit
signal enemy_killed

@export var speed = 300.0
@export var acceleration = 2500.0
@export var deceleration = 4000.0

var shielded = false
var attack_mode = false
var velocity = Vector2.ZERO

var shadows: Array[Sprite2D]
var shadow_count = 3

func powerup_shield() -> void:
	shielded = true
	$ShieldSprite.show()

func powerup_shield_stop() -> void:
	shielded = false
	$ShieldSprite.hide()

func powerup_attack() -> void:
	attack_mode = true
	$AttackSprite.show()

func powerup_attack_stop() -> void:
	attack_mode = false
	$AttackSprite.hide()

func start(pos: Vector2):
	position = pos
	for i in range(shadow_count):
		shadows[i].position = pos
		shadows[i].show()

	powerup_shield_stop()
	powerup_attack_stop()
	show()
	$CollisionShape2D.disabled = false

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
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var vel = direction.normalized() * speed
	var rate = acceleration if (direction.x != 0.0 || direction.y != 0.0) else deceleration
	velocity = velocity.move_toward(vel, rate * delta)

	position += velocity * delta
	position = position.clamp(Vector2.ZERO, get_viewport_rect().size)

	if global_position.distance_squared_to(shadows.back().global_position) > 1.0:
		for i in range(shadow_count):
			shadows[i].global_position = shadows[i].global_position.lerp(global_position, 5.0 * delta * (shadow_count - i))

func _on_body_entered(body: Node2D) -> void:
	if attack_mode:
		body.queue_free()
		enemy_killed.emit()
		return

	if shielded:
		body.queue_free()
		enemy_killed.emit()
		powerup_shield_stop()
		return

	for i in range(shadow_count):
		shadows[i].hide()
	hide()
	hit.emit()
	$CollisionShape2D.set_deferred("disabled", true)
