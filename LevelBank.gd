extends Node

class_name LevelBank

var levels = [
	# Level 0
	[
		"ooo",
		"@x!",
		"ooo",],
	# Level 1
	[
		"oo",
		"@x",
		"x!"],
	# Level 2
	[
		"oooooooo",
		"oooooooo",
		"o@xxxx!o",
		"oooooooo",
		"oooooooo"],
	# Level 3
	[
		"@xxx",
		"xxxx",
		"xxxx",
		"xxx!"
	],
	# Level 4
	[
		"@xxx",
		"xxxx",
		"xxxx",
		"xxxx",
		"xxx!"
	],
	# Level 5
	[
		"@xoo",
		"oxBo",
		"o!oo",
		"oooo"],
	# Level 6
	[
		"o@ooo",
		"BxxxB",
		"oBBxo",
		"o!xxo",
	]
]

var level_index = 0

func get_level_data():
	return levels[level_index % len(levels)]

func get_current_level():
	var level_data = get_level_data()
	var maze = MazeData.new()
	maze.cells = level_data
	return maze

func next_level():
	level_index = level_index + 1


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#levels = _create_levels()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
