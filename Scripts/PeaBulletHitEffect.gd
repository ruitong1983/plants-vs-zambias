# 特效节点（用于击中、爆炸等动画），继承自 Sprite2D
extends Sprite2D

# 特效持续播放时间
@export var Duration: float = 0.3

# 节点初始化时执行
func _ready():
	# 设置初始缩放为 0.5
	scale = Vector2(0.5, 0.5)

	# 创建补间动画
	var tween = create_tween()

	# 动画1：缩放从 0.5 平滑变大到 1.5（向外扩散）
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), Duration)\
		.set_ease(Tween.EASE_OUT)

	# 动画结束后销毁自身
	tween.tween_callback(queue_free)
