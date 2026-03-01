extends Control

@onready var status_label: Label = $CanvasLayer/Label
@onready var stability_bar: ProgressBar = $CanvasLayer/ProgressBar
@onready var breath = $Breath
@onready var puzzle = $Puzzle

func _ready():
	print("[Main] ready")
	status_label.modulate = Color(1, 1, 1, 1)
	puzzle.visible = false

	breath.stability_changed.connect(_on_stability_changed)
	breath.breath_ready.connect(_on_breath_ready)


func _process(_delta: float) -> void:
	var holding := Input.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE)
	status_label.text = "Breathing... (Space: " + ("ON" if holding else "OFF") + ")"

func _on_stability_changed(value: float):
	stability_bar.value = value

func _on_breath_ready(stability: float):
	breath.visible = false
	puzzle.visible = true
	puzzle.start_with_stability(stability)
	puzzle.puzzle_completed.connect(_on_puzzle_completed)

func _on_puzzle_completed():
	puzzle.visible = false
	breath.visible = true
	breath.reset_session()
