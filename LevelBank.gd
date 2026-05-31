extends Node

class_name LevelBank

const LEVELS = [
	# Level 1
	["ooo", "@x!", "ooo"],
	# Level 2
	["oo", "@x", "x!"],
	# Level 3
	["oooooooo", "oooooooo", "o@xxxx!o", "oooooooo", "oooooooo"],
	# Level 4
	["@xoo", "oxBo", "o!oo", "oooo"],
	# Level 5
	["@xxx", "xxxx", "xxxx", "xxxx", "xxx!"],
	# Level 6
	["@xBo", "oxBoo", "oxxxx", "BoxBo", "xoxxo", "oooxB", "oBo!o"],
	# Level 7
	["o@ooo", "BxxxB", "oBBxo", "o!xxo"],
]

var level_index = 0

func get_current_level():
	var maze = MazeData.new()
	maze.cells = LEVELS[level_index % len(LEVELS)]
	return maze

func next_level():
	level_index = level_index + 1

func _process(_delta: float) -> void:
	pass
