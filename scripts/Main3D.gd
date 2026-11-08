extends Node3D

const BALL_START := Vector3(0.0, 0.23, -5.0)
const GOAL_Z := 18.0
const GOAL_HALF_WIDTH := 3.66
const GOAL_HEIGHT := 2.44
const GRAVITY := 9.8

var ball: Node3D
var goalkeeper: Node3D
var camera: Camera3D
var aim_marker: MeshInstance3D
var score_label: Label
var power_label: Label
var status_label: Label
var help_label: Label
var power := 18.0
var aim_x := 0.0
var score := 0
var shots := 0
var ball_velocity := Vector3.ZERO
var ball_in_flight := false
var keeper_home_x := 0.0
var keeper_speed := 4.3
var waiting_reset := 0.0

var turf_mat: StandardMaterial3D
var white_mat: StandardMaterial3D
var dark_mat: StandardMaterial3D
var red_mat: StandardMaterial3D
var skin_mat: StandardMaterial3D

func _ready() -> void:
    _make_materials()
    _build_stadium()
    _build_ball()
    _build_goalkeeper()
    _build_camera_and_lighting()
    _build_hud()
    _reset_ball()

func _process(delta: float) -> void:
    if waiting_reset > 0.0:
        waiting_reset -= delta
        if waiting_reset <= 0.0:
            _reset_ball()
        return

    if not ball_in_flight:
        if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
            aim_x -= 4.0 * delta
        if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
            aim_x += 4.0 * delta
        if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
            power += 10.0 * delta
        if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
            power -= 10.0 * delta
        aim_x = clamp(aim_x, -4.5, 4.5)
        power = clamp(power, 13.0, 25.0)
        if Input.is_key_just_pressed(KEY_SPACE):
            _kick()
        if is_instance_valid(aim_marker):
            aim_marker.position = Vector3(aim_x, 0.04, 12.0)
    if Input.is_key_just_pressed(KEY_R):
        score = 0
        shots = 0
        waiting_reset = 0.0
        _reset_ball()
    _update_hud()

func _physics_process(delta: float) -> void:
    if not ball_in_flight:
        return
    ball_velocity.y -= GRAVITY * delta
    ball.position += ball_velocity * delta
    ball.rotate_x(delta * 6.5)
    ball.rotate_z(delta * 3.2)

    var keeper_target_x := clamp(ball.position.x * 0.55, -3.1, 3.1)
    goalkeeper.position.x = move_toward(goalkeeper.position.x, keeper_target_x, keeper_speed * delta)

    if ball.position.z >= GOAL_Z:
        if absf(ball.position.x) <= GOAL_HALF_WIDTH - 0.15 and ball.position.y >= 0.18 and ball.position.y <= GOAL_HEIGHT - 0.1:
            score += 1
            status_label.text = "GOAL!  What a free kick!"
            status_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.45))
        else:
            status_label.text = "Wide or over the bar! Try again."
            status_label.add_theme_color_override("font_color", Color(1.0, 0.74, 0.48))
        ball_in_flight = false
        waiting_reset = 1.5
    elif ball.position.z > 14.8 and absf(ball.position.x - goalkeeper.position.x) < 0.75 and ball.position.y < 2.0:
        status_label.text = "SAVED! The keeper got a hand to it."
        status_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.48))
        ball_in_flight = false
        waiting_reset = 1.5
    elif ball.position.y <= 0.23 and ball.position.z < GOAL_Z:
        ball.position.y = 0.23
        ball_velocity.y = absf(ball_velocity.y) * 0.38
        ball_velocity.x *= 0.78
        ball_velocity.z *= 0.82
        if ball_velocity.length() < 2.0:
            status_label.text = "Shot missed. Adjust your aim and power."
            ball_in_flight = false
            waiting_reset = 1.2

func _make_materials() -> void:
    turf_mat = _material(Color(0.08, 0.39, 0.17), 0.0, 0.12)
    white_mat = _material(Color(0.94, 0.97, 0.94), 0.0, 0.25)
    dark_mat = _material(Color(0.045, 0.065, 0.09), 0.05, 0.32)
    red_mat = _material(Color(0.83, 0.055, 0.095), 0.0, 0.3)
    skin_mat = _material(Color(0.78, 0.51, 0.34), 0.0, 0.4)

