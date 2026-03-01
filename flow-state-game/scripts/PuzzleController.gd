extends Node2D

signal puzzle_completed()

@onready var grid_root = $GridRoot
@onready var cursor = $Cursor
@onready var done_label = $DoneLabel

var grid_size := 6
var cell_size := 60
var cursor_pos := Vector2i(0, 0)
var targets := {}
var filled := {}

func start_with_stability(stability):
	done_label.visible = false
	filled.clear()
	targets.clear()
	cursor_pos = Vector2i(2, 2)

	_build_grid()

	var count = 5 + int(stability * 5)
	_generate_targets(count)
	_update_cursor()

func _process(_delta):
	var moved = false

	if Input.is_action_just_pressed("ui_left"):
		cursor_pos.x -= 1
		moved = true
	if Input.is_action_just_pressed("ui_right"):
		cursor_pos.x += 1
		moved = true
	if Input.is_action_just_pressed("ui_up"):
		cursor_pos.y -= 1
		moved = true
	if Input.is_action_just_pressed("ui_down"):
		cursor_pos.y += 1
		moved = true

	if moved:
		cursor_pos.x = clamp(cursor_pos.x, 0, grid_size - 1)
		cursor_pos.y = clamp(cursor_pos.y, 0, grid_size - 1)
		_update_cursor()
		_check_fill()

func _build_grid():
	for child in grid_root.get_children():
		child.queue_free()

	for y in range(grid_size):
		for x in range(grid_size):
			var cell = ColorRect.new()
			cell.size = Vector2(cell_size - 4, cell_size - 4)
			cell.position = Vector2(x * cell_size, y * cell_size)
			cell.color = Color(0.2, 0.2, 0.25)
			grid_root.add_child(cell)

func _generate_targets(count):
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	while targets.size() < count:
		var pos = Vector2i(rng.randi_range(0, grid_size - 1), rng.randi_range(0, grid_size - 1))
		targets[pos] = true

func _update_cursor():
	cursor.size = Vector2(cell_size - 10, cell_size - 10)
	cursor.position = Vector2(cursor_pos.x * cell_size + 5, cursor_pos.y * cell_size + 5)
	cursor.color = Color(0.8, 0.8, 1)

func _check_fill():
	if targets.has(cursor_pos):
		filled[cursor_pos] = true

	if filled.size() >= targets.size():
		done_label.visible = true
		emit_signal("puzzle_completed")
