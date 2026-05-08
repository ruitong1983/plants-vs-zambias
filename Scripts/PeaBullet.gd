# 子弹基类，所有豌豆子弹的父类
extends Area2D
class_name PeaBullet

# ------------------------------
# 导出变量（编辑器可调）
# ------------------------------
# 子弹飞行速度
@export var Speed: float = 350.0
# 命中僵尸时的爆炸/特效场景
@export var HitEffectScene: PackedScene

# ------------------------------
# 公共属性（由豌豆射手动态赋值）
# ------------------------------
# 子弹伤害
var Damage: int
# 是否为冰冻子弹
var IsIce: bool = false

# ------------------------------
# 引擎初始化函数
# ------------------------------
func _ready():
	# 绑定信号：当子弹进入其他区域（碰撞僵尸）时触发
	area_entered.connect(OnAreaEntered)

# ------------------------------
# 每帧执行：控制子弹飞行
# delta: 距离上一帧的时间
# ------------------------------
func _process(delta):
	# 让子弹向右匀速飞行
	position += Vector2(Speed * delta, 0)

# ------------------------------
# 碰撞检测：子弹碰到僵尸
# ------------------------------
func OnAreaEntered(area: Area2D):
	# 判断：只有碰到 Zombie 才执行逻辑
	if area is Zombie:
		# 获取僵尸对象
		var zombie: Zombie = area
		# 子类可覆写：施加冰冻减速等额外效果
		_apply_bullet_effect(zombie)
		# 造成伤害
		zombie.TakeDamage(Damage)
		# 生成命中特效
		SpawnHitEffect()
		# 销毁子弹
		queue_free()

# ------------------------------
# 子弹特殊效果钩子（子类覆写）
# ------------------------------
func _apply_bullet_effect(zombie: Zombie) -> void:
	pass  # 普通子弹无额外效果

# ------------------------------
# 生成命中特效
# ------------------------------
func SpawnHitEffect():
	if HitEffectScene != null:
		var effect = HitEffectScene.instantiate()
		get_parent().add_child(effect)
		effect.global_position = global_position

# ------------------------------
# 出屏幕自动销毁
# ------------------------------
func _on_screen_exited():
	queue_free()