func _material(color: Color, metal: float, rough: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = metal
    mat.roughness = rough
    return mat

func _build_stadium() -> void:
    var field := _box("Pitch", Vector3(40.0, 0.18, 58.0), Vector3(0.0, -0.10, 6.0), turf_mat)
    field.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    for i in range(10):
        var stripe_mat := _material(Color(0.095 if i % 2 == 0 else 0.075, 0.44 if i % 2 == 0 else 0.38, 0.19 if i % 2 == 0 else 0.16), 0.0, 0.9)
        var strip := _box("MowingStripe", Vector3(40.0, 0.012, 2.9), Vector3(0.0, 0.0, -20.0 + i * 5.8), stripe_mat)
        strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

    _line_box("TouchlineLeft", Vector3(0.12, 0.025, 50.0), Vector3(-18.0, 0.015, 6.0))
    _line_box("TouchlineRight", Vector3(0.12, 0.025, 50.0), Vector3(18.0, 0.015, 6.0))
    _line_box("EndLineNear", Vector3(36.0, 0.025, 0.12), Vector3(0.0, 0.015, -18.0))
    _line_box("GoalLine", Vector3(36.0, 0.025, 0.12), Vector3(0.0, 0.015, 30.0))
    _line_box("PenaltyAreaTop", Vector3(16.5, 0.025, 0.12), Vector3(0.0, 0.015, 21.0))
    _line_box("PenaltyAreaLeft", Vector3(0.12, 0.025, 12.0), Vector3(-8.25, 0.015, 27.0))
    _line_box("PenaltyAreaRight", Vector3(0.12, 0.025, 12.0), Vector3(8.25, 0.015, 27.0))
    _line_box("SixYardTop", Vector3(9.0, 0.025, 0.12), Vector3(0.0, 0.015, 27.0))
    _line_box("SixYardLeft", Vector3(0.12, 0.025, 6.0), Vector3(-4.5, 0.015, 27.0))
    _line_box("SixYardRight", Vector3(0.12, 0.025, 6.0), Vector3(4.5, 0.015, 27.0))
    _line_box("CenterLine", Vector3(36.0, 0.025, 0.12), Vector3(0.0, 0.015, -2.0))

    _cylinder("CenterSpot", 0.11, 0.025, Vector3(0.0, 0.03, -2.0), white_mat)
    _cylinder("PenaltySpot", 0.11, 0.025, Vector3(0.0, 0.03, 24.0), white_mat)
    _make_goal()
    _make_crowd()

func _make_goal() -> void:
    var goal_mat := _material(Color(0.93, 0.96, 1.0), 0.35, 0.2)
    _cylinder("GoalLeftPost", 0.12, GOAL_HEIGHT, Vector3(-GOAL_HALF_WIDTH, GOAL_HEIGHT * 0.5, GOAL_Z), goal_mat)
    _cylinder("GoalRightPost", 0.12, GOAL_HEIGHT, Vector3(GOAL_HALF_WIDTH, GOAL_HEIGHT * 0.5, GOAL_Z), goal_mat)
    var crossbar := _cylinder("GoalCrossbar", 0.12, GOAL_HALF_WIDTH * 2.0, Vector3(0.0, GOAL_HEIGHT, GOAL_Z), goal_mat)
    crossbar.rotation.z = PI * 0.5
    var net_mat := _material(Color(0.83, 0.9, 0.96, 0.35), 0.0, 0.8)
    for i in range(9):
        var x := -GOAL_HALF_WIDTH + i * GOAL_HALF_WIDTH * 0.25
        _line_box("NetVertical", Vector3(0.025, GOAL_HEIGHT, 0.025), Vector3(x, GOAL_HEIGHT * 0.5, GOAL_Z + 2.2), net_mat)
    for j in range(1, 5):
        _line_box("NetHorizontal", Vector3(GOAL_HALF_WIDTH * 2.0, 0.025, 0.025), Vector3(0.0, j * GOAL_HEIGHT / 5.0, GOAL_Z + 2.2), net_mat)
    _line_box("NetRoof", Vector3(GOAL_HALF_WIDTH * 2.0, 0.025, 2.2), Vector3(0.0, GOAL_HEIGHT, GOAL_Z + 1.1), net_mat)

func _make_crowd() -> void:
    var stand_mat := _material(Color(0.055, 0.09, 0.16), 0.0, 0.9)
    _box("FarStand", Vector3(42.0, 8.0, 2.0), Vector3(0.0, 4.0, 36.0), stand_mat)
    _box("LeftStand", Vector3(2.0, 8.0, 54.0), Vector3(-21.0, 4.0, 7.0), stand_mat)
    _box("RightStand", Vector3(2.0, 8.0, 54.0), Vector3(21.0, 4.0, 7.0), stand_mat)
    var colors := [Color(0.9, 0.15, 0.17), Color(0.96, 0.8, 0.24), Color(0.9, 0.93, 0.96), Color(0.15, 0.55, 0.95)]
    for row in range(6):
        for col in range(42):
            var x := -19.0 + col * 0.92
            var y := 1.2 + row * 0.85
            var z := 34.8
            var fan := _sphere("Crowd", Vector3(0.18, 0.26, 0.16), Vector3(x, y, z), _material(colors[(row * 11 + col * 7) % colors.size()], 0.0, 0.9))
            fan.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _build_ball() -> void:
    ball = Node3D.new()
    ball.name = "Football"
    add_child(ball)
    ball.position = BALL_START
    var sphere := SphereMesh.new()
    sphere.radius = 0.23
    sphere.height = 0.46
    sphere.radial_segments = 24
    sphere.rings = 16
    var ball_mat := _material(Color(0.96, 0.96, 0.9), 0.0, 0.26)
    var mesh := MeshInstance3D.new()
    mesh.mesh = sphere
    mesh.material_override = ball_mat
    ball.add_child(mesh)
    var seam := _torus("BallSeam", 0.16, 0.012, Vector3.ZERO, dark_mat, ball)
    seam.rotation.x = PI * 0.5
    var seam2 := _torus("BallSeam2", 0.16, 0.012, Vector3.ZERO, dark_mat, ball)
    seam2.rotation.y = PI * 0.5

func _build_goalkeeper() -> void:
    goalkeeper = Node3D.new()
    goalkeeper.name = "Goalkeeper"
    goalkeeper.position = Vector3(0.0, 0.0, GOAL_Z - 0.7)
    add_child(goalkeeper)
    _capsule("KeeperBody", 0.38, 1.2, Vector3(0.0, 1.02, 0.0), red_mat, goalkeeper)
    _sphere("KeeperHead", Vector3(0.25, 0.27, 0.25), Vector3(0.0, 1.82, 0.0), skin_mat, goalkeeper)
    _box_parent("KeeperLeftArm", Vector3(0.85, 0.16, 0.2), Vector3(-0.57, 1.35, 0.0), white_mat, goalkeeper, Vector3(0.0, 0.0, -0.25))
    _box_parent("KeeperRightArm", Vector3(0.85, 0.16, 0.2), Vector3(0.57, 1.35, 0.0), white_mat, goalkeeper, Vector3(0.0, 0.0, 0.25))
    _box_parent("KeeperLeftLeg", Vector3(0.22, 0.65, 0.27), Vector3(-0.2, 0.38, 0.0), dark_mat, goalkeeper)
    _box_parent("KeeperRightLeg", Vector3(0.22, 0.65, 0.27), Vector3(0.2, 0.38, 0.0), dark_mat, goalkeeper)
    _sphere("LeftGlove", Vector3(0.19, 0.16, 0.14), Vector3(-1.03, 1.36, 0.0), white_mat, goalkeeper)
    _sphere("RightGlove", Vector3(0.19, 0.16, 0.14), Vector3(1.03, 1.36, 0.0), white_mat, goalkeeper)

func _build_camera_and_lighting() -> void:
    camera = Camera3D.new()
    camera.name = "GameCamera"
    camera.position = Vector3(0.0, 7.0, -16.0)
    camera.rotation_degrees = Vector3(-13.0, 0.0, 0.0)
    camera.fov = 52.0
    add_child(camera)
    camera.current = true

    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.025, 0.09, 0.2)
    sky_mat.sky_horizon_color = Color(0.3, 0.47, 0.62)
    sky_mat.ground_bottom_color = Color(0.04, 0.07, 0.08)
    sky_mat.ground_horizon_color = Color(0.23, 0.3, 0.28)
    sky.sky_material = sky_mat
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.58, 0.67, 0.82)
    env.ambient_light_energy = 0.55
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world.environment = env
    add_child(world)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
    sun.light_energy = 1.35
    sun.shadow_enabled = true
    add_child(sun)
    for x in [-16.0, 16.0]:
        var lamp := SpotLight3D.new()
        lamp.position = Vector3(x, 12.0, 15.0)
        lamp.rotation_degrees = Vector3(-40.0, 0.0 if x < 0.0 else 180.0, 0.0)
        lamp.light_color = Color(0.72, 0.84, 1.0)
        lamp.light_energy = 18.0
        lamp.spot_range = 30.0
        lamp.spot_angle = 62.0
        add_child(lamp)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "HUD"
    add_child(layer)
    var panel := ColorRect.new()
    panel.position = Vector2(22, 20)
    panel.size = Vector2(360, 132)
    panel.color = Color(0.015, 0.035, 0.07, 0.78)
    layer.add_child(panel)

    score_label = _label(layer, "SCORE  0", Vector2(42, 30), 25, Color(1.0, 0.83, 0.32))
    power_label = _label(layer, "POWER  18", Vector2(42, 69), 19, Color(0.88, 0.95, 1.0))
    status_label = _label(layer, "READY — SET YOUR AIM", Vector2(0, 580), 27, Color(1.0, 1.0, 1.0))
    status_label.size = Vector2(1280, 48)
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    help_label = _label(layer, "A / D or ← / →  AIM     W / S or ↑ / ↓  POWER     SPACE  KICK     R  RESET", Vector2(0, 652), 16, Color(0.82, 0.9, 0.98))
    help_label.size = Vector2(1280, 32)
    help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var aim_label := _label(layer, "AIM", Vector2(42, 102), 16, Color(0.65, 0.82, 0.95))
    aim_label.name = "AimReadout"

    var marker_mesh := CylinderMesh.new()
    marker_mesh.top_radius = 0.42
    marker_mesh.bottom_radius = 0.55
    marker_mesh.height = 0.025
    aim_marker = MeshInstance3D.new()
    aim_marker.name = "AimMarker"
    aim_marker.mesh = marker_mesh
    aim_marker.material_override = _material(Color(1.0, 0.85, 0.23, 0.8), 0.1, 0.3)
    aim_marker.position = Vector3(0, 0.04, 12)
    add_child(aim_marker)

