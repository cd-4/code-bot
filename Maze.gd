extends Node
class_name MazeData

var cells = [
	"@xxxx",
	"xxxoo",
	"xxxBo",
	"oo!xx"
]
#var cells = [
#	"@xxxxxxx",
#	"xxxooxxx",
#	"xxxxooox",
#	"ooxxxxxx",
#	"ooo!xxoo"
#]


func get_num_cols() -> int:
	var cols = 0
	for row in cells:
		var row_len = len(row)
		if row_len > cols:
			cols = row_len
	return cols

func get_num_rows() -> int:
	return len(cells)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
