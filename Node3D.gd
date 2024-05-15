extends Node3D

@onready var player = $".."
@onready var node_3d = $"."

var ammo = 10

func _input(event):
	if player.is_action_just_pressed("ui_character_mouse_0"):
		ammo =- 1
		print(ammo)
