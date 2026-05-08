# 铁桶僵尸，继承自基础僵尸，血量翻倍，动画不同
extends Zombie

func _ready():
	# 必须在 super._ready() 之前设置，因为父类 _ready() 中 _currentHealth = MaxHealth
	MaxHealth = 400
	super._ready()

# 重写受伤逻辑：铁桶僵尸在血量降到一半时只掉桶不掉头，降到1/4时才掉头
func TakeDamage(damage: int) -> void:
	_currentHealth -= damage
	update_animation()

	# 血量降到1/4且没播放过头掉落动画 → 掉头
	if _currentHealth <= MaxHealth / 4 and not _lostHeadPlayed:
		_lostHeadPlayed = true
		play_lost_head_animation()

	if _currentHealth <= 0:
		die()

func update_animation() -> void:
	if _currentHealth <= 0:
		return

	if _isAttacking:
		if _currentHealth > MaxHealth / 2:
			_anim.play("EatWithBuckethead")
		elif _currentHealth > MaxHealth / 4:
			_anim.play("Eat")
		else:
			_anim.play("LostHeadEat")
	else:
		if _currentHealth > MaxHealth / 2:
			_anim.play("MoveWithBuckethead")
		elif _currentHealth > MaxHealth / 4:
			_anim.play("Move")
		else:
			_anim.play("LostHeadMove")
