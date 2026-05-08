extends Plants
class_name WallNut
## WallNut —— 坚果墙脚本
## 继承自 Plants，一种高生命值的防御型植物。
## 根据当前 HP 在三组动画间切换：
##   - HP > 160:   default  （完好无损）
##   - 80 < HP <= 160: cracked1 （轻微开裂）
##   - 0 < HP <= 80:  cracked2 （严重开裂）
##   - HP <= 0: 由父类 Plants 的 TakeDamage() 调用 Die() 销毁
##
##  HP 初始值在 _ready() 中设为 200，覆盖父类 Plants 的 Export 默认值。


# =============================================================================
# 节点引用
# =============================================================================

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

## 节点进入场景树时调用
## 坚果墙初始血量，覆盖场景中的 Export 默认值
func _ready() -> void:
	HP = 200


## 每帧调用一次，根据当前 HP 切换开裂动画
## @param delta: 上一帧到当前帧的时间间隔（秒），此处未使用
func _process(delta: float) -> void:
	# HP <= 0 时，父类 TakeDamage() 会调用 Die() 销毁节点，
	# 此处不再额外处理，避免重复逻辑。
	if HP > 160:
		# 血量充裕，保持完好外观
		anim.play("default")
	elif HP > 80:
		# 80 < HP <= 160，播放"轻微开裂"动画
		anim.play("cracked1")
	elif HP > 0:
		# 0 < HP <= 80，播放"严重开裂"动画
		anim.play("cracked2")
