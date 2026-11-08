extends Node2D

const GOAL_TOP = 260.0
const GOAL_BOTTOM = 460.0

var target_y: float = 360.0

func _process(delta: float) -> void:
    position.y = lerp(position.y, target_y, 3.2 * delta)
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(-28.0, 18.0, 56.0, 72.0), Color(0.96, 0.13, 0.24, 1.0))
    draw_rect(Rect2(-17.0, 92.0, 34.0, 20.0), Color(0.8, 0.8, 0.8, 1.0))
    draw_circle(Vector2(0, -8), 22.0, Color(0.97, 0.82, 0.72, 1.0))
    draw_circle(Vector2(-7.0, -16.0), 3.5, Color(0.12, 0.12, 0.12, 1.0))
    draw_circle(Vector2(7.0, -16.0), 3.5, Color(0.12, 0.12, 0.12, 1.0))
    draw_arc(Vector2(0.0, -6.0), 10.0, 0.0, PI, 10, Color(0.24, 0.24, 0.24, 1.0), 2.0)
