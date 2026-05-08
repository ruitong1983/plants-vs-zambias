# MusicManager.gd —— 游戏音频管理单例
# 负责 BGM 和 SFX 的播放与停止，统一管理游戏内所有音频资源
# 作为 Autoload 使用，通过 MusicManager.instance 全局访问
extends Node
# 注意：不要在 autoload 脚本上使用 class_name，会与 autoload 节点名冲突


# ============================================================================
# 单例
# ============================================================================

static var instance: Node


# ============================================================================
# 音频资源（preload 加载，autoload 下比 @export 更可靠）
# ============================================================================

const start_menu_bgm    := preload("res://素材/Audio/Music/StartMenuBGM.mp3")
const main_game_bgm     := preload("res://素材/Audio/Music/MainGameBGM.mp3")
const main_game_start_sfx := preload("res://素材/Audio/Sound/awooga.ogg")
const game_win_sfx      := preload("res://素材/Audio/Sound/胜利.ogg")
const game_lose_sfx     := preload("res://素材/Audio/Sound/失败.ogg")
const zombie_eat_sfx    := preload("res://素材/Audio/Sound/僵尸吃音效.ogg")


# ============================================================================
# 内部播放器（动态创建，不依赖场景节点）
# ============================================================================

var _bgm_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _sfx_player2: AudioStreamPlayer


# ============================================================================
# 初始化
# ============================================================================

func _enter_tree() -> void:
	if instance == null:
		instance = self


func _ready() -> void:
	if instance != self:
		queue_free()
		return

	# 动态创建三个音频播放器作为子节点
	_bgm_player = _create_player("BGMPlayer")
	_sfx_player = _create_player("SFXPlayer")
	_sfx_player2 = _create_player("SFXPlayer2")


func _create_player(p_name: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = p_name
	add_child(p)
	return p


## 确保全局实例已赋值（如 autoload 未配置，从场景树中查找）
static func ensure_instance() -> void:
	if instance != null:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		instance = tree.root.get_node_or_null("MusicManager")


# ============================================================================
# BGM 控制
# ============================================================================

func play_bgm(bgm: AudioStream) -> void:
	if bgm == null or _bgm_player == null:
		return
	if _bgm_player.stream == bgm and _bgm_player.playing:
		return
	_bgm_player.stream = bgm
	_bgm_player.play()


func stop_bgm() -> void:
	if _bgm_player != null:
		_bgm_player.stop()


# ============================================================================
# SFX 控制
# ============================================================================

func play_sfx(sfx: AudioStream, use_second: bool = false) -> void:
	if sfx == null:
		return
	var player := _sfx_player2 if use_second else _sfx_player
	if player == null:
		return
	player.stream = sfx
	player.play()


# ============================================================================
# 快捷播放方法
# ============================================================================

func play_start_menu_bgm() -> void:
	play_bgm(start_menu_bgm)


func play_main_game_bgm() -> void:
	play_bgm(main_game_bgm)


func play_main_game_start_sfx() -> void:
	play_sfx(main_game_start_sfx)


func play_game_win_sfx() -> void:
	play_sfx(game_win_sfx)


func play_game_lose_sfx() -> void:
	play_sfx(game_lose_sfx)


func play_zombie_eat_sfx() -> void:
	play_sfx(zombie_eat_sfx, true)
