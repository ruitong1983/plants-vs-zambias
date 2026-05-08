# 冰冻豌豆射手，继承自 PeaShooter
# 发射冰冻子弹，命中时减速僵尸
extends PeaShooter
class_name IcePeaShooter

# ------------------------------
# 导出变量
# ------------------------------
# 冰冻豌豆子弹场景（拖拽赋值）
@export var IcePeaScene: PackedScene


# ------------------------------
# 覆写：返回冰冻子弹场景
# ------------------------------
func _get_bullet_scene() -> PackedScene:
	return IcePeaScene
