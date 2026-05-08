# 植物基类（所有植物的父类），继承自 Area2D
extends Area2D
class_name Plants
# ------------------------------
# 导出变量（可在编辑器中调整）
# ------------------------------
# 植物的生命值
@export var HP: int = 100
# 植物是否已经种植（关键：向日葵脚本会用到这个）
@export var IsPlanted: bool = false

# ------------------------------
# 受到伤害函数
# 外部调用：植物.TakeDamage(伤害数值)
# ------------------------------
func TakeDamage(damage: int):
	# 扣血
	HP -= damage

	# 如果血量小于等于 0，执行死亡逻辑
	if HP <= 0:
		Die()

# ------------------------------
# 植物死亡函数
# ------------------------------
func Die():
	var cell = get_parent()
	if cell is GridCell:
		cell.set_plant_state(false)
	queue_free()
