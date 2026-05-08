# 冰冻豌豆子弹，继承自 PeaBullet
# 命中时减速僵尸并使其变色
extends PeaBullet
class_name IcePeaBullet

# ------------------------------
# 子弹特殊效果：冰冻减速 + 变色
# ------------------------------
func _apply_bullet_effect(zombie: Zombie) -> void:
	# 减速僵尸
	zombie.Speed = 20
	# 僵尸变蓝色（冰冻特效）
	zombie.modulate = Color(0.060, 0.600, 0.900, 1.0)
