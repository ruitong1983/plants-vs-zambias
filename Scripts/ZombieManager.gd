# 僵尸管理脚本，分两阶段：
# 1. 预览阶段：开局镜头右移时，僵尸在右侧自然随机散开（纯展示）
# 2. 游戏阶段：镜头左移后，预览僵尸消失，僵尸在 X=2000 固定位置逐个刷新
extends Node2D
class_name ZombieManager

signal all_zombies_defeated

@export var zombie_scenes: Array[PackedScene] = []
@export var zombie_weights: Array[int] = [4, 2, 2, 2]
@export var max_zombies: int = 20
@export var spawn_interval: float = 8.0
@export var spawn_x: float = 2000.0

var _spawned_count: int = 0
var _killed_count: int = 0
var _lane_y_values: Array[float] = [220, 400, 580, 760, 940]
var _preview_zombies: Array[Zombie] = []


# ===================== 预览阶段：自然随机散开 =====================

func spawn_preview_zombies() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	const area_x_min := 1955.0
	const area_x_max := 2250.0
	const area_y_min := 180.0
	const area_y_max := 980.0
	const min_spacing := 50.0

	var placed_positions: Array[Vector2] = []

	for _i in range(max_zombies):
		var scene := _pick_random_scene()
		if scene == null:
			continue

		var zombie := scene.instantiate() as Zombie
		if zombie == null:
			continue

		zombie._is_waiting = true
		get_tree().current_scene.add_child(zombie)

		# 在区域内随机找位置，避免重叠
		var best_pos := Vector2(rng.randf_range(area_x_min, area_x_max), rng.randf_range(area_y_min, area_y_max))
		for _attempt in range(20):
			var candidate := Vector2(rng.randf_range(area_x_min, area_x_max), rng.randf_range(area_y_min, area_y_max))
			var too_close := false
			for p in placed_positions:
				if candidate.distance_to(p) < min_spacing:
					too_close = true
					break
			if not too_close:
				best_pos = candidate
				break

		zombie.global_position = best_pos
		placed_positions.append(best_pos)
		_preview_zombies.append(zombie)


func clear_preview_zombies() -> void:
	for z in _preview_zombies:
		if is_instance_valid(z):
			z.queue_free()
	_preview_zombies.clear()


# ===================== 游戏阶段：逐个刷新 =====================

func spawn_game_zombies() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	while _spawned_count < max_zombies:
		await get_tree().create_timer(spawn_interval).timeout

		var scene := _pick_random_scene()
		if scene == null:
			continue

		var zombie := scene.instantiate() as Zombie
		if zombie == null:
			continue

		get_tree().current_scene.add_child(zombie)

		# Y 随机选 5 条路径之一，X 固定 2000
		var lane_y := _lane_y_values[rng.randi() % _lane_y_values.size()]
		zombie.global_position = Vector2(spawn_x, lane_y)

		zombie.zombie_died.connect(_on_zombie_died)
		_spawned_count += 1


# ===================== 通用 =====================

func _pick_random_scene() -> PackedScene:
	if zombie_scenes.is_empty():
		return null

	var total_weight := 0
	for w in zombie_weights:
		total_weight += w
	if total_weight <= 0:
		return zombie_scenes[randi() % zombie_scenes.size()]

	var roll := randi() % total_weight
	var cumulative := 0
	for i in zombie_scenes.size():
		var w := zombie_weights[i] if i < zombie_weights.size() else 1
		cumulative += w
		if roll < cumulative:
			return zombie_scenes[i]

	return zombie_scenes[-1]


func _on_zombie_died() -> void:
	_killed_count += 1
	print("僵尸死亡: ", _killed_count, "/", max_zombies)
	if _killed_count >= max_zombies:
		all_zombies_defeated.emit()
