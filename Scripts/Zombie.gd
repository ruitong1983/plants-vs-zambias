# 僵尸主体脚本，继承自Area2D（用于碰撞检测）
extends Area2D
class_name Zombie

signal zombie_died

# ===================== 导出变量（可在编辑器面板调整） =====================
# 僵尸移动速度
@export var Speed: float = 40.0
# 最大生命值
@export var MaxHealth: int = 200
# 攻击力
@export var AttackDamage: int = 20
# 攻击间隔时间（秒）
@export var AttackInterval: float = 1.5

# ===================== 私有成员变量 =====================
# 当前生命值
var _currentHealth: int
# 是否正在攻击
var _isAttacking: bool = false
# 是否播放过头掉下来的动画
var _lostHeadPlayed: bool = false
# 攻击定时器
var _attackTimer: Timer
# 当前攻击的目标植物
var _targetPlant: Node2D
# 是否正在等待（开局预览时不移动）
var _is_waiting: bool = false
# 是否已经死亡
var _isDead: bool = false

# 动画播放器（身体动画）
@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
# 头掉落动画播放器
@onready var _lostHeadAnim: AnimatedSprite2D = $LostHeadAnimate

# ===================== 初始化函数（节点就绪时调用） =====================
func _ready():
	# 初始化当前生命值为最大值
	add_to_group("Zombie")

	_currentHealth = MaxHealth

	# 创建攻击定时器
	_attackTimer = Timer.new()
	# 设置等待时间
	_attackTimer.wait_time = AttackInterval
	# 循环触发
	_attackTimer.one_shot = false
	# 绑定超时信号 → 攻击函数
	_attackTimer.timeout.connect(_on_attack)
	# 将定时器添加为子节点
	add_child(_attackTimer)

	# 绑定区域进入/退出信号（检测植物）
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

# ===================== 每帧更新函数 =====================
func _process(delta: float) -> void:
	# 等待中、攻击中或已死亡时停止移动
	if _is_waiting or _isAttacking or _isDead:
		return
	# 僵尸向左移动
	position += Vector2(-Speed * delta, 0)

# ===================== 开始移动（由 ZombieManager 调用） =====================
func start_moving() -> void:
	_is_waiting = false


# ===================== 当有区域进入碰撞时触发（检测植物） =====================
func _on_area_entered(area: Area2D) -> void:
	# 只攻击已种植的植物（排除预览中的植物）
	if area is Plants and area.IsPlanted:
		# 设置目标植物
		_targetPlant = area
		# 开始攻击
		start_attack()

# ===================== 当区域退出碰撞时触发（植物消失） =====================
func _on_area_exited(area: Area2D) -> void:
	# 如果退出的是当前攻击目标
	if _targetPlant == area:
		# 停止攻击
		stop_attack()

# ===================== 开始攻击 =====================
func start_attack() -> void:
	# 如果已经在攻击 → 不重复执行
	if _isAttacking:
		return

	_isAttacking = true
	# 播放啃咬音效（使用第二音效播放器，不干扰常规音效）
	MusicManager.ensure_instance()
	if MusicManager.instance != null:
		MusicManager.instance.play_zombie_eat_sfx()
		# 更新动画为攻击动画
		update_animation()
		# 启动攻击定时器
		_attackTimer.start()
		# 立即造成一次伤害，避免等待间隔
		_on_attack()

# ===================== 停止攻击 =====================
func stop_attack() -> void:
	_isAttacking = false
	_targetPlant = null
	# 切换回行走动画
	update_animation()
	# 停止攻击定时器
	_attackTimer.stop()

# ===================== 攻击执行函数（定时器触发） =====================
func _on_attack() -> void:
	# 没有目标 → 退出
	if _targetPlant == null:
		return

	# 如果目标有 TakeDamage 方法
	if _targetPlant.has_method("TakeDamage"):
		# 对植物造成伤害
		_targetPlant.TakeDamage(AttackDamage)
		# 播放啃咬音效
		MusicManager.ensure_instance()
		if MusicManager.instance != null:
			MusicManager.instance.play_zombie_eat_sfx()

# ===================== 受到伤害函数（被子弹调用） =====================
func TakeDamage(damage: int) -> void:
	# 扣除生命值
	_currentHealth -= damage
	# 更新动画状态
	update_animation()

	# 生命值低于一半 且 没播放过头掉落动画
	if _currentHealth <= MaxHealth / 2 and not _lostHeadPlayed:
		_lostHeadPlayed = true
		# 播放头掉落动画
		play_lost_head_animation()

	# 生命值 ≤ 0 → 死亡
	if _currentHealth <= 0:
		die()

# ===================== 播放头掉落动画（异步等待完成） =====================
func play_lost_head_animation() -> void:
	# 没有动画节点 → 退出
	if _lostHeadAnim == null:
		return

	# 显示并播放动画
	_lostHeadAnim.visible = true
	_lostHeadAnim.play("LostHead")

	# 等待动画播放完成
	await _lostHeadAnim.animation_finished
	if not is_instance_valid(_lostHeadAnim):
		return
	# 隐藏动画并移除头部
	_lostHeadAnim.visible = false
	_lostHeadAnim.queue_free()

# ===================== 死亡逻辑 =====================
func die() -> void:
	# 已经死亡 → 不重复执行
	if _isDead:
		return

	_isDead = true
	zombie_died.emit()
	# 停止移动
	Speed = 0
	# 停止攻击
	_isAttacking = false
	_attackTimer.stop()
	# 播放死亡动画
	play_die_animation()

# ===================== 统一动画更新函数（核心） =====================
func update_animation() -> void:
	# 已死亡 → 不处理
	if _currentHealth <= 0:
		return

	# 判断是否在攻击
	if _isAttacking:
		# 生命值 > 一半 → 正常攻击动画；否则 → 无头攻击动画
		if _currentHealth > MaxHealth / 2:
			_anim.play("Eat")
		else:
			_anim.play("LostHeadEat")
	else:
		# 生命值 > 一半 → 正常行走；否则 → 无头行走
		if _currentHealth > MaxHealth / 2:
			_anim.play("Move")
		else:
			_anim.play("LostHeadMove")

# ===================== 播放死亡动画（异步等待后销毁） =====================
func play_die_animation() -> void:
	# 没有动画节点 → 直接删除
	if _anim == null:
		queue_free()
		return

	# 播放死亡动画
	_anim.play("Die")
	# 等待动画结束
	await _anim.animation_finished
	# 删除僵尸节点
	queue_free()
