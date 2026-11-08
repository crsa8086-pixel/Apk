extends Node2D

@onready var ball: Node2D = $Ball
@onready var goalkeeper: Node2D = $Goalkeeper
@onready var score_label: Label = $HUD/ScoreLabel
@onready var power_label: Label = $HUD/PowerLabel
@onready var angle_label: Label = $HUD/AngleLabel
@onready var message_label: Label = $HUD/MessageLabel

const FIELD_TOP = 90.0
const FIELD_BOTTOM = 630.0
const FIELD_LEFT = 100.0
const FIELD_RIGHT = 1190.0
const GOAL_TOP = 260.0
const GOAL_BOTTOM = 460.0
const GOAL_LINE = 1188.0

var current_power: float = 650.0
var current_angle: float = 0.0
var score: int = 0
var reset_delay: float = 0.0
var waiting_for_reset: bool = false

func _ready() -> void:
    reset_ball()
    update_hud()

func _process(delta: float) -> void:
    if waiting_for_reset:
        reset_delay -= delta
        if reset_delay <= 0.0:
            waiting_for_reset = false
            reset_ball()
        return

    if Input.is_key_pressed(KEY_A):
        current_angle -= 55.0 * delta
    if Input.is_key_pressed(KEY_D):
        current_angle += 55.0 * delta
    if Input.is_key_pressed(KEY_W):
        current_power += 220.0 * delta
    if Input.is_key_pressed(KEY_S):
        current_power -= 220.0 * delta

    current_angle = clamp(current_angle, -35.0, 35.0)
    current_power = clamp(current_power, 350.0, 900.0)

    if Input.is_key_just_pressed(KEY_SPACE) and not ball.in_motion:
        kick_ball()

    if ball.in_motion:
        if ball.global_position.x >= GOAL_LINE and ball.global_position.y >= GOAL_TOP and ball.global_position.y <= GOAL_BOTTOM:
            score += 1
            ball.in_motion = false
            message_label.text = "GOAL! Beautiful free kick!"
            update_hud()
            waiting_for_reset = true
            reset_delay = 1.25
        elif ball.global_position.x > FIELD_RIGHT or ball.global_position.x < FIELD_LEFT or ball.global_position.y < FIELD_TOP or ball.global_position.y > FIELD_BOTTOM:
            ball.in_motion = false
            message_label.text = "Saved! Try again."
            update_hud()
            waiting_for_reset = true
            reset_delay = 1.25

    if ball.in_motion and goalkeeper:
        goalkeeper.target_y = clamp(ball.global_position.y, GOAL_TOP, GOAL_BOTTOM)

    update_hud()

func kick_ball() -> void:
    var angle_rad = deg_to_rad(current_angle)
    var launch_dir = Vector2(cos(angle_rad), sin(angle_rad))
    ball.kick(launch_dir, current_power)
    message_label.text = "Kick taken!"
    update_hud()

func update_hud() -> void:
    score_label.text = "Score: %d" % score
    power_label.text = "Power: %d" % int(current_power)
    angle_label.text = "Angle: %d°" % int(round(current_angle))

func reset_ball() -> void:
    ball.position = Vector2(220.0, 360.0)
    ball.velocity = Vector2.ZERO
    ball.in_motion = false
    message_label.text = "Aim with A / D   Power with W / S   Space to shoot"
    update_hud()