func _label(parent: Node, text: String, pos: Vector2, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.position = pos
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    parent.add_child(label)
    return label

func _update_hud() -> void:
    if not is_instance_valid(score_label):
        return
    score_label.text = "SCORE  %d     SHOTS  %d" % [score, shots]
    power_label.text = "POWER  %d       AIM  %+.1f m" % [int(round(power)), aim_x]

func _kick() -> void:
    shots += 1
    ball_velocity = Vector3(aim_x * 0.78, 5.7 + power * 0.13, power)
    ball_in_flight = true
    status_label.text = "FREE KICK!"
    status_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.48))
    _update_hud()

func _reset_ball() -> void:
    ball.position = BALL_START
    ball.rotation = Vector3.ZERO
    ball_velocity = Vector3.ZERO
    ball_in_flight = false
    aim_x = 0.0
    power = 18.0
    goalkeeper.position = Vector3(0.0, 0.0, GOAL_Z - 0.7)
    status_label.text = "READY — SET YOUR AIM"
    status_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
    if is_instance_valid(aim_marker):
        aim_marker.position.x = 0.0
    _update_hud()

func _box(name: String, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var instance := MeshInstance3D.new()
    instance.name = name
    instance.mesh = mesh
    instance.material_override = mat
    instance.position = pos
    add_child(instance)
    return instance

func _line_box(name: String, size: Vector3, pos: Vector3, mat: Material = null) -> MeshInstance3D:
    return _box(name, size, pos, mat if mat != null else white_mat)

func _box_parent(name: String, size: Vector3, pos: Vector3, mat: Material, parent: Node3D, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var instance := MeshInstance3D.new()
    instance.name = name
    instance.mesh = mesh
    instance.material_override = mat
    instance.position = pos
    instance.rotation = rot
    parent.add_child(instance)
    return instance

func _sphere(name: String, size: Vector3, pos: Vector3, mat: Material, parent: Node3D = null) -> MeshInstance3D:
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    var instance := MeshInstance3D.new()
    instance.name = name
    instance.mesh = mesh
    instance.scale = size
    instance.position = pos
    instance.material_override = mat
    if parent == null:
        add_child(instance)
    else:
        parent.add_child(instance)
    return instance

func _cylinder(name: String, radius: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    var instance := MeshInstance3D.new()
    instance.name = name
    instance.mesh = mesh
    instance.material_override = mat
    instance.position = pos
    add_child(instance)
    return instance

func _capsule(name: String, radius: float, height: float, pos: Vector3, mat: Material, parent: Node3D) -> MeshInstance3D:
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    var instance := MeshInstance3D.new()
    instance.name = name
    instance.mesh = mesh
    instance.material_override = mat
    instance.position = pos
    parent.add_child(instance)
    return instance

func _torus(name: String, outer: float, inner: float, pos: Vector3, mat: Material, parent: Node3D) -> MeshInstance3D:
    var mesh := TorusMesh.new()
    mesh.outer_radius = outer
    mesh.inner_radius = inner
    var instance := MeshInstance3D.new()
    instance.name = name
    instance.mesh = mesh
    instance.material_override = mat
    instance.position = pos
    parent.add_child(instance)
    return instance
