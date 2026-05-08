# 路障僵尸，继承自基础僵尸，血量300，血降到2/3时掉路障，降到1/3时掉头
extends Zombie

func _ready():
	MaxHealth = 300
	super._ready()

# 重写受伤逻辑：血降到2/3只掉路障不掉头，降到1/3时才掉头
func TakeDamage(damage: int) -> void:
	_currentHealth -= damage
	update_animation()

	if _currentHealth <= MaxHealth / 3 and not _lostHeadPlayed:
		_lostHeadPlayed = true
		play_lost_head_animation()

	if _currentHealth <= 0:
		die()

func update_animation() -> void:
	if _currentHealth <= 0:
		return

	if _isAttacking:
		if _currentHealth > MaxHealth * 2 / 3:
			_anim.play("EatWithConehead")
		elif _currentHealth > MaxHealth / 3:
			_anim.play("Eat")
		else:
			_anim.play("LostHeadEat")
	else:
		if _currentHealth > MaxHealth * 2 / 3:
			_anim.play("MoveWithConehead")
		elif _currentHealth > MaxHealth / 3:
			_anim.play("Move")
		else:
			_anim.play("LostHeadMove")
