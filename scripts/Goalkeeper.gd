extends Node2D

@onready var ball: Node2D = get_parent().get_node("Ball")
var target_y: float = 360.0

func _process(delta: float) -> void:
    if ball:
        target_y = clamp(ball.global_position.y, 260.0, 460.0)
    position.y = lerp(position.y, target_y, 2.8 * delta)
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(-26.0, 10.0, 52.0, 78.0), Color(0.96, 0.14, 0.24, 1.0))
    draw_rect(Rect2(-18.0, 95.0, 36.0, 18.0), Color(0.85, 0.82, 0.8, 1.0))
    draw_circle(Vector2(0.0, -12.0), 24.0, Color(0.96, 0.86, 0.74, 1.0))
    draw_circle(Vector2(-7.0, -15.0), 3.0, Color(0.12, 0.12, 0.12, 1.0))
    draw_circle(Vector2(7.0, -15.0), 3.0, Color(0.12, 0.12, 0.12, 1.0))
    draw_arc(Vector2(0.0, -8.0), 11.0, 0.0, PI, 10, Color(0.24, 0.24, 0.24, 1.0), 2.0)
