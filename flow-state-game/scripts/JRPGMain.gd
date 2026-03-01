extends Control

enum BattleState {
	PLAYER_BREATH,
	ENEMY_TURN,
	VICTORY,
	DEFEAT
}

const MIN_INHALE: float = 2.0
const MAX_INHALE: float = 8.0
const MIN_EXHALE: float = 2.0
const MAX_EXHALE: float = 10.0
const STEP: float = 0.5
const PHASES_PER_ATTACK: int = 6

@onready var turn_label: Label = $BattleWindow/TurnLabel
@onready var player_hp_label: Label = $BattleWindow/PlayerHPLabel
@onready var enemy_hp_label: Label = $BattleWindow/EnemyHPLabel
@onready var breath_bar: ProgressBar = $BattleWindow/BreathBar
@onready var breath_label: Label = $BattleWindow/BreathLabel
@onready var log_label: Label = $BattleWindow/LogLabel
@onready var hint_label: Label = $BattleWindow/HintLabel
@onready var hero: ColorRect = $BattleWindow/Hero
@onready var enemy: ColorRect = $BattleWindow/Enemy

var state: BattleState = BattleState.PLAYER_BREATH
var state_timer: float = 0.0
var turn_index: int = 1

var player_hp: int = 140
var enemy_hp: int = 220

var target_inhale: float = 4.0
var target_exhale: float = 6.0
var enemy_weak_inhale: float = 4.5
var enemy_weak_exhale: float = 5.5

var holding: bool = false
var phase_time: float = 0.0
var phase_scores: Array[float] = []
var phase_switches: int = 0
var stability: float = 0.0

var battle_time: float = 0.0
var hero_base_pos: Vector2 = Vector2.ZERO
var enemy_base_pos: Vector2 = Vector2.ZERO
var enemy_flash: float = 0.0

func _ready() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	enemy_weak_inhale = rng.randf_range(3.5, 6.5)
	enemy_weak_exhale = rng.randf_range(4.5, 7.5)

	hero_base_pos = hero.position
	enemy_base_pos = enemy.position
	_start_player_turn()

func _process(delta: float) -> void:
	battle_time += delta
	_update_visuals(delta)
	_update_hud()

	match state:
		BattleState.PLAYER_BREATH:
			_process_player_breath(delta)
		BattleState.ENEMY_TURN:
			_process_enemy_timer(delta)
		BattleState.VICTORY, BattleState.DEFEAT:
			pass

func _process_player_breath(delta: float) -> void:
	_handle_tuning_input()

	var now_holding: bool = Input.is_key_pressed(KEY_SPACE)
	if now_holding != holding:
		_evaluate_phase(phase_time, holding)
		phase_time = 0.0
		holding = now_holding

	phase_time += delta

	var phase_target: float = target_inhale if holding else target_exhale
	breath_bar.value = clampf(phase_time / maxf(phase_target, 0.001), 0.0, 1.0)

	if phase_switches >= PHASES_PER_ATTACK:
		_resolve_player_attack()

func _process_enemy_timer(delta: float) -> void:
	state_timer -= delta
	if state_timer > 0.0:
		return

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var damage: int = rng.randi_range(9, 14) + int(floor(float(turn_index) * 0.8))
	player_hp = max(player_hp - damage, 0)

	if player_hp <= 0:
		state = BattleState.DEFEAT
		log_label.text = "你被击倒了……呼吸紊乱，战斗失败。"
		hint_label.text = "按 F5 重新开始"
		return

	log_label.text = "敌人反击，造成 %d 伤害！" % damage
	turn_index += 1
	_start_player_turn()

func _start_player_turn() -> void:
	state = BattleState.PLAYER_BREATH
	phase_time = 0.0
	phase_scores.clear()
	phase_switches = 0
	holding = false
	stability = maxf(stability * 0.5, 0.0)
	breath_bar.value = 0.0
	log_label.text = "第 %d 回合：调整呼吸并完成 6 次相位切换后自动攻击。" % turn_index
	hint_label.text = "Space: 按住吸气 / 松开呼气  |  方向键: 调整 I/E 节奏"

