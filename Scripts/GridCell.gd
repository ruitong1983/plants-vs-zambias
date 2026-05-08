extends Area2D
class_name GridCell
## GridCell —— 网格单元格脚本
## 代表草坪上的一个种植格，处理点击种植操作（点击模式）。
## 拖拽模式的种植由 PlantManager._input 通过物理查询完成。

# 当前格子上是否已种植植物
# true: 已被占用，不可再种
# false: 空闲，可以种植
@export var HasPlant: bool = false

## 节点进入场景树时调用
## 连接 Area2D 自带的 input_event 信号，用于检测鼠标点击
func _ready() -> void:
	# 连接内置信号，当鼠标在此 Area2D 区域内发生点击时触发
	input_event.connect(_on_input_event)


## 鼠标在此单元格区域内发生输入事件时回调
## 点击模式：点击按钮后植物跟随鼠标，再点击格子完成种植
## @param viewport: 触发事件的视口节点
## @param event:  输入事件对象（鼠标点击、触摸等）
## @param shape_idx: 碰撞形状的索引（Area2D 可能有多个 CollisionShape2D）
func _on_input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	# 仅响应鼠标左键按下事件（点击模式：先点按钮选植物，再点格子种植物）
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 通过组查找 PlantManager 节点（挂载在 PlantsUI 上）
		var pm = get_tree().get_first_node_in_group("PlantManager")
		if pm != null:
			# 通知 PlantManager 尝试在当前格子上种植所选植物
			pm.place_on_cell(self)


## 设置当前格子的种植状态
## PlantManager 或 Plants.Die() 调用此方法来标记占用/释放
## @param has_plant: true 表示占用，false 表示释放
func set_plant_state(has_plant: bool) -> void:
	HasPlant = has_plant
