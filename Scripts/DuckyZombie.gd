# 鸭子僵尸，继承自基础僵尸，血量250
extends Zombie

func _ready():
	MaxHealth = 250
	super._ready()
