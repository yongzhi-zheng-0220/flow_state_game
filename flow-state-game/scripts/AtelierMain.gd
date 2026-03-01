extends Control

enum BreathMode {
	FREE,
	GUIDED
}

const MIN_INHALE: float = 2.0
const MAX_INHALE: float = 8.0
const MIN_EXHALE: float = 2.0
const MAX_EXHALE: float = 10.0
const STEP: float = 0.5

const LAYER_COUNT: int = 5
var layer_names: Array[String] = [
	"水域层",
	"莲花层",
	"光影层",
	"雕塑层",
	"角色互动层"
]
var layer_costs: Array[float] = [30.0, 45.0, 65.0, 85.0, 110.0]

@onready var calm_energy_label: Label = $Playfield/CalmPanel/CalmEnergyLabel
@onready var mode_label: Label = $Playfield/CalmPanel/ModeLabel
@onready var toggle_mode_button: Button = $Playfield/CalmPanel/ToggleModeButton
@onready var end_session_button: Button = $Playfield/CalmPanel/EndSessionButton

@onready var breath_phase_label: Label = $Playfield/BreathPanel/BreathPhaseLabel
@onready var breath_bar: ProgressBar = $Playfield/BreathPanel/BreathBar
@onready var breath_feedback_label: Label = $Playfield/BreathPanel/BreathFeedbackLabel
@onready var breath_params_label: Label = $Playfield/BreathPanel/BreathParamsLabel

@onready var growth_label: Label = $Playfield/GardenPanel/GrowthLabel
@onready var atmosphere_label: Label = $Playfield/GardenPanel/AtmosphereLabel

@onready var water_status: Label = $Playfield/GardenPanel/LayerRows/WaterRow/Status
@onready var lotus_status: Label = $Playfield/GardenPanel/LayerRows/LotusRow/Status
@onready var light_status: Label = $Playfield/GardenPanel/LayerRows/LightRow/Status
@onready var sculpture_status: Label = $Playfield/GardenPanel/LayerRows/SculptureRow/Status
@onready var companion_status: Label = $Playfield/GardenPanel/LayerRows/CompanionRow/Status

@onready var water_button: Button = $Playfield/GardenPanel/LayerRows/WaterRow/Action
@onready var lotus_button: Button = $Playfield/GardenPanel/LayerRows/LotusRow/Action
@onready var light_button: Button = $Playfield/GardenPanel/LayerRows/LightRow/Action
@onready var sculpture_button: Button = $Playfield/GardenPanel/LayerRows/SculptureRow/Action
@onready var companion_button: Button = $Playfield/GardenPanel/LayerRows/CompanionRow/Action

@onready var water_visual: CanvasItem = $Playfield/GardenPanel/GardenPreview/WaterVisual
@onready var lotus_visual: CanvasItem = $Playfield/GardenPanel/GardenPreview/LotusVisual
@onready var light_visual: CanvasItem = $Playfield/GardenPanel/GardenPreview/LightVisual
@onready var sculpture_visual: CanvasItem = $Playfield/GardenPanel/GardenPreview/SculptureVisual
@onready var companion_visual: CanvasItem = $Playfield/GardenPanel/GardenPreview/CompanionVisual

@onready var summary_panel: ColorRect = $Playfield/SummaryPanel
@onready var summary_body: Label = $Playfield/SummaryPanel/SummaryBody
@onready var close_summary_button: Button = $Playfield/SummaryPanel/CloseSummaryButton

var mode: BreathMode = BreathMode.FREE
var guided_unlocked: bool = false

var calm_energy: float = 16.0
var target_inhale: float = 4.0
var target_exhale: float = 6.0
var holding: bool = false
var phase_time: float = 0.0
var stability: float = 0.55

var session_time: float = 0.0
var stability_integral: float = 0.0
var stable_streak: float = 0.0
var longest_streak: float = 0.0
var session_growth: float = 0.0

var feedback_timer: float = 0.0
var feedback_text: String = "心流平稳…"

var layer_unlocked: Array[bool] = []
var layer_status_labels: Array[Label] = []
var layer_buttons: Array[Button] = []
var layer_visuals: Array[CanvasItem] = []

