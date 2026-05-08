extends TextureRect
## PlantManager —— 植物管理单例
## 全局唯一的植物种植管理器，负责：
##   - 阳光数量管理
##   - 植物放置流程（开始放置 / 取消 / 确认种植）
##   - 跟随鼠标预览当前待种植物
##   - 胜利 / 失败判断与 UI 展示
##
## 放置流程同时支持两种操作方式：
##   1. 拖拽：按住按钮 → 拖到格子 → 松开完成种植
##   2. 点击：点击按钮 → 植物跟随鼠标 → 再点击格子完成种植

# 当前正在跟随鼠标的植物节点（待放置预览）
var _currentPlant: Node2D = null
# 触发本次放置的植物按钮，用于取消时恢复按钮状态
var _sourceButton = null  # PlantButton 引用
# 是否处于放置模式（鼠标跟随植物等待点击格子）
var _isPlacing: bool = false
# 阳光数量 Label 引用，用于在 UI 上显示当前阳光数
var _SunText: Label
# 当前拥有的阳光数量，初始 100
var currentSun: int = 100
# 拖拽起始位置，用于判断是否发生了拖拽
var _drag_start_pos: Vector2 = Vector2.ZERO
# 是否已触发拖拽（鼠标移动超过阈值）
var _has_dragged: bool = false

const DRAG_THRESHOLD: float = 10.0  # 拖拽判定阈值（像素）

## 节点进入场景树时调用
## 将自身注册到 "PlantManager" 组，供其他脚本通过 get_tree().get_first_node_in_group() 查找
func _ready() -> void:
	# 注册到组，替代 autoload 全局查找
	add_to_group("PlantManager")

	# 获取 UI 子节点引用
	_SunText = $SunText as Label


## 每帧调用一次
## - 刷新阳光数量显示
## - 放置模式下让植物跟随鼠标，检测拖拽
func _process(delta: float) -> void:
	# 实时更新阳光数量文本
	if _SunText != null:
		_SunText.text = str(currentSun)

	# 放置模式处理
	if _isPlacing and _currentPlant != null:
		# 植物跟随鼠标移动
		_currentPlant.global_position = get_viewport().get_mouse_position()

		# 检测是否达到拖拽阈值
		if not _has_dragged:
			var mouse_pos = get_viewport().get_mouse_position()
			if mouse_pos.distance_to(_drag_start_pos) > DRAG_THRESHOLD:
				_has_dragged = true


## 全局输入事件处理
## 检测鼠标左键松开：
##   - 拖拽模式：物理查询鼠标下的 GridCell，找到则种植，否则取消
##   - 点击模式：松开不处理，留给 GridCell 的 input_event（点击格子）来触发种植
func _input(event: InputEvent) -> void:
	if not _isPlacing:
		return

	# 如果游戏已结束，只响应 ESC/右键取消，不响应种植操作
	if _is_game_over():
		# 允许取消放置，清理预览植物
		if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
			cancel_placing()
		return

	# ESC 或右键取消放置
	if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
		cancel_placing()
		return

	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _has_dragged:
			# 点击模式：按钮点了一下就松开，植物继续跟随鼠标，等用户点格子
			return

		# 拖拽模式：拖拽后松开，通过物理查询检测鼠标位置下的格子
		var space_state = get_viewport().get_world_2d().direct_space_state
		var params = PhysicsPointQueryParameters2D.new()
		params.position = get_viewport().get_mouse_position()
		params.collide_with_areas = true
		params.collide_with_bodies = false
		var results = space_state.intersect_point(params)

		var placed = false
		for result in results:
			var collider = result.get("collider")
			if collider is GridCell:
				placed = place_on_cell(collider)
				break

		if not placed:
			cancel_placing()


## 开始放置植物
## 实例化植物场景，将其添加到场景根节点，使其跟随鼠标移动
## @param plant_scene:  植物的 PackedScene（.tscn 文件）
## @param source_button: 触发放置的 PlantButton 节点，取消时用于通知恢复
func start_placing_plant(plant_scene: PackedScene, source_button) -> void:
	# 如果之前有未完成的放置操作，先取消
	cancel_placing()

	# 实例化植物节点
	_currentPlant = plant_scene.instantiate() as Node2D
	# 预览阶段禁用碰撞，防止僵尸误判为已种植植物
	_currentPlant.collision_layer = 0
	_currentPlant.collision_mask = 0
	# 添加到场景根节点，使其独立于 UI 层，跟随鼠标自由移动
	get_tree().root.add_child(_currentPlant)

	_sourceButton = source_button
	_isPlacing = true
	# 记录拖拽起始位置，用于判断点击 vs 拖拽
	_drag_start_pos = get_viewport().get_mouse_position()
	_has_dragged = false


## 取消当前植物放置操作
## 销毁预览节点，重置所有放置相关状态
func cancel_placing() -> void:
	if _currentPlant != null:
		_currentPlant.queue_free()
		_currentPlant = null
	_isPlacing = false
	_sourceButton = null


## 尝试将当前正在放置的植物种到指定格子上
## 拖拽模式由 _input 物理查询调用，点击模式由 GridCell 的 input_event 调用
## @param cell: 目标种植格（GridCell 节点）
## @return: true 表示种植成功，false 表示失败（不在放置模式 / 格子已占用）
func place_on_cell(cell: GridCell) -> bool:
	# 前置检查：是否处于放置模式且有待种植的植物
	if not _isPlacing or _currentPlant == null:
		return false

	# 格子上已有植物，不可重复种植
	if cell.HasPlant:
		return false

	# 将植物从根节点移动到目标格子下作为子节点
	_currentPlant.get_parent().remove_child(_currentPlant)
	cell.add_child(_currentPlant)
	_currentPlant.global_position = cell.global_position

	# 标记格子为已占用
	cell.set_plant_state(true)

	# 设置植物的物理碰撞层，使其能与僵尸发生碰撞检测
	if _currentPlant is Plants:
		_currentPlant.IsPlanted = true
		_currentPlant.collision_layer = 1
		_currentPlant.collision_mask = 1

	# 扣减阳光（种植成功时才扣）
	if _sourceButton != null:
		currentSun -= _sourceButton.sun_cost
		# 通知按钮开始冷却
		_sourceButton.start_cooldown()

	# 种植完成，重置放置状态
	_currentPlant = null
	_isPlacing = false
	_sourceButton = null

	return true


## 更新阳光数量
## @param amount: 变化量，正数为增加阳光，负数为消耗阳光
## 检查游戏是否已结束（从 Lose 节点读取 game_over 标志）
func _is_game_over() -> bool:
	var lose = get_tree().get_first_node_in_group("Lose") as Lose
	return lose != null and lose.game_over


func update_sun_count(amount: int) -> void:
	if _SunText != null:
		currentSun += amount
