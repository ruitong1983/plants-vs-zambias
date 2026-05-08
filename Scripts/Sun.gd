# 阳光节点，继承自 Area2D（可点击区域）
class_name Sun
extends Area2D

# 阳光收集后飞向的目标位置
@export var TargetPosition: Vector2 = Vector2(433, 73)
# 移动到目标位置的时间
@export var MoveDuration: float = 0.8
# 阳光飘落动画时间
@export var FlyDuration: float = 1.2
# 抛物线高度
@export var ArcHeight: float = -200.0

# ------------------------------
# 内部私有变量
# ------------------------------
var _startPos: Vector2    # 起始位置
var _endPos: Vector2      # 结束位置
var _isCollected: bool = false  # 是否被收集
var _isLaunching: bool = false  # 是否正在抛物线运动
var _launchElapsed: float = 0.0 # 抛物线动画已过去的时间

# ------------------------------
# 引擎初始化函数（节点加载完成执行）
# ------------------------------
func _ready():
	# 开启可点击（必须开才能点）
	input_pickable = true

# ------------------------------
# 鼠标点击事件
# ------------------------------
func _input_event(viewport, event, shape_idx):
	# 判断：未被收集 + 是鼠标左键按下
	if not _isCollected and event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# 执行收集
			collect()

# ------------------------------
# 收集阳光（核心动画）
# ------------------------------
func collect():
	# 标记已收集，防止重复点击
	_isCollected = true

	# 创建动画播放器
	var tween = create_tween()

	# 播放位移动画：移动到目标位置，使用正弦平滑曲线
	tween.tween_property(self, "global_position", TargetPosition, MoveDuration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	# 等待动画播放完成
	await tween.finished

	# 通知全局植物管理器增加阳光数量
	var pm = get_tree().get_first_node_in_group("PlantManager")
	if pm != null:
		pm.update_sun_count(50)

	# 动画结束，销毁阳光
	queue_free()


func launch(targetPos: Vector2):
	_startPos = global_position
	_endPos = targetPos
	_launchElapsed = 0.0
	_isLaunching = true

func _process(delta):
	if _isLaunching:
		_launchElapsed += delta
		var t: float = _launchElapsed / FlyDuration

		if t >= 1.0:
			_isLaunching = false
			global_position = _endPos
			return

		var controlPoint: Vector2 = (_startPos + _endPos) / 2 + Vector2(0, ArcHeight)
		var pos: Vector2 = (1 - t) * (1 - t) * _startPos + 2 * (1 - t) * t * controlPoint + t * t * _endPos
		global_position = pos
