extends TextureButton
## 植物种植按钮
## 用于选择植物并放置到战场上，包含冷却时间和阳光消耗的UI控制
## 支持拖拽操作：按下左键开始拖拽植物预览，在格子上松开完成种植

## 需要种植的植物场景（PackedScene 资源）
@export var plant_scene: PackedScene = null
## 冷却时间，单位：秒
@export var cooldown_time: float = 5.0
## 种植该植物所需的阳光数量
@export var sun_cost: int = 50

## 冷却进度条控件引用
var _cooldown_bar: TextureProgressBar = null
## 是否正在冷却中
var _is_cooling: bool = false
## 冷却计时器，记录当前已冷却的时间（秒）
var _cooldown_timer: float = 0.0

func _ready() -> void:
	# 获取冷却进度条控件
	_cooldown_bar = get_node_or_null("CooldownBar")
	if _cooldown_bar != null:
		# 初始状态：隐藏进度条，进度值设为满
		_cooldown_bar.visible = false
		_cooldown_bar.value = 100

	# 连接按钮按下信号（鼠标左键按下即触发，支持拖拽）
	button_down.connect(_on_button_down)


## 鼠标左键按下按钮时的处理逻辑
## 启动植物放置模式，植物预览跟随鼠标移动，不立即扣阳光
func _on_button_down() -> void:
	# 如果正在冷却中，或者没有配置植物场景，则忽略
	if _is_cooling or plant_scene == null:
		return

	var pm = get_parent()
	# 检查 PlantManager 是否存在，且当前阳光足够
	if pm != null and pm.currentSun >= sun_cost:
		# 启动放置植物的流程，将当前按钮引用传入（阳光扣减由 PlantManager 在放置成功时处理）
		pm.start_placing_plant(plant_scene, self)


## 开始冷却计时（由 PlantManager 在植物成功放置后调用）
func start_cooldown() -> void:
	_is_cooling = true
	if _cooldown_bar != null:
		_cooldown_bar.visible = true


func _process(delta: float) -> void:
	# ————— 冷却逻辑 —————
	if _is_cooling:
		# 累加冷却时间
		_cooldown_timer += delta

		# 根据冷却进度更新进度条显示值（从 100% 递减到 0%）
		var progress: float = 100.0 - (_cooldown_timer / cooldown_time) * 100.0
		_cooldown_bar.value = clamp(progress, 0.0, 100.0)

		# 冷却时间到达，结束冷却状态
		if _cooldown_timer >= cooldown_time:
			_cooldown_bar.visible = false
			_cooldown_bar.value = 100
			_cooldown_timer = 0.0
			_is_cooling = false

	# ————— 按钮禁用状态更新 —————
	# 当阳光不足或正在冷却时，禁用按钮
	var pm = get_parent()
	if pm != null:
		disabled = pm.currentSun < sun_cost or _is_cooling
