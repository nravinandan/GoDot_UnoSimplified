# Player.gd - Player Class

extends Node

class_name Player
var Playername
var uid            # unique identifier for player
var hand = []      
	
func _init(name = "XYZ", uid = 0):
	self.Playername = name
	self.uid = uid
