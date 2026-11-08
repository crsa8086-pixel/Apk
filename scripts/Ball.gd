extends Node2D

var velocity: Vector2 = Vector2.ZERO
var in_motion: bool = false
var radius: float = 15.0

func _draw() -> void:
    var outline = Color(0.94, 0.80, 0.50, 1.0)
    draw_circle(Vector2.ZERO, radius + 2.0, Color(0.98, 0.87, 0.64, 1.0))
    draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, outline, 2.0)
    draw_circle(Vector2.ZERO, radius * 0.35, Color(0.65, 0.39, 0.12, 1.0))
    draw_circle(Vector2(0.0, -4.0), 3.0, Color(0.18, 0.18, 0.18, 1.0))
    draw_line(Vector2(-6.0, 5.0), Vector2(6.0, 5.0), Color(0.18, 0.18, 0.18, 1.0), 2.0)

func _process(delta: float) -> void:
    if not in_motion:
        return

    position += velocity * delta

    if position.y <= 90.0 + radius or position.y >= 630.0 - radius:
        position.y = clamp(position.y, 90.0 + radius, 630.0 - radius)
        velocity.y *= -0.82

    if position.x <= 100.0 + radius or position.x >= 1190.0 - radius:
        position.x = clamp(position.x, 100.0 + radius, 1190.0 - radius)
        velocity.x *= -0.72

    velocity *= 0.994
    if velocity.length() < 24.0:
        velocity = Vector2.ZERO
        in_motion = false

func kick(direction: Vector2, power: float) -> void:
    velocity = direction.normalized() * power
    in_motion = true
