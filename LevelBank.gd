extends Node

class_name LevelBank

var levels = []
var level_index = 0

func _init():
	_load_levels()

func _load_levels():
	var i = 1
	while true:
		var path = "res://Levels/level_%d.txt" % i
		if not FileAccess.file_exists(path):
			break
		var file = FileAccess.open(path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		var cells = []
		for line in content.split("\n"):
			var row = line.strip_edges()
			if row != "":
				cells.append(row)
		levels.append(cells)
		i += 1

func get_level_data():
	if levels.is_empty():
		push_error("LevelBank: no level files found in res://Levels/")
		return []
	return levels[level_index % len(levels)]

func get_current_level():
	var level_data = get_level_data()
	var maze = MazeData.new()
	maze.cells = level_data
	return maze

func next_level():
	level_index = level_index + 1

func _process(_delta: float) -> void:
	pass
