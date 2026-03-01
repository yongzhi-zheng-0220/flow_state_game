extends Control

@export var stroke_count := 42
@export var seed := 1203
@export var min_stroke_size := Vector2(36.0, 16.0)
@export var max_stroke_size := Vector2(150.0, 62.0)
@export var drift_strength := 4.0
@export var layer_opacity := 0.44
@export var palette: PackedColorArray = PackedColorArray([
	Color(0.71, 0.82, 0.84, 1.0),
	Color(0.62, 0.74, 0.76, 1.0),
	Color(0.79, 0.82, 0.70, 1.0),
	Color(0.70, 0.66, 0.79, 1.0),
	Color(0.84, 0.79, 0.73, 1.0),
	Color(0.62, 0.78, 0.67, 1.0)
])

var _time := 0.0
var _stroke_meta: Array[Dictionary] = []
var _rebuild_pending := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	_schedule_rebuild()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_schedule_rebuild()

func _process(delta: float) -> void:
	_time += delta
	for data in _stroke_meta:
		var node: Panel = data.get("node") as Panel
		if node == null:
			continue
		var base_pos: Vector2 = data.get("base_pos", Vector2.ZERO)
		var amp: float = data.get("amp", 0.0)
		var speed: float = data.get("speed", 1.0)
		var phase: float = data.get("phase", 0.0)
		node.position = base_pos + Vector2(
			sin(_time * speed + phase) * amp,
			cos(_time * speed * 0.83 + phase) * amp * 0.45
		)
		node.rotation_degrees = data.get("base_rot", 0.0) + sin(_time * speed * 0.5 + phase) * 1.8
		node.modulate.a = data.get("alpha", 0.6) * (0.90 + 0.10 * sin(_time * speed * 0.7 + phase))

func _schedule_rebuild() -> void:
	if _rebuild_pending:
		return
	_rebuild_pending = true
	call_deferred("_rebuild")

func _rebuild() -> void:
	_rebuild_pending = false
	_clear_strokes()

	if size.x < 2.0 or size.y < 2.0:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	_stroke_meta.clear()

	for i in range(stroke_count):
		var stroke := Panel.new()
		stroke.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var w := rng.randf_range(min_stroke_size.x, max_stroke_size.x)
		var h := rng.randf_range(min_stroke_size.y, max_stroke_size.y)
		stroke.size = Vector2(w, h)
		stroke.position = Vector2(
			rng.randf_range(-w * 0.25, size.x - w * 0.75),
			rng.randf_range(-h * 0.25, size.y - h * 0.75)
		)
		var base_rot := rng.randf_range(-16.0, 16.0)
		stroke.rotation_degrees = base_rot

		var color := _pick_palette_color(rng)
		color.a = rng.randf_range(0.18, 0.46)

		var style := StyleBoxFlat.new()
		style.bg_color = color
		var radius := int(rng.randf_range(8.0, 22.0))
		style.corner_radius_top_left = radius
		style.corner_radius_top_right = radius
		style.corner_radius_bottom_right = radius
		style.corner_radius_bottom_left = radius
		stroke.add_theme_stylebox_override("panel", style)

		add_child(stroke)

		_stroke_meta.append({
			"node": stroke,
			"base_pos": stroke.position,
			"base_rot": base_rot,
			"amp": rng.randf_range(0.8, drift_strength),
			"speed": rng.randf_range(0.16, 0.48),
			"phase": rng.randf_range(0.0, TAU),
			"alpha": color.a
		})

	modulate.a = layer_opacity

func _clear_strokes() -> void:
	for child in get_children():
		child.queue_free()

func _pick_palette_color(rng: RandomNumberGenerator) -> Color:
	if palette.is_empty():
		return Color(0.7, 0.8, 0.8, 1.0)
	return palette[rng.randi_range(0, palette.size() - 1)]