func _ready() -> void:
	layer_unlocked.clear()
	for i: int in range(LAYER_COUNT):
		layer_unlocked.append(false)
	layer_status_labels = [water_status, lotus_status, light_status, sculpture_status, companion_status]
	layer_buttons = [water_button, lotus_button, light_button, sculpture_button, companion_button]
	layer_visuals = [water_visual, lotus_visual, light_visual, sculpture_visual, companion_visual]

	for i: int in range(LAYER_COUNT):
		layer_visuals[i].visible = false

	toggle_mode_button.pressed.connect(_on_toggle_mode_pressed)
	end_session_button.pressed.connect(_on_end_session_pressed)
	close_summary_button.pressed.connect(_on_close_summary_pressed)

	for i: int in range(LAYER_COUNT):
		var idx: int = i
		layer_buttons[i].pressed.connect(func() -> void:
			_on_layer_action_pressed(idx)
		)

	summary_panel.visible = false
	_refresh_layer_ui()
	_refresh_hud()
	_set_feedback("心流平稳…")

func _process(delta: float) -> void:
	if summary_panel.visible:
		return

	session_time += delta
	stability_integral += stability * delta
	_update_breath_cycle(delta)
	_update_streak(delta)

	if feedback_timer > 0.0:
		feedback_timer = maxf(feedback_timer - delta, 0.0)
		if feedback_timer == 0.0:
			_set_feedback("心流平稳…", 0.0)

	_refresh_hud()

func _update_breath_cycle(delta: float) -> void:
	_handle_breath_tuning_input()

	var now_holding: bool = Input.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE)
	if now_holding != holding:
		_evaluate_phase(phase_time, holding)
		phase_time = 0.0
		holding = now_holding

	phase_time += delta

	var phase_target: float = target_inhale if holding else target_exhale
	var remain: float = maxf(phase_target - phase_time, 0.0)
	var phase_name: String = "吸气" if holding else "呼气"

	breath_bar.value = clampf(phase_time / maxf(phase_target, 0.001), 0.0, 1.0)
	breath_phase_label.text = "%s  %.1f秒" % [phase_name, remain]
	breath_params_label.text = "目标（吸 %.1f / 呼 %.1f）| 稳定度 %.2f" % [target_inhale, target_exhale, stability]

func _evaluate_phase(duration: float, was_holding: bool) -> void:
	if duration < 0.2:
		return

	var target: float = target_inhale if was_holding else target_exhale
	var score: float = _phase_score(duration, target)
	var gain: float = _phase_gain(score)

	stability = lerpf(stability, score, 0.28)
	calm_energy += gain

	if mode == BreathMode.GUIDED:
		if score < 0.55:
			_set_feedback("心流飘移中…")
		elif score > 0.88:
			_set_feedback("心流已对齐。")
		else:
			_set_feedback("心流渐稳。")
	else:
		if score > 0.82:
			_set_feedback("宁静能量在生长。")
		else:
			_set_feedback("心流飘移中…")

func _phase_score(duration: float, target: float) -> float:
	var err_ratio: float = absf(duration - target) / maxf(target, 0.001)

	if mode == BreathMode.FREE:
		var soft: float = 1.0 - clampf(err_ratio * 0.6, 0.0, 1.0)
		return clampf(0.62 + soft * 0.30, 0.0, 1.0)

	var precise: float = 1.0 - clampf(err_ratio, 0.0, 1.0)
	var zone_bonus: float = 0.14 if err_ratio <= 0.15 else 0.0
	return clampf(precise + zone_bonus, 0.0, 1.0)

func _phase_gain(score: float) -> float:
	var base: float = 2.8 if mode == BreathMode.FREE else 4.6
	var stability_factor: float = 0.55 + stability * 0.65
	return base * (0.45 + score * 0.75) * stability_factor

func _update_streak(delta: float) -> void:
	if stability >= 0.74:
		stable_streak += delta
		longest_streak = maxf(longest_streak, stable_streak)
	else:
		stable_streak = maxf(stable_streak - delta * 0.7, 0.0)

func _handle_breath_tuning_input() -> void:
	if Input.is_action_just_pressed("ui_up"):
		target_inhale = clampf(target_inhale + STEP, MIN_INHALE, MAX_INHALE)
	if Input.is_action_just_pressed("ui_down"):
		target_inhale = clampf(target_inhale - STEP, MIN_INHALE, MAX_INHALE)
	if Input.is_action_just_pressed("ui_right"):
		target_exhale = clampf(target_exhale + STEP, MIN_EXHALE, MAX_EXHALE)
	if Input.is_action_just_pressed("ui_left"):
		target_exhale = clampf(target_exhale - STEP, MIN_EXHALE, MAX_EXHALE)

