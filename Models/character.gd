extends Node3D

enum WalkDirection { UP, DOWN, LEFT, RIGHT }

@onready var anim_tree = $"3DGodotRobot/AnimationTree"

var walking = false
var did_win = false

func set_bounce(is_bouncing:bool):
	anim_tree.bounce = is_bouncing

func set_win(win:bool):
	anim_tree.did_win = win

func set_walking(is_walking:bool):
	walking = is_walking

func _update_animations(delta: float):
	if walking:
		anim_tree.set("parameters/MoveBlendSpace/blend_position", 0.5)
	else:
		anim_tree.set("parameters/MoveBlendSpace/blend_position", 0)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_update_animations(delta)
	pass
