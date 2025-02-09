extends Node3D

const character = preload("res://Models/character.gd")

enum WalkResult { SUCCESS, FALL, BOUNCE, FINISH }

@export var maze_data = null
@export var max_height = 20
@export var max_width = 40
@export var vertical_offset = 3
@export var gap_size = 0.4
@export var time_to_step = 1.0
@export var zoom_time = 1.0
@export var player_time_to_step = 1.0

@onready var up_image = preload("res://Arrows/UpArrow.png")
@onready var down_image = preload("res://Arrows/DownArrow.png")
@onready var right_image = preload("res://Arrows/RightArrow.png")
@onready var left_image = preload("res://Arrows/LeftArrow.png")
@onready var win_shader = preload("res://WinSquare.tres")
@onready var block_shader = preload("res://BlockSquare.tres")
@onready var party_horn = preload("res://Sounds/Party Horn - Sound Effect (HD).mp3")
@onready var bonk_sound = preload("res://Sounds/Bonk Sound Effect.mp3")

@onready var up_button = $Camera3D/HUD/Control/Up
@onready var down_button = $Camera3D/HUD/Control/Down
@onready var right_button = $Camera3D/HUD/Control/Right
@onready var left_button = $Camera3D/HUD/Control/Left
@onready var start_button = $Camera3D/HUD/BottomBox/Start
@onready var cancel_button = $Camera3D/HUD/RevertButton
@onready var camera = $Camera3D
@onready var win_text = $Camera3D/HUD/WinText
@onready var action_circle = $Camera3D/HUD/CurrentActionCircle
@onready var next_level_button = $Camera3D/HUD/NextLevelButton
@onready var level_pieces_parent = $LevelPiecesParent
@onready var confetti_sound_player = $ConfettiSoundEffectPlayer
@onready var bonk_player = $BonkSoundEffectPlayer

var is_running = false
var is_zooming = false
var time_zooming = 0.0
var time_stepping = 0.0
var is_zoom_win = false
var current_fall_velocity = 0.0

var level_bank = null

var player_inputs = []
var player_action_index = 0
var player_position = [0, 0]

@onready var player = $Character
@onready var hud = $Camera3D/HUD
@onready var control_row = $Camera3D/HUD/BottomBox/ShownControls

func _get_total_gap_size():
	var num_rows = maze_data.get_num_rows()
	return (num_rows - 1) * gap_size

func _get_cell_size():
	var num_rows = maze_data.get_num_rows()
	var total_gap_size = _get_total_gap_size()
	var working_size = max_height - total_gap_size
	var cell_height = working_size / num_rows
	return Vector3(cell_height, 0.2, cell_height)

func _get_grid_center():
	return Vector3(0, vertical_offset, 0)

func _get_grid_top_left():
	var center = _get_grid_center()
	var cell_size = _get_cell_size()
	cell_size.z = 0
	
	var num_cols = maze_data.get_num_cols()
	var desired_width = (num_cols * cell_size.x) + (num_cols-1) * gap_size
	
	var top_left = center - Vector3(desired_width / 2, 0, max_height / 2)
	cell_size.z = - cell_size.z
	top_left = top_left + (Vector3(cell_size) / 2)
	return top_left

func _get_cell_position_for_player(col:int, row:int):
	var pos = _get_cell_position(col, row)
	pos.y = pos.y + 0.5
	return pos
	
func _get_cell_position(col:int, row:int):
	var top_left_pos = _get_grid_top_left()
	var cell_size = _get_cell_size()
	return top_left_pos + Vector3(row*(cell_size.x + gap_size), -cell_size.y / 2, col*(cell_size.z + gap_size))

func _generate_maze():
	player_inputs = []
	for child in level_pieces_parent.get_children():
		child.queue_free()
	maze_data = level_bank.get_current_level()
	
	var rows = maze_data.get_num_rows()
	var cols = maze_data.get_num_cols()
	var cell_size = _get_cell_size()	
	for r in rows:
		var row = maze_data.cells[r]
		for c in cols:
			if c < len(row):
				var pos_data = maze_data.cells[r][c]
				if pos_data == 'x' or pos_data == '@' or pos_data == '!' or pos_data == 'B':
					var cell_box = CSGBox3D.new()
					cell_box.set_size(cell_size)
					level_pieces_parent.add_child(cell_box)
					var pos = _get_cell_position(r, c)
					cell_box.global_position = pos
					if pos_data == '!':
						var mat = ShaderMaterial.new()
						mat.shader = win_shader
						cell_box.material = mat
					if pos_data == 'B':
						var block_height = cell_size.x * 0.6
						cell_box.set_size(Vector3(cell_size.x, block_height, cell_size.z))
						cell_box.global_position += Vector3(0, block_height / 2, 0)
						var mat = ShaderMaterial.new()
						mat.shader = block_shader
						cell_box.material = mat

	_reset_player()

