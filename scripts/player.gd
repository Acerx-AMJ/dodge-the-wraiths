extends Area2D
signal hit
signal enemy_killed

@export var speed = 400
var shielded = false
var attack_mode = false

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
	powerup_shield_stop()
	powerup_attack_stop()
	show()
	$CollisionShape2D.disabled = false

func _process(delta: float) -> void:
	var velocity: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = velocity.y > 0

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
	
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, get_viewport_rect().size)

func _on_body_entered(body: Node2D) -> void:
	if attack_mode:
		body.queue_free()
		enemy_killed.emit()

	if not shielded and not attack_mode:
		hide()
		hit.emit()
		$CollisionShape2D.set_deferred("disabled", true)