func _on_toggle_mode_pressed() -> void:
	if not guided_unlocked:
		_set_feedback("先修复水域层，才能解锁引导节律。")
		return

	mode = BreathMode.GUIDED if mode == BreathMode.FREE else BreathMode.FREE
	_set_feedback("模式已切换：%s。" % _mode_name())
	_refresh_hud()

func _on_layer_action_pressed(index: int) -> void:
	if index < 0 or index >= LAYER_COUNT:
		return
	if layer_unlocked[index]:
		return

	var cost: float = layer_costs[index]
	if calm_energy + 0.001 < cost:
		_set_feedback("心流飘移中…继续呼吸以积累宁静能量。")
		return

	calm_energy -= cost
	layer_unlocked[index] = true
	layer_visuals[index].visible = true
	session_growth += 20.0

	if index == 0:
		guided_unlocked = true
		_set_feedback("水域已苏醒，引导节律已解锁。")
	else:
		_set_feedback("已修复：%s。" % layer_names[index])

	_refresh_layer_ui()
	_refresh_hud()

func _refresh_layer_ui() -> void:
	for i: int in range(LAYER_COUNT):
		if layer_unlocked[i]:
			layer_status_labels[i].text = "已修复"
			layer_buttons[i].text = "已完成"
			layer_buttons[i].disabled = true
		else:
			layer_status_labels[i].text = "需要 %.0f 宁静能量" % [layer_costs[i]]
			layer_buttons[i].text = "修复"
			layer_buttons[i].disabled = false

func _refresh_hud() -> void:
	calm_energy_label.text = "宁静能量：%.1f" % calm_energy
	mode_label.text = "模式：%s" % _mode_name()
	toggle_mode_button.text = "切换到%s" % ("引导节律" if mode == BreathMode.FREE else "自由节律")
	toggle_mode_button.disabled = not guided_unlocked
	breath_feedback_label.text = feedback_text

	var growth_total: float = _total_growth_percent()
	growth_label.text = "花园成长：%.0f%%" % growth_total
	atmosphere_label.text = _atmosphere_text()

func _mode_name() -> String:
	if mode == BreathMode.GUIDED:
		return "引导节律"
	return "自由节律"

func _atmosphere_text() -> String:
	var unlocked_count: int = _unlocked_count()
	if unlocked_count <= 1:
		return "氛围：静水初醒"
	if unlocked_count == 2:
		return "氛围：花瓣苏醒"
	if unlocked_count == 3:
		return "氛围：光影入画"
	if unlocked_count == 4:
		return "氛围：形体与风共舞"
	return "氛围：花园与同伴皆已苏生"

func _set_feedback(text: String, hold_time: float = 1.4) -> void:
	feedback_text = text
	feedback_timer = hold_time

func _on_end_session_pressed() -> void:
	var avg_stability: float = stability_integral / maxf(session_time, 0.001)
	var growth_total: float = _total_growth_percent()
	var summary_text: String = ""
	summary_text += "今日平均稳定度: %.2f\n" % avg_stability
	summary_text += "最长连续稳定时间: %.1f 秒\n" % longest_streak
	summary_text += "今日花园恢复: %.0f%%\n" % session_growth
	summary_text += "累计花园成长指数: %.0f%%\n\n" % growth_total
	summary_text += "心流备注：%s" % ("心流已对齐。" if avg_stability >= 0.75 else "心流飘移中…")
	summary_body.text = summary_text
	summary_panel.visible = true

func _on_close_summary_pressed() -> void:
	summary_panel.visible = false
	_reset_session_metrics()

func _reset_session_metrics() -> void:
	session_time = 0.0
	stability_integral = 0.0
	stable_streak = 0.0
	longest_streak = 0.0
	session_growth = 0.0
	_set_feedback("新的宁静练习开始了。")

func _unlocked_count() -> int:
	var count: int = 0
	for i: int in range(layer_unlocked.size()):
		if layer_unlocked[i]:
			count += 1
	return count

func _total_growth_percent() -> float:
	return float(_unlocked_count()) * 20.0
