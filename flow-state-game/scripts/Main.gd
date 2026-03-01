extends Control

@onready var status_label: Label = $Playfield/CanvasLayer/Label
@onready var stability_bar: ProgressBar = $Playfield/CanvasLayer/ProgressBar
@onready var score_label: Label = $Playfield/CanvasLayer/ScoreLabel
@onready var breath = $Playfield/Breath
@onready var puzzle = $Playfield/Puzzle
@onready var water_mist: ColorRect = get_node_or_null("Playfield/MonetBackdrop/WaterMist") as ColorRect
@onready var lily_a: ColorRect = get_node_or_null("Playfield/MonetBackdrop/LilyLightA") as ColorRect
@onready var lily_b: ColorRect = get_node_or_null("Playfield/MonetBackdrop/LilyLightB") as ColorRect

var score := 0
var deco_time := 0.0
var water_mist_base_pos := Vector2.ZERO
var lily_a_base_pos := Vector2.ZERO
var lily_b_base_pos := Vector2.ZERO

func _ready():
	print("[主场景] 已就绪")
	status_label.modulate = Color(1, 1, 1, 1)
	puzzle.visible = false
	if water_mist != null:
		water_mist_base_pos = water_mist.position
	if lily_a != null:
		lily_a_base_pos = lily_a.position
	if lily_b != null:
		lily_b_base_pos = lily_b.position

	breath.stability_changed.connect(_on_stability_changed)
	breath.breath_ready.connect(_on_breath_ready)
	puzzle.puzzle_completed.connect(_on_puzzle_completed)
	puzzle.points_awarded.connect(_on_points_awarded)
	_update_score_label()


func _process(_delta: float) -> void:
	deco_time += _delta
	_animate_main_backdrop()

	if puzzle.visible:
		status_label.text = "心流拼图阶段"
		return

	var holding := Input.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE)
	status_label.text = "心流呼吸（空格：" + ("吸气" if holding else "呼气") + "）"

func _on_stability_changed(value: float):
	stability_bar.value = value

func _on_breath_ready(stability: float):
	breath.visible = false
	puzzle.visible = true
	puzzle.start_with_stability(stability)

func _on_puzzle_completed():
	_add_score(25)
	puzzle.visible = false
	breath.visible = true
	breath.reset_session()

func _on_points_awarded(points: int) -> void:
	_add_score(points)

func _add_score(points: int) -> void:
	score += points
	_update_score_label()

func _update_score_label() -> void:
	if score_label != null:
		score_label.text = "宁静点数：" + str(score)

func _animate_main_backdrop() -> void:
	if water_mist != null:
		water_mist.position = water_mist_base_pos + Vector2(sin(deco_time * 0.15) * 16.0, cos(deco_time * 0.20) * 4.0)
	if lily_a != null:
		lily_a.position = lily_a_base_pos + Vector2(cos(deco_time * 0.22) * 8.0, sin(deco_time * 0.18) * 2.0)
	if lily_b != null:
		lily_b.position = lily_b_base_pos + Vector2(sin(deco_time * 0.20 + 0.7) * 10.0, cos(deco_time * 0.16) * 2.5)
