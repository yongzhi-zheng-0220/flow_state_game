extends Control

signal stability_changed(value: float)
signal breath_ready(stability: float)

@onready var bg: ColorRect = get_node_or_null("ColorRect") as ColorRect
@onready var fog_layer: ColorRect = get_node_or_null("FogLayer") as ColorRect
@onready var lily_glow: ColorRect = get_node_or_null("LilyGlow") as ColorRect
@onready var guide_label: Label = get_node_or_null("Label") as Label
@onready var phase_bar: ProgressBar = get_node_or_null("PhaseBar") as ProgressBar
@onready var guide_spirit: ColorRect = get_node_or_null("GuideSpirit") as ColorRect
@onready var companion_spirit: ColorRect = get_node_or_null("CompanionSpirit") as ColorRect

@onready var guide_eye_l: ColorRect = get_node_or_null("GuideSpirit/EyeL") as ColorRect
@onready var guide_eye_r: ColorRect = get_node_or_null("GuideSpirit/EyeR") as ColorRect
@onready var guide_body: ColorRect = get_node_or_null("GuideSpirit/BodyPixel") as ColorRect
@onready var companion_eye_l: ColorRect = get_node_or_null("CompanionSpirit/EyeL") as ColorRect
@onready var companion_eye_r: ColorRect = get_node_or_null("CompanionSpirit/EyeR") as ColorRect
@onready var companion_body: ColorRect = get_node_or_null("CompanionSpirit/BodyPixel") as ColorRect

var target_inhale := 4.0
var target_exhale := 6.0
const STEP := 0.5
const MIN_INHALE := 2.0
const MAX_INHALE := 8.0
const MIN_EXHALE := 2.0
const MAX_EXHALE := 10.0

var holding := false
var phase_time := 0.0
var stability := 0.0
var stable_time := 0.0
var ready_emitted := false  # 防止 breath_ready 连续触发
var deco_time := 0.0
var guide_base_pos := Vector2.ZERO
var companion_base_pos := Vector2.ZERO
var fog_base_pos := Vector2.ZERO
var lily_base_pos := Vector2.ZERO
var guide_body_base_pos := Vector2.ZERO
var guide_body_base_size := Vector2.ZERO
var companion_body_base_pos := Vector2.ZERO
var companion_body_base_size := Vector2.ZERO
var guide_eye_l_base_pos := Vector2.ZERO
var guide_eye_r_base_pos := Vector2.ZERO
var companion_eye_l_base_pos := Vector2.ZERO
var companion_eye_r_base_pos := Vector2.ZERO

func _ready() -> void:
	if guide_spirit != null:
		guide_base_pos = guide_spirit.position
	if companion_spirit != null:
		companion_base_pos = companion_spirit.position
	if fog_layer != null:
		fog_base_pos = fog_layer.position
	if lily_glow != null:
		lily_base_pos = lily_glow.position
	if guide_body != null:
		guide_body_base_pos = guide_body.position
		guide_body_base_size = guide_body.size
	if companion_body != null:
		companion_body_base_pos = companion_body.position
		companion_body_base_size = companion_body.size
	if guide_eye_l != null:
		guide_eye_l_base_pos = guide_eye_l.position
	if guide_eye_r != null:
		guide_eye_r_base_pos = guide_eye_r.position
	if companion_eye_l != null:
		companion_eye_l_base_pos = companion_eye_l.position
	if companion_eye_r != null:
		companion_eye_r_base_pos = companion_eye_r.position

func _process(delta: float) -> void:
	if not visible:
		return

	deco_time += delta
	_handle_breath_tuning_input()

	var now_holding := Input.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE)

	if bg == null:
		push_error("[BreathController] 未找到子节点 'ColorRect'。请确认 Breath 场景根节点下存在名为 ColorRect 的 ColorRect 节点。")
		set_process(false)
		return

	# 呼吸ガイド表示（吸う/吐く）と進捗バー
	var phase_target: float = target_inhale if now_holding else target_exhale
	var progress: float = clamp(phase_time / max(phase_target, 0.001), 0.0, 1.0)
	var remain: float = max(phase_target - phase_time, 0.0)
	if guide_label != null:
		guide_label.text = ("吸う" if now_holding else "吐く") + "  残り " + String.num(remain, 1) + " 秒" + "  安定度 " + String.num(stability, 2) + "  (I " + String.num(target_inhale, 1) + " / E " + String.num(target_exhale, 1) + ")"
	if phase_bar != null:
		phase_bar.value = progress

	# 立即可见的反馈：按住 Space 立刻变亮（不依赖稳定度计算）
	var base_dark := Color(0.54, 0.64, 0.68, 1.0)
	var base_light := Color(0.66, 0.76, 0.78, 1.0)
	var target := base_light if now_holding else base_dark
	# 随稳定度进一步提亮，让玩家逐渐感到“进入状态”
	target = target.lerp(Color(0.79, 0.83, 0.74, 1.0), clamp(stability, 0.0, 1.0))
	bg.color = bg.color.lerp(target, 0.12)
	_animate_characters(now_holding)

	# 调试：只在按下瞬间打印（不刷屏）
	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		print("[Breath] Space pressed")

	phase_time += delta

	# 呼吸相位切换（按下/松开）
	if now_holding != holding:
		_evaluate_phase(phase_time, holding)
		holding = now_holding
		phase_time = 0.0
		if phase_bar != null:
			phase_bar.value = 0.0

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

