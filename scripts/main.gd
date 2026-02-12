extends Node2D

@export var speed: float = 220.0

const PLAYER_SIZE := Vector2(32.0, 32.0)
const PLAYER_COLOR := Color(0.2, 0.9, 0.6)
const COLLECTIBLE_RADIUS := 10.0
const COLLECTIBLE_COLOR := Color(1.0, 0.8, 0.2)

var start_position := Vector2(100.0, 100.0)
var player_position := Vector2(100.0, 100.0)
var collectible_position := Vector2.ZERO
var score := 0
var rng := RandomNumberGenerator.new()

@onready var score_label: Label = $ScoreLabel

func _ready() -> void:
	rng.randomize()
	_reset_run()
	queue_redraw()

func _process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		player_position += direction * speed * delta

	if Input.is_action_just_pressed("reset_player"):
		_reset_run()

	var viewport_size := get_viewport_rect().size
	player_position.x = clamp(player_position.x, 0.0, viewport_size.x - PLAYER_SIZE.x)
	player_position.y = clamp(player_position.y, 0.0, viewport_size.y - PLAYER_SIZE.y)

	if _is_collectible_collected():
		score += 1
		_update_score_label()
		_spawn_collectible()

	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(player_position, PLAYER_SIZE), PLAYER_COLOR)
	draw_circle(collectible_position, COLLECTIBLE_RADIUS, COLLECTIBLE_COLOR)

func _reset_run() -> void:
	player_position = start_position
	score = 0
	_update_score_label()
	_spawn_collectible()

func _is_collectible_overlapping_player(candidate_pos: Vector2) -> bool:
	return _collectible_clearance(candidate_pos) <= 0.0

func _collectible_clearance(candidate_pos: Vector2) -> float:
	var player_rect := Rect2(player_position, PLAYER_SIZE)
	var closest_x: float = clamp(candidate_pos.x, player_rect.position.x, player_rect.end.x)
	var closest_y: float = clamp(candidate_pos.y, player_rect.position.y, player_rect.end.y)
	var closest_point := Vector2(closest_x, closest_y)
	return closest_point.distance_to(candidate_pos) - COLLECTIBLE_RADIUS

func _spawn_collectible() -> void:
	var viewport_size := get_viewport_rect().size
	var min_x: float = COLLECTIBLE_RADIUS
	var min_y: float = COLLECTIBLE_RADIUS
	var max_x: float = max(COLLECTIBLE_RADIUS, viewport_size.x - COLLECTIBLE_RADIUS)
	var max_y: float = max(COLLECTIBLE_RADIUS, viewport_size.y - COLLECTIBLE_RADIUS)
	var candidate := Vector2.ZERO
	var best_candidate := Vector2(min_x, min_y)
	var best_clearance := -INF
	var max_attempts := 10
	for i in range(max_attempts):
		candidate = Vector2(
			rng.randf_range(min_x, max_x),
			rng.randf_range(min_y, max_y)
		)
		var clearance := _collectible_clearance(candidate)
		if clearance > best_clearance:
			best_clearance = clearance
			best_candidate = candidate
		if clearance > 0.0:
			collectible_position = candidate
			return

	var fallback_points := [
		Vector2(min_x, min_y),
		Vector2(max_x, min_y),
		Vector2(min_x, max_y),
		Vector2(max_x, max_y),
		Vector2((min_x + max_x) * 0.5, min_y),
		Vector2((min_x + max_x) * 0.5, max_y),
		Vector2(min_x, (min_y + max_y) * 0.5),
		Vector2(max_x, (min_y + max_y) * 0.5),
		Vector2((min_x + max_x) * 0.5, (min_y + max_y) * 0.5)
	]
	for fallback_point in fallback_points:
		if _collectible_clearance(fallback_point) > 0.0:
			collectible_position = fallback_point
			return

	collectible_position = best_candidate

func _is_collectible_collected() -> bool:
	return _is_collectible_overlapping_player(collectible_position)

func _update_score_label() -> void:
	score_label.text = "Score: %d" % score