func _reset_player():
	var rows = maze_data.get_num_rows()
	var cols = maze_data.get_num_cols()
	var cell_size = _get_cell_size()
	for r in rows:
		var row = maze_data.cells[r]
		for c in cols:
			if c < len(row):
				var pos = _get_cell_position_for_player(r, c)
				var letter = row[c]
				if letter == '@':
					player.global_position = pos
					player_position = [r, c]
					var S = cell_size.x * 0.3
					player.scale = Vector3(S, S, S)
	player.set_walking(false)
	player.set_win(false)
	player.global_rotation.y = _rotation_from_direction(character.WalkDirection.DOWN)
	player_action_index = 0
	win_text.visible = false
	is_zoom_win = false
	current_fall_velocity = 0.0
	next_level_button.visible = false
	next_level_button.disabled = true
	party_sound_played = false
	bonk_played = false


func _loadMaze(new_maze_data:MazeData):
	self.maze_data = new_maze_data
	self._generate_maze()

func _add_input(direction: character.WalkDirection):
	if len(player_inputs) == 6:
		return
	player_inputs.append(direction)
	
func _add_up_input():
	_add_input(character.WalkDirection.UP)

func _add_down_input():
	_add_input(character.WalkDirection.DOWN)

func _add_right_input():
	_add_input(character.WalkDirection.RIGHT)

func _add_left_input():
	_add_input(character.WalkDirection.LEFT)

func _get_image_from_direction(direction: character.WalkDirection):
	if direction == character.WalkDirection.UP:
		return up_image
	if direction == character.WalkDirection.DOWN:
		return down_image
	if direction == character.WalkDirection.RIGHT:
		return right_image
	if direction == character.WalkDirection.LEFT:
		return left_image

func _update_shown_controls():
	for child in control_row.get_children():
		child.queue_free()
		
	for input in player_inputs:
		var new_item = TextureRect.new()
		new_item.texture = _get_image_from_direction(input)
		new_item.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		new_item.size = Vector2(150, 150)
		control_row.add_child(new_item)

func _next_level():
	level_bank.next_level()
	_return_to_planning()
	_generate_maze()

func _connect_buttons():
	up_button.pressed.connect(_add_up_input)
	down_button.pressed.connect(_add_down_input)
	right_button.pressed.connect(_add_right_input)
	left_button.pressed.connect(_add_left_input)
	start_button.pressed.connect(start)
	cancel_button.pressed.connect(_return_to_planning)
	next_level_button.pressed.connect(_next_level)

func _set_buttons_active(enabled:bool):
	up_button.disabled = not enabled
	down_button.disabled = not enabled
	right_button.disabled = not enabled
	left_button.disabled = not enabled


func start():
	if len(player_inputs) == 0:
		return
	_reset_player()
	_set_buttons_active(false)
	is_zooming = true
	time_zooming = 0.0
	time_stepping = 0.0
	is_running = true
	next_level_button.visible = false
	next_level_button.disabled = true

func _do_zoom(delta: float):
	var max_angle = PI / 8
	var zoom_prop = (time_zooming / zoom_time)
	var prop_time = zoom_prop * max_angle
	var radius = 20.0
	
	var desired_y = cos(PI/8) * radius
	var desired_z = sin(PI/8) * (radius + 10)
	var desired_pos = Vector3(0, desired_y, desired_z)

	var desired_global_rotation_x = (- PI/2) * (1-PI/8)

	var pos = lerp(camera.global_position, desired_pos, delta * 4)
	var ang = lerp_angle(camera.global_rotation.x, desired_global_rotation_x, delta * 4)
	camera.global_rotation.x = ang
	camera.global_position = pos
	time_zooming = time_zooming + delta
	if time_zooming > zoom_time:
		is_zooming = false

func _remove_last_input():
	if len(player_inputs) > 0:
		player_inputs.remove_at(len(player_inputs) - 1)

func _scan_inputs() -> void:
	if Input.is_action_just_pressed("delete_action"):
		_remove_last_input()

func _return_to_planning() -> void:
	if is_running:
		is_zooming = false
		is_running = false
		camera.global_position = Vector3(0, 20, 0)
		camera.global_rotation.x = -PI/2
		_reset_player()
		_set_buttons_active(true)
	else:
		_remove_last_input()

func _get_current_action():
	var ind = player_action_index % len(player_inputs)
	return player_inputs[ind]

func _get_next_position():
	var current_action = _get_current_action()
	var row = player_position[0]
	var col = player_position[1]
	var next_position = [row, col]
	if current_action == character.WalkDirection.UP:
		next_position[0] -= 1
	if current_action == character.WalkDirection.DOWN:
		next_position[0] += 1
	if current_action == character.WalkDirection.LEFT:
		next_position[1] -= 1
	if current_action == character.WalkDirection.RIGHT:
		next_position[1] += 1
	return next_position

