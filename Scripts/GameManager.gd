extends Node2D
class_name GameManager

## 太阳场景（PackedScene），用于实例化太阳
@export var sun_scene: PackedScene
## UI 面板滑入动画的持续时间（秒）
@export var ui_slide_duration := 1.0
## 太阳生成的间隔时间（秒）
@export var sun_spawn_interval := 5.0
## 太阳生成 X 坐标最小值
@export var sun_spawn_x_min := 500.0
## 太阳生成 X 坐标最大值
@export var sun_spawn_x_max := 1500.0

## 相机节点引用，用于触发开场相机移动动画
var _camera: Node2D
## UI 面板（TextureRect）引用，用于开场滑入效果
var _ui: TextureRect


var _zombie_mgr: ZombieManager


func _ready() -> void:
	_camera = get_node("Camera2D") as Node2D
	_ui = get_node("PlantsUI") as TextureRect
	_ui.position = Vector2(_ui.position.x, -_ui.size.y - 70)

	_zombie_mgr = get_node("ZombieManager") as ZombieManager
	if _zombie_mgr != null:
		_zombie_mgr.all_zombies_defeated.connect(_on_all_zombies_defeated)

	start_game_sequence()


## 按顺序执行游戏开场流程：
## 1. 预览僵尸在右侧自然散开
## 2. 相机右移展示 → 停留 → 移回原位
## 3. 预览僵尸消失
## 4. UI 面板从上方滑入
## 5. 播放主游戏 BGM
## 6. 僵尸开始逐个刷新（X=2000, 随机路径 Y）
## 7. 开始生成太阳
func start_game_sequence() -> void:
	if _zombie_mgr != null:
		_zombie_mgr.spawn_preview_zombies()

	if _camera != null and _camera.has_method("start_camera_move"):
		_camera.start_camera_move()
		await _camera.camera_move_finished

	if _zombie_mgr != null:
		_zombie_mgr.clear_preview_zombies()

	await ui_slide_down()

	MusicManager.ensure_instance()
	if MusicManager.instance != null:
		MusicManager.instance.play_main_game_bgm()

	if _zombie_mgr != null:
		_zombie_mgr.spawn_game_zombies()

	spawn_suns()


# ============================================================================
# UI 动画
# ============================================================================

func ui_slide_down() -> void:
	var start_pos := _ui.position
	var end_pos := Vector2(start_pos.x, 5)

	var elapsed := 0.0
	while elapsed < ui_slide_duration:
		await get_tree().create_timer(0.01).timeout
		elapsed += 0.01
		_ui.position = start_pos + (end_pos - start_pos) * (elapsed / ui_slide_duration)

	_ui.position = end_pos


# ============================================================================
# 对象生成
# ============================================================================

func spawn_suns() -> void:
	while not _is_game_over():
		await get_tree().create_timer(sun_spawn_interval).timeout

		if _is_game_over():
			break
		if sun_scene != null:
			var sun := sun_scene.instantiate() as Node2D
			get_tree().current_scene.add_child(sun)
			sun.global_position = Vector2(randf_range(sun_spawn_x_min, sun_spawn_x_max), -50)

			var tween := get_tree().create_tween()
			var target_pos := Vector2(sun.global_position.x, randf_range(250, 1000))
			var fall_distance := target_pos.y - sun.global_position.y
			var bounce_power := fall_distance * 0.03
			tween.tween_property(sun, "global_position", target_pos, 3.0)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN)
			var bounce_count := 3
			var current_x := target_pos.x
			for i in range(bounce_count):
				var ratio := 1.0 - float(i) / bounce_count
				var this_bounce := bounce_power * ratio
				var h_offset := randf_range(-15, 15) * ratio
				current_x += h_offset
				var bounce_peak := Vector2(current_x, target_pos.y - this_bounce)
				tween.tween_property(sun, "global_position", bounce_peak, 0.1)\
					.set_trans(Tween.TRANS_SINE)\
					.set_ease(Tween.EASE_OUT)
				tween.tween_property(sun, "global_position:y", target_pos.y, 0.07)\
					.set_trans(Tween.TRANS_SINE)\
					.set_ease(Tween.EASE_IN)
			var roll_x := current_x + (current_x - target_pos.x) * 0.3 + randf_range(-5, 5)
			tween.tween_property(sun, "global_position:x", roll_x, 0.25)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_OUT)


func _on_all_zombies_defeated() -> void:
	print("所有僵尸已被消灭，游戏胜利！")
	MusicManager.ensure_instance()
	if MusicManager.instance != null:
		MusicManager.instance.play_game_win_sfx()
		MusicManager.instance.stop_bgm()
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://Scenes/StartMenu.tscn")


func _is_game_over() -> bool:
	var lose := get_tree().get_first_node_in_group("Lose") as Lose
	return lose != null and lose.game_over
