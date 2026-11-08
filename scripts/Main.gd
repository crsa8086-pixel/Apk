extends Node2D

@onready var ball: Node2D = $Ball
@onready var goalkeeper: Node2D = $Goalkeeper
@onready var score_label: Label = $HUD/ScoreLabel
@onready var power_label: Label = $HUD/PowerLabel
@onready var angle_label: Label = $HUD/AngleLabel
@onready var status_label: Label = $HUD/StatusLabel
@onready var target_label: Label = $HUD/TargetLabel

const FIELD_TOP = 90.0
const FIELD_BOTTOM = 630.0
const FIELD_LEFT = 100.0
const FIELD_RIGHT = 1190.0
const GOAL_TOP = 260.0
const GOAL_BOTTOM = 460.0
const GOAL_LINE_X = 1188.0
const BALL_START = Vector2(220.0, 360.0)

var score: int = 0
var shots_taken: int = 0
var power: float = 680.0
var angle: float = 0.0
var reset_timer: float = 0.0
var waiting_for_reset: bool = false

func _ready() -> void:
    reset_ball()
    update_hud()

func _process(delta: float) -> void:
    if waiting_for_reset:
        reset_timer -= delta
        if reset_timer <= 0.0:
            waiting_for_reset = false
            reset_ball()
        return

    if Input.is_action_pressed("aim_left"):
        angle -= 60.0 * delta
    if Input.is_action_pressed("aim_right"):
        angle += 60.0 * delta
    if Input.is_action_pressed("power_up"):
        power += 200.0 * delta
    if Input.is_action_pressed("power_down"):
        power -= 200.0 * delta

    power = clamp(power, 350.0, 900.0)
    angle = clamp(angle, -34.0, 34.0)

    if Input.is_action_just_pressed("shoot") and not ball.in_motion:
        take_shot()

    if ball.in_motion:
        if ball.global_position.x >= GOAL_LINE_X and ball.global_position.y >= GOAL_TOP and ball.global_position.y <= GOAL_BOTTOM:
            score += 1
            ball.in_motion = false
            status_label.text = "GOAL!"
            status_label.modulate = Color(0.9, 1.0, 0.4)
            target_label.text = "Target hit!"
            waiting_for_reset = true
            reset_timer = 1.25
        elif ball.global_position.x > FIELD_RIGHT or ball.global_position.x < FIELD_LEFT or ball.global_position.y < FIELD_TOP or ball.global_position.y > FIELD_BOTTOM:
            ball.in_motion = false
            status_label.text = "Saved!"
            status_label.modulate = Color(1.0, 0.7, 0.5)
            target_label.text = "Try again"
            waiting_for_reset = true
            reset_timer = 1.25

    if ball.in_motion and goalkeeper:
        goalkeeper.target_y = clamp(ball.global_position.y, GOAL_TOP, GOAL_BOTTOM)

    update_hud()

func take_shot() -> void:
    shots_taken += 1
    var aim = Vector2(cos(deg_to_rad(angle)), sin(deg_to_rad(angle)))
    ball.kick(aim, power)
    status_label.text = "Shot launched"
    status_label.modulate = Color(1.0, 1.0, 1.0)
    target_label.text = "Power %d | Angle %d" % [int(power), int(angle)]

func update_hud() -> void:
    score_label.text = "Score: %d" % score
    power_label.text = "Power: %d" % int(power)
    angle_label.text = "Angle: %d°" % int(round(angle))
    status_label.text = status_label.text if status_label.text != "" else "Ready"

func reset_ball() -> void:
    ball.position = BALL_START
    ball.velocity = Vector2.ZERO
    ball.in_motion = false
    status_label.text = "Ready to shoot"
    status_label.modulate = Color(1.0, 1.0, 1.0)
    target_label.text = "A/D aim   W/S power   Space shoot"
    update_hud()
