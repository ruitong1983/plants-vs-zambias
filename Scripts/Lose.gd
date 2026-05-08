# Lose.gd —— 游戏失败检测区域与 UI 控制
# 继承自 Area2D，放置在草坪最左侧，僵尸进入时触发失败判定
# 所有失败相关逻辑（UI 显示、音效、game_over 标志）都在此脚本中集中管理
extends Area2D
class_name Lose


## 失败时显示的 UI 面板（TextureRect），在编辑器中拖入 LoseUI 节点赋值
## 如果未手动赋值，运行时会自动查找同级节点 "LoseUI"
@export var lose_ui: Control

## 游戏是否已结束，外部脚本通过此标志判断是否阻止操作（如种植）
var game_over: bool = false


func _ready() -> void:
	add_to_group("Lose")

	# 先断开再连接，避免编辑器残留信号干扰
	if area_entered.is_connected(_on_area_entered):
		area_entered.disconnect(_on_area_entered)
	area_entered.connect(_on_area_entered)

	# 游戏开始时隐藏失败 UI
	if lose_ui != null:
		lose_ui.visible = false


func _on_area_entered(area: Area2D) -> void:
	# 只响应僵尸（通过组名判断，比 class_name 的 is 运算符更可靠）
	if not area.is_in_group("Zombie"):
		return

	# 避免重复触发
	if game_over:
		return

	game_over = true

	# 如果编辑器未赋值，自动在场景中查找
	if lose_ui == null:
		lose_ui = get_node("../LoseUI") as Control
	if lose_ui != null:
		lose_ui.visible = true

	# 播放失败音效并停止 BGM
	MusicManager.ensure_instance()
	if MusicManager.instance != null:
		MusicManager.instance.play_game_lose_sfx()
		MusicManager.instance.stop_bgm()


func _input(event: InputEvent) -> void:
	if not game_over:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().change_scene_to_file("res://Scenes/StartMenu.tscn")
