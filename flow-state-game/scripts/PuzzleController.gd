extends Node2D

signal puzzle_completed()
signal points_awarded(points: int)

@onready var grid_root = $GridRoot
@onready var cursor = $Cursor
@onready var done_label = $DoneLabel
@onready var instruction_label = $Label
@onready var backdrop: ColorRect = get_node_or_null("Backdrop") as ColorRect
@onready var water_shadow: ColorRect = get_node_or_null("WaterShadow") as ColorRect
@onready var char_kai: ColorRect = get_node_or_null("CharacterKai") as ColorRect
@onready var char_mio: ColorRect = get_node_or_null("CharacterMio") as ColorRect
@onready var char_zen: ColorRect = get_node_or_null("CharacterZen") as ColorRect

var grid_size := 6
var cell_size := 60
var cursor_pos := Vector2i(0, 0)
var targets := {}
var filled := {}
var is_completed := false
var cell_nodes := {}
var deco_time := 0.0
var character_bases := {}
var character_parts := {}
var backdrop_base_pos := Vector2.ZERO
var water_shadow_base_pos := Vector2.ZERO
const BASE_A := Color(0.57, 0.69, 0.71, 1.0)
const BASE_B := Color(0.62, 0.74, 0.75, 1.0)
const TARGET_COLOR := Color(0.68, 0.63, 0.79, 1.0)
const FILLED_COLOR := Color(0.62, 0.78, 0.60, 1.0)

func _ready() -> void:
	if backdrop != null:
		backdrop_base_pos = backdrop.position
	if water_shadow != null:
		water_shadow_base_pos = water_shadow.position

	_register_character(char_kai)
	_register_character(char_mio)
	_register_character(char_zen)

func start_with_stability(stability):
	done_label.visible = false
	done_label.text = "Completed! Team calm +1"
	if instruction_label != null:
		instruction_label.text = "Find all stars with arrow keys"
	filled.clear()
	targets.clear()
	cursor_pos = Vector2i(2, 2)
	is_completed = false

	_build_grid()

	var count = 5 + int(stability * 5)
	_generate_targets(count)
	_update_cursor()

func _process(_delta):
	if not visible:
		return

	deco_time += _delta
	_animate_background_drift()
	_animate_characters()
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
	cell_nodes.clear()

	for y in range(grid_size):
		for x in range(grid_size):
			var cell = ColorRect.new()
			cell.size = Vector2(cell_size - 4, cell_size - 4)
			cell.position = Vector2(x * cell_size, y * cell_size)
			cell.color = BASE_A if ((x + y) % 2 == 0) else BASE_B
			grid_root.add_child(cell)
			cell_nodes[Vector2i(x, y)] = cell

func _generate_targets(count):
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	while targets.size() < count:
		var pos = Vector2i(rng.randi_range(0, grid_size - 1), rng.randi_range(0, grid_size - 1))
		targets[pos] = true
	_refresh_grid_visuals()

func _update_cursor():
	cursor.size = Vector2(cell_size - 10, cell_size - 10)
	cursor.position = Vector2(cursor_pos.x * cell_size + 5, cursor_pos.y * cell_size + 5)
	cursor.color = Color(0.92, 0.95, 0.98, 0.82)

func _check_fill():
	if is_completed:
		return

	if targets.has(cursor_pos) and not filled.has(cursor_pos):
		filled[cursor_pos] = true
		emit_signal("points_awarded", 10)
		_refresh_grid_visuals()

	if filled.size() >= targets.size():
		is_completed = true
		done_label.visible = true
		_boost_characters()
		emit_signal("points_awarded", 50)
		emit_signal("puzzle_completed")

func _refresh_grid_visuals() -> void:
	for y in range(grid_size):
		for x in range(grid_size):
			var pos := Vector2i(x, y)
			var cell: ColorRect = cell_nodes.get(pos) as ColorRect
			if cell == null:
				continue
			if filled.has(pos):
				cell.color = FILLED_COLOR
			elif targets.has(pos):
				cell.color = TARGET_COLOR
			else:
				cell.color = BASE_A if ((x + y) % 2 == 0) else BASE_B

func _register_character(node: ColorRect) -> void:
	if node == null:
		return
	character_bases[node] = node.position
	var body := node.get_node_or_null("Body") as ColorRect
	var eye_l := node.get_node_or_null("EyeL") as ColorRect
	var eye_r := node.get_node_or_null("EyeR") as ColorRect
	character_parts[node] = {
		"body": body,
		"body_base_pos": body.position if body != null else Vector2.ZERO,
		"body_base_size": body.size if body != null else Vector2.ZERO,
		"eye_l": eye_l,
		"eye_l_base_pos": eye_l.position if eye_l != null else Vector2.ZERO,
		"eye_r": eye_r,
		"eye_r_base_pos": eye_r.position if eye_r != null else Vector2.ZERO
	}

func _animate_characters() -> void:
	var index := 0
	for node in character_bases.keys():
		var character := node as ColorRect
		if character == null:
			continue
		var base: Vector2 = character_bases[node]
		character.position = base + Vector2(0.0, sin(deco_time * 2.0 + float(index)) * 5.0)
		var pulse := 0.78 + 0.22 * (0.5 + 0.5 * sin(deco_time * 2.4 + float(index) * 0.7))
		character.color.a = pulse
		var frame := int(floor(fposmod(deco_time * 2.6 + float(index) * 0.5, 3.0)))
		_apply_pixel_idle_frame(character, frame)
		index += 1

func _boost_characters() -> void:
	for node in character_bases.keys():
		var character := node as ColorRect
		if character == null:
			continue
		character.color = character.color.lerp(Color(0.90, 0.93, 0.86, 0.95), 0.55)

func _animate_background_drift() -> void:
	if backdrop != null:
		backdrop.position = backdrop_base_pos + Vector2(sin(deco_time * 0.18) * 10.0, 0.0)
	if water_shadow != null:
		water_shadow.position = water_shadow_base_pos + Vector2(cos(deco_time * 0.22) * 14.0, sin(deco_time * 0.20) * 3.0)

func _apply_pixel_idle_frame(character: ColorRect, frame: int) -> void:
	var parts: Dictionary = character_parts.get(character, {})
	if parts.is_empty():
		return

	var body := parts.get("body") as ColorRect
	var body_base_pos: Vector2 = parts.get("body_base_pos", Vector2.ZERO)
	var body_base_size: Vector2 = parts.get("body_base_size", Vector2.ZERO)
	if body != null:
		if frame == 0:
			body.position = body_base_pos
			body.size = body_base_size
		elif frame == 1:
			body.position = body_base_pos + Vector2(0.0, -1.0)
			body.size = body_base_size + Vector2(0.0, 2.0)
		else:
			body.position = body_base_pos + Vector2(0.0, 1.0)
			body.size = body_base_size + Vector2(0.0, -1.0)

	_apply_eye_frame(parts.get("eye_l") as ColorRect, parts.get("eye_l_base_pos", Vector2.ZERO), frame == 2)
	_apply_eye_frame(parts.get("eye_r") as ColorRect, parts.get("eye_r_base_pos", Vector2.ZERO), frame == 2)

func _apply_eye_frame(eye: ColorRect, eye_base_pos: Vector2, blink: bool) -> void:
	if eye == null:
		return
	if blink:
		eye.position = eye_base_pos + Vector2(0.0, 1.0)
		eye.size = Vector2(eye.size.x, 1.0)
	else:
		eye.position = eye_base_pos
		eye.size = Vector2(eye.size.x, 4.0)
