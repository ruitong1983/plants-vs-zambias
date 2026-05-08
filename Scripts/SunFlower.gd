class_name SunFlower
extends Plants
# ------------------------------
# 导出变量（编辑器可设置）
# ------------------------------
# 阳光的预制体（拖拽 Sun 场景到这里）
@export var SunScene: PackedScene
# 生成阳光的间隔时间（秒）
@export var GenerateInterval: float = 5.0
# 阳光落地时的散落半径（越大散得越远）
@export var ScatterRadius: float = 100.0
# 阳光落地时向下的偏移范围（越大越偏下）
@export var ScatterVerticalMin: float = 40.0
@export var ScatterVerticalMax: float = 100.0
# 抛物线高度随机范围
@export var ArcHeightMin: float = -250.0
@export var ArcHeightMax: float = -180.0

# ------------------------------
# 内部变量
# ------------------------------
# 生成阳光的定时器
var _generateTimer: Timer
# 动画播放器
var anim: AnimatedSprite2D
# 记录之前播放的动画
var previousAnim: StringName
# 随机数生成器
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# ------------------------------
# 初始化函数
# ------------------------------
func _ready():
	# 初始化随机数生成器
	_rng.randomize()

	# 获取子节点 AnimatedSprite2D
	anim = $AnimatedSprite2D

	# 创建定时器
	_generateTimer = Timer.new()
	# 设置等待时间
	_generateTimer.wait_time = GenerateInterval
	# 循环执行（false=重复执行）
	_generateTimer.one_shot = false
	# 绑定超时信号 → 执行生成阳光函数
	_generateTimer.timeout.connect(GenerateSun)
	# 添加到节点树
	add_child(_generateTimer)
	# 启动定时器
	_generateTimer.start()

# ------------------------------
# 生成阳光（核心功能）
# ------------------------------
func GenerateSun():
	# 如果没绑定阳光预制体 或 植物未种植 → 直接退出
	if SunScene == null || IsPlanted == false:
		return

	# 播放一次闪光动画
	PlayOnceAnim("flash")

	# 实例化阳光
	var sun: Node2D = SunScene.instantiate()
	# 添加到当前场景
	get_tree().current_scene.add_child(sun)

	# 设置阳光初始位置（向日葵上方一点）
	sun.global_position = global_position + Vector2(0, -30)

	# 如果阳光是 Sun 类型 → 调用抛物线发射
	if sun is Sun:
		# 设置抛物线高度的随机值
		sun.ArcHeight = _rng.randf_range(ArcHeightMin, ArcHeightMax)
		# 让阳光落在向日葵附近的随机位置
		var scatter_offset = Vector2(_rng.randf_range(-ScatterRadius, ScatterRadius), _rng.randf_range(ScatterVerticalMin, ScatterVerticalMax))
		sun.launch(global_position + scatter_offset)


# ------------------------------
# 播放一次动画，播放完后切回原动画
# ------------------------------
func PlayOnceAnim(animName: StringName):
	# 记录当前正在播放的动画
	previousAnim = anim.animation
	# 播放指定动画
	anim.play(animName)

	# 等待动画播放完成
	await anim.animation_finished

	# 播完后切回原来的动画
	anim.play(previousAnim)
