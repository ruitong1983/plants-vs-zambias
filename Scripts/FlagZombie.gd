# 旗帜僵尸，继承自基础僵尸，血量200，移动速度更快
extends Zombie

func _ready():
	MaxHealth = 200
	Speed = 60.0
	super._ready()
