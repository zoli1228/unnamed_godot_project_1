extends Node

## This is an example of a module. You can add as many modules as you want with their own unique functionality. At the moment each module
## must have an "update(...)" function, and this function is called from the player's process().
## This module for example could add headbobbing, without placing any dependancy in the player's core script.

var player : RigidBody3D = null

func _ready() -> void:
	player = get_owner().get_child(0)
	print(player)

func update(_delta: float) -> void:
	pass