func _handle_breath_tuning_input() -> void:
	if Input.is_action_just_pressed("ui_up"):
		target_inhale = clamp(target_inhale + STEP, MIN_INHALE, MAX_INHALE)
	if Input.is_action_just_pressed("ui_down"):
		target_inhale = clamp(target_inhale - STEP, MIN_INHALE, MAX_INHALE)
	if Input.is_action_just_pressed("ui_right"):
		target_exhale = clamp(target_exhale + STEP, MIN_EXHALE, MAX_EXHALE)
	if Input.is_action_just_pressed("ui_left"):
		target_exhale = clamp(target_exhale - STEP, MIN_EXHALE, MAX_EXHALE)

func _animate_characters(now_holding: bool) -> void:
	_animate_background_drift()

	if guide_spirit != null:
		guide_spirit.position = guide_base_pos + Vector2(0.0, sin(deco_time * 1.6) * 6.0)
		var guide_target := Color(0.39, 0.62, 0.74, 0.88)
		if now_holding:
			guide_target = Color(0.52, 0.72, 0.80, 0.95)
		guide_target = guide_target.lerp(Color(0.82, 0.86, 0.78, 1.0), clamp(stability, 0.0, 1.0))
		guide_spirit.color = guide_spirit.color.lerp(guide_target, 0.12)
		_apply_pixel_breath_frame(guide_body, guide_body_base_pos, guide_body_base_size, guide_eye_l, guide_eye_l_base_pos, guide_eye_r, guide_eye_r_base_pos, int(floor(fposmod(deco_time * 3.0, 3.0))))
	if companion_spirit != null:
		companion_spirit.position = companion_base_pos + Vector2(0.0, cos(deco_time * 1.9) * 4.0)
		var companion_target := Color(0.73, 0.57, 0.64, 0.72)
		if now_holding:
			companion_target = Color(0.80, 0.64, 0.68, 0.85)
		companion_spirit.color = companion_spirit.color.lerp(companion_target, 0.10)
		_apply_pixel_breath_frame(companion_body, companion_body_base_pos, companion_body_base_size, companion_eye_l, companion_eye_l_base_pos, companion_eye_r, companion_eye_r_base_pos, int(floor(fposmod(deco_time * 2.7 + 1.0, 3.0))))

func _animate_background_drift() -> void:
	if fog_layer != null:
		fog_layer.position = fog_base_pos + Vector2(sin(deco_time * 0.22) * 18.0, cos(deco_time * 0.18) * 4.0)
	if lily_glow != null:
		lily_glow.position = lily_base_pos + Vector2(cos(deco_time * 0.26) * 12.0, sin(deco_time * 0.21) * 3.0)

func _apply_pixel_breath_frame(body: ColorRect, body_base_pos: Vector2, body_base_size: Vector2, eye_l: ColorRect, eye_l_base_pos: Vector2, eye_r: ColorRect, eye_r_base_pos: Vector2, frame: int) -> void:
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

	_apply_pixel_eye_frame(eye_l, eye_l_base_pos, frame == 2)
	_apply_pixel_eye_frame(eye_r, eye_r_base_pos, frame == 2)

func _apply_pixel_eye_frame(eye: ColorRect, eye_base_pos: Vector2, blink: bool) -> void:
	if eye == null:
		return
	if blink:
		eye.position = eye_base_pos + Vector2(0.0, 1.0)
		eye.size = Vector2(eye.size.x, 1.0)
	else:
		eye.position = eye_base_pos
		eye.size = Vector2(eye.size.x, 4.0)

func reset_session() -> void:
	stability = 0.0
	stable_time = 0.0
	phase_time = 0.0
	holding = false
	ready_emitted = false
	emit_signal("stability_changed", stability)
	if guide_label != null:
		guide_label.text = "呼吸ガイド"
	if phase_bar != null:
		phase_bar.value = 0.0