func _get_position_result(next_position):
	var row = next_position[0]
	var col = next_position[1]
	
	if row < 0 or row >= len(maze_data.cells):
		return WalkResult.FALL
	var row_data = maze_data.cells[row]
	if col < 0 or col >= len(row_data):
		return WalkResult.FALL
	
	var position_data = maze_data.cells[row][col]
	if position_data == 'o':
		return WalkResult.FALL
	if position_data == 'x':
		return WalkResult.SUCCESS
	if position_data == '!':
		return WalkResult.FINISH
	if position_data == 'B':
		return WalkResult.BOUNCE
	
func _rotation_from_direction(direction:character.WalkDirection):
	if direction == character.WalkDirection.UP:
		return -PI
	if direction == character.WalkDirection.DOWN:
		return 0
	if direction == character.WalkDirection.RIGHT:
		return PI/2
	if direction == character.WalkDirection.LEFT:
		return -PI/2

func _current_rotation():
	var current_action = _get_current_action()
	return _rotation_from_direction(current_action)

var bonk_played = false
func _run_character(delta: float):
	var next_position = _get_next_position()
	var pos_result = _get_position_result(next_position)
	var current_result = _get_position_result(player_position)
	if current_result == WalkResult.FINISH:
		player.set_walking(false)
		player.set_win(true)
		is_zoom_win = true
		return
	
	var last_pos = _get_cell_position_for_player(player_position[0], player_position[1])
	var desired_pos = _get_cell_position_for_player(next_position[0], next_position[1])
	var player_pos = player.global_position
	var prop = time_stepping / time_to_step

	if prop > 0.75 and pos_result == WalkResult.FALL:
		current_fall_velocity += delta
		player.global_position -= Vector3(0, current_fall_velocity, 0)
		return
	if pos_result == WalkResult.BOUNCE:
		time_stepping += delta
		var desired_y = _current_rotation()
		var new_rot = lerp_angle(player.global_rotation.y, desired_y, delta * 10)
		player.global_rotation.y = new_rot
		if prop < 0.5:
			var new_pos = (1-prop) * last_pos + (prop)* desired_pos
			player.global_position = new_pos
		elif prop < 1.8:
			if prop > 1:
				prop = 1
			player.set_bounce(true)
			var new_pos = (prop) * last_pos + (1-prop)* desired_pos
			player.global_position = new_pos
			if not bonk_player.is_playing() and not bonk_played:
				bonk_player.stream = bonk_sound
				bonk_player.stream.loop = false
				bonk_player.play()
				bonk_played = true
		else:
			bonk_played = false
			player_action_index = (player_action_index + 1) % len(player_inputs)
			player.set_bounce(false)
			time_stepping = 0.0
		return
	if time_stepping < time_to_step:
		var new_pos = (1-prop)*last_pos + (prop)*desired_pos
		player.global_position = new_pos
		time_stepping += delta
		var player_rot_y = player.global_rotation.y
		var desired_y = _current_rotation()
		var new_rot = lerp_angle(player_rot_y, desired_y, delta * 10)
		player.global_rotation.y = new_rot
		player.set_walking(true)
	else:
		player_position = next_position
		time_stepping = 0
		player_action_index = (player_action_index + 1) % len(player_inputs)

var party_sound_played = false
func _do_win_zoom(delta: float):
	var scale = _get_cell_size().x
	var player_pos = player.global_position
	var desired_pos = player_pos + Vector3(0, scale, scale)
	var desired_rot = Vector3(-PI/6, 0, 0)
	
	var player_y = player.global_rotation.y
	var desired_y = 0
	var p_row = lerp_angle(player_y, desired_y, delta * 8)
	player.global_rotation.y = p_row
	
	var new_pos = lerp(camera.global_position, desired_pos, delta * 4)
	var new_rot = lerp_angle(camera.global_rotation.x, desired_rot.x, delta * 4)
	camera.global_position = new_pos
	camera.global_rotation.x = new_rot
	if (camera.global_position - desired_pos).length() < 1.0:
		win_text.visible = true
		next_level_button.visible = true
		next_level_button.disabled = false
		if not confetti_sound_player.is_playing() and not party_sound_played:
			confetti_sound_player.stream = party_horn
			confetti_sound_player.stream.loop = false
			confetti_sound_player.play()
			party_sound_played = true

func _highlight_command():
	if not is_running:
		action_circle.visible = false
	else:
		action_circle.visible = true
		var circle_rect = action_circle.get_global_rect()
		
		var cur_index = player_action_index
		var control_icon = control_row.get_children()[cur_index]
		var child_rect = control_icon.get_global_rect()
		
		var offset = (circle_rect.size.x - child_rect.size.x) / 2.0
		var new_pos = child_rect.position + Vector2(-offset, -offset)
		action_circle.set_global_position(new_pos)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level_bank = LevelBank.new()
	self._generate_maze()
	self._connect_buttons()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_update_shown_controls()
	_highlight_command()
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	if not is_running:
		_scan_inputs()
	else:
		if is_zooming:
			_do_zoom(delta)
		else:
			if is_zoom_win:
				_do_win_zoom(delta)
			else:
				_run_character(delta)
				if player.global_position.y < -50:
					_return_to_planning()
					
