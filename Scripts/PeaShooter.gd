# 豌豆射手脚本，继承自 植物基类 Plants
extends Plants
class_name PeaShooter

# ------------------------------
# 导出变量（编辑器可设置）
# ------------------------------
# 攻击力
@export var AttackPower: int = 20
# 发射子弹的间隔时间（秒）
@export var FireInterval: float = 1.5
# 普通豌豆子弹场景（拖拽赋值）
@export var NormalPeaScene: PackedScene
# 发射点节点（标记子弹从哪里出来）
@export var FiringPos: Marker2D

# ------------------------------
# 私有变量
# ------------------------------
# 发射子弹的定时器
var _fireTimer: Timer


# ------------------------------
# 初始化函数（节点加载完成执行）
# ------------------------------
func _ready():
	# 1. 创建定时器
	_fireTimer = Timer.new()
	# 2. 设置发射间隔
	_fireTimer.wait_time = FireInterval
	# 3. 设置循环触发（false=一直循环发射）
	_fireTimer.one_shot = false
	# 4. 绑定信号：定时器时间到 → 执行发射函数
	_fireTimer.timeout.connect(ShootPea)
	# 5. 将定时器添加为子节点
	add_child(_fireTimer)
	# 6. 启动定时器
	_fireTimer.start()


# ------------------------------
# 发射豌豆子弹（核心功能）
# ------------------------------
func ShootPea():
	var bullet_scene := _get_bullet_scene()

	# 安全判断：未种植 或 未设置子弹 → 不发射
	if IsPlanted == false or bullet_scene == null:
		return

	# 实例化子弹
	var pea := bullet_scene.instantiate()
	# 将子弹添加到格子节点下（和植物同级）
	get_parent().add_child(pea)
	# 设置子弹的出生位置 = 豌豆射手的发射点位置
	pea.global_position = FiringPos.global_position

	# 类型安全判断：如果是子弹，设置属性
	if pea is PeaBullet:
		pea.Damage = AttackPower


# ------------------------------
# 获取子弹场景（子类覆写以使用不同子弹）
# ------------------------------
func _get_bullet_scene() -> PackedScene:
	return NormalPeaScene
