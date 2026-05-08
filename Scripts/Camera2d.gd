extends Camera2D
class_name Camera2d
## 相机移动完成时发出的信号，用于通知其他节点相机动画已结束
signal camera_move_finished


## 执行相机移动动画：
## 1. 播放开场音效
## 2. 相机向右平移 580 像素（1.5 秒，Sine InOut 缓动）
## 3. 停留 0.8 秒
## 4. 相机移回原位（1.5 秒，Sine InOut 缓动）
## 5. 发出 camera_move_finished 信号
func start_camera_move() -> void:
	## 播放游戏主界面开场音效
	MusicManager.ensure_instance()
	if MusicManager.instance != null:
		MusicManager.instance.play_main_game_start_sfx()

	# 记录动画开始前的相机位置，作为最终返回的目标位置
	var start_pos := position
	# 终点：从起始位置向右偏移 580 像素
	var end_pos := start_pos + Vector2(580, 0)

	# --- 第一阶段：向右移动 ---
	var tween := get_tree().create_tween()
	# 在 1.5 秒内将 position 属性从当前值渐变到 end_pos
	tween.tween_property(self, "position", end_pos, 1.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	# 等待向右移动的补间动画播放完毕
	await tween.finished

	# --- 第二阶段：在终点停留 0.8 秒 ---
	await get_tree().create_timer(0.8).timeout

	# --- 第三阶段：移回原位 ---
	var tween_back := get_tree().create_tween()
	# 在 1.5 秒内将 position 属性从当前位置渐变回 start_pos
	tween_back.tween_property(self, "position", start_pos, 1.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	# 等待移回原位的补间动画播放完毕
	await tween_back.finished

	# 通知所有监听者：相机移动动画已全部完成
	camera_move_finished.emit()
