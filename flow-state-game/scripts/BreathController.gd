extends Control

signal stability_changed(value: float)
signal breath_ready(stability: float)

@onready var bg: ColorRect = get_node_or_null("ColorRect") as ColorRect

var target_inhale := 4.0
var target_exhale := 6.0

var holding := false
var phase_time := 0.0
var stability := 0.0
var stable_time := 0.0
var ready_emitted := false  # 防止 breath_ready 连续触发

func _process(delta: float) -> void:
	var now_holding := Input.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE)

	if bg == null:
		push_error("[BreathController] 未找到子节点 'ColorRect'。请确认 Breath 场景根节点下存在名为 ColorRect 的 ColorRect 节点。")
		set_process(false)
		return

	# 立即可见的反馈：按住 Space 立刻变亮（不依赖稳定度计算）
	var base_dark := Color(0.05, 0.06, 0.08, 1.0)
	var base_light := Color(0.18, 0.20, 0.28, 1.0)
	var target := base_light if now_holding else base_dark
	# 随稳定度进一步提亮，让玩家逐渐感到“进入状态”
	target = target.lerp(Color(0.45, 0.50, 0.75, 1.0), clamp(stability, 0.0, 1.0))
	bg.color = bg.color.lerp(target, 0.12)

	# 调试：只在按下瞬间打印（不刷屏）
	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		print("[Breath] Space pressed")

	phase_time += delta

	# 呼吸相位切换（按下/松开）
	if now_holding != holding:
		_evaluate_phase(phase_time, holding)
		holding = now_holding
		phase_time = 0.0

	emit_signal("stability_changed", stability)

	# 稳定度累计
	if stability > 0.7:
		stable_time += delta
	else:
		stable_time = 0.0
		ready_emitted = false

	# 达标触发一次进入 Puzzle
	if stable_time > 8.0 and not ready_emitted:
		ready_emitted = true
		emit_signal("breath_ready", stability)

func _evaluate_phase(duration: float, was_holding: bool) -> void:
	var target: float = target_inhale if was_holding else target_exhale
	var err_ratio: float = abs(duration - target) / target
	var score: float = 1.0 - clamp(err_ratio, 0.0, 1.0)

	stability = lerp(stability, score, 0.2)

func reset_session() -> void:
	stability = 0.0
	stable_time = 0.0
	phase_time = 0.0
	holding = false
	ready_emitted = false
	emit_signal("stability_changed", stability)
