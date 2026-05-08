extends Control

# 当节点进入场景树时执行
func _ready():
	# 播放开始菜单背景音乐
	MusicManager.ensure_instance()
	if MusicManager.instance != null:
		MusicManager.instance.play_start_menu_bgm()

	# 获取按钮节点
	var start_button = $StartGameButton
	var exit_button = $ExitGameButton

	# 连接按钮的 pressed 信号到对应的处理函数
	start_button.pressed.connect(_on_start_game_button_pressed)
	exit_button.pressed.connect(_on_exit_game_button_pressed)


# 开始游戏按钮按下的处理函数
func _on_start_game_button_pressed():
	# 切换到游戏主场景
	get_tree().change_scene_to_file("res://Scenes/MainGame.tscn")


# 退出游戏按钮按下的处理函数
func _on_exit_game_button_pressed():
	# 退出游戏
	get_tree().quit()