func _handle_tuning_input() -> void:
	if Input.is_action_just_pressed("ui_up"):
		target_inhale = clampf(target_inhale + STEP, MIN_INHALE, MAX_INHALE)
	if Input.is_action_just_pressed("ui_down"):
		target_inhale = clampf(target_inhale - STEP, MIN_INHALE, MAX_INHALE)
	if Input.is_action_just_pressed("ui_right"):
		target_exhale = clampf(target_exhale + STEP, MIN_EXHALE, MAX_EXHALE)
	if Input.is_action_just_pressed("ui_left"):
		target_exhale = clampf(target_exhale - STEP, MIN_EXHALE, MAX_EXHALE)

func _evaluate_phase(duration: float, was_holding: bool) -> void:
	if duration < 0.2:
		return

	var target: float = target_inhale if was_holding else target_exhale
	var err_ratio: float = absf(duration - target) / maxf(target, 0.001)
	var score: float = 1.0 - clampf(err_ratio, 0.0, 1.0)
	phase_scores.append(score)
	phase_switches += 1
	stability = lerp(stability, score, 0.35)

func _resolve_player_attack() -> void:
	var accuracy: float = 0.0
	for s in phase_scores:
		accuracy += s
	accuracy /= maxf(float(phase_scores.size()), 1.0)

	var rhythm_diff: float = absf(target_inhale - enemy_weak_inhale) + absf(target_exhale - enemy_weak_exhale)
	var rhythm_bonus: float = maxf(0.0, 2.6 - rhythm_diff)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var damage: int = int(round(12.0 + accuracy * 26.0 + rhythm_bonus * 8.0 + rng.randf_range(0.0, 4.0)))
	enemy_hp = max(enemy_hp - damage, 0)
	enemy_flash = 0.4

	if enemy_hp <= 0:
		state = BattleState.VICTORY
		log_label.text = "你的呼吸斩击造成 %d 伤害！敌人被击败！" % damage
		hint_label.text = "胜利！你用呼吸节奏掌控了战斗。"
		return

	log_label.text = "呼吸斩击造成 %d 伤害（稳定度 %.2f）！" % [damage, accuracy]
	state = BattleState.ENEMY_TURN
	state_timer = 1.2
	hint_label.text = "敌人正在行动……"

func _update_hud() -> void:
	turn_label.text = "Turn %d" % turn_index
	player_hp_label.text = "Hero HP: %d / 140" % player_hp
	enemy_hp_label.text = "Enemy HP: %d / 220" % enemy_hp

	var phase_target: float = target_inhale if holding else target_exhale
	var remain: float = maxf(phase_target - phase_time, 0.0)
	var phase_text: String = "INHALE" if holding else "EXHALE"
	breath_label.text = "%s  %.1fs  |  Stability %.2f  |  (I %.1f / E %.1f)  |  Combo %d/%d" % [
		phase_text, remain, stability, target_inhale, target_exhale, phase_switches, PHASES_PER_ATTACK
	]

func _update_visuals(delta: float) -> void:
	if state == BattleState.PLAYER_BREATH:
		hero.position = hero_base_pos + Vector2(0.0, sin(battle_time * 4.0) * (3.0 if holding else 1.5))
	else:
		hero.position = hero.position.lerp(hero_base_pos, minf(delta * 8.0, 1.0))

	enemy.position = enemy_base_pos + Vector2(0.0, sin(battle_time * 2.1) * 2.0)

	if enemy_flash > 0.0:
		enemy_flash = maxf(enemy_flash - delta, 0.0)
		enemy.modulate = Color(1.0, 0.86 + enemy_flash * 0.35, 0.86 + enemy_flash * 0.35, 1.0)
	else:
		enemy.modulate = enemy.modulate.lerp(Color(1, 1, 1, 1), minf(delta * 6.0, 1.0))
