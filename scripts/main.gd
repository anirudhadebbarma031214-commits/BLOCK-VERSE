extends Node3D

const MOVE_SPEED := 7.0
const JUMP_VELOCITY := 7.5
const MOUSE_SENSITIVITY := 0.0025
const BLOCK_SIZE := Vector3(1.5, 1.5, 1.5)

var player: CharacterBody3D
var camera_pivot: Node3D
var camera: Camera3D
var hud_label: Label
var build_mode := false
var yaw := 0.0
var pitch := -0.15
var blocks_placed := 0

func _ready() -> void:
    _build_world()
    _create_player()
    _create_hud()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_world() -> void:
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    environment.sky = Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.035, 0.09, 0.19)
    sky_material.sky_horizon_color = Color(0.35, 0.58, 0.78)
    sky_material.ground_bottom_color = Color(0.045, 0.06, 0.08)
    sky_material.ground_horizon_color = Color(0.22, 0.29, 0.33)
    environment.sky.sky_material = sky_material
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.65, 0.76, 1.0)
    environment.ambient_light_energy = 0.7
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.environment = environment
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -30, 0)
    sun.light_energy = 1.25
    sun.shadow_enabled = true
    add_child(sun)

    _make_box("Island Base", Vector3(0, -0.6, 0), Vector3(70, 1, 70), Color(0.12, 0.19, 0.23))
    _make_box("Spawn Plaza", Vector3(0, -0.02, 0), Vector3(22, 0.25, 22), Color(0.23, 0.29, 0.34))
    # Bright tiles make the starter hub easy to read.
    for x in range(-9, 10, 3):
        _make_box("Plaza Tile", Vector3(float(x), 0.12, 0), Vector3(0.07, 0.025, 18), Color(0.15, 0.75, 0.95), false)
    for z in range(-9, 10, 3):
        _make_box("Plaza Tile", Vector3(0, 0.12, float(z)), Vector3(18, 0.025, 0.07), Color(0.15, 0.75, 0.95), false)

    # Starter obby: colorful platforms lead to a small finish tower.
    var obby := [
        [Vector3(0, 0.7, -14), Vector3(4, 0.7, 4), Color(0.1, 0.8, 0.95)],
        [Vector3(0, 1.7, -20), Vector3(3.5, 0.7, 3.5), Color(0.45, 0.35, 1.0)],
        [Vector3(3, 2.6, -25), Vector3(3.5, 0.7, 3.5), Color(1.0, 0.35, 0.65)],
        [Vector3(6, 3.5, -30), Vector3(3.5, 0.7, 3.5), Color(1.0, 0.68, 0.2)],
        [Vector3(6, 4.4, -36), Vector3(6, 0.7, 6), Color(0.3, 0.95, 0.58)]
    ]
    for item in obby:
        _make_box("Obby Platform", item[0], item[1], item[2])

    _make_box("Finish Pillar", Vector3(6, 7.0, -36), Vector3(1.2, 4.5, 1.2), Color(0.22, 0.9, 0.65))
    _make_box("Welcome Sign", Vector3(-12, 2.1, -7), Vector3(0.4, 3.6, 7), Color(0.08, 0.16, 0.25))
    _make_box("Neon Sign Face", Vector3(-11.75, 2.3, -7), Vector3(0.12, 2.4, 5.5), Color(0.1, 0.75, 1.0), false)

    # Simple skyline silhouettes around the play space.
    for i in range(18):
        var angle := TAU * float(i) / 18.0
        var radius := 27.0 + float(i % 3) * 2.0
        var height := 4.0 + float((i * 7) % 8)
        var pos := Vector3(cos(angle) * radius, height * 0.5 - 0.1, sin(angle) * radius)
        var building_color := Color(0.08 + float(i % 3) * 0.025, 0.13 + float(i % 4) * 0.02, 0.21 + float(i % 2) * 0.04)
        _make_box("Skyline Building", pos, Vector3(3.5, height, 3.5), building_color)

func _make_box(label: String, position: Vector3, size: Vector3, color: Color, solid: bool = true) -> Node3D:
    var root: Node3D
    if solid:
        var body := StaticBody3D.new()
        body.name = label
        root = body
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        body.add_child(collision)
    else:
        root = Node3D.new()
        root.name = label

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = 0.12
    material.roughness = 0.48
    mesh_instance.material_override = material
    root.add_child(mesh_instance)
    root.position = position
    add_child(root)
    return root

func _create_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, 1.5, 3)
    add_child(player)

    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.42
    capsule.height = 1.8
    collision.shape = capsule
    collision.position.y = 0.9
    player.add_child(collision)

    var body_mesh := MeshInstance3D.new()
    var body_shape := CapsuleMesh.new()
    body_shape.radius = 0.42
    body_shape.height = 1.8
    body_mesh.mesh = body_shape
    var body_material := StandardMaterial3D.new()
    body_material.albedo_color = Color(0.12, 0.72, 1.0)
    body_material.metallic = 0.22
    body_material.roughness = 0.32
    body_mesh.material_override = body_material
    body_mesh.position.y = 0.9
    player.add_child(body_mesh)

    var face := MeshInstance3D.new()
    var face_mesh := SphereMesh.new()
    face_mesh.radius = 0.13
    face_mesh.height = 0.26
    face.mesh = face_mesh
    var face_material := StandardMaterial3D.new()
    face_material.albedo_color = Color(1.0, 0.83, 0.61)
    face.material_override = face_material
    face.position = Vector3(0, 1.38, -0.31)
    player.add_child(face)

    camera_pivot = Node3D.new()
    camera_pivot.position = Vector3(0, 1.45, 0)
    player.add_child(camera_pivot)
    camera = Camera3D.new()
    camera.position = Vector3(0, 1.2, 5.8)
    camera.rotation.x = -0.12
    camera.current = true
    camera_pivot.add_child(camera)

func _create_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    hud_label = Label.new()
    hud_label.position = Vector2(22, 18)
    hud_label.add_theme_font_size_override("font_size", 18)
    hud_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0))
    hud_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
    hud_label.add_theme_constant_override("shadow_offset_x", 2)
    hud_label.add_theme_constant_override("shadow_offset_y", 2)
    layer.add_child(hud_label)
    _update_hud()

    var title := Label.new()
    title.text = "BLOCK-VERSE"
    title.position = Vector2(22, 100)
    title.add_theme_font_size_override("font_size", 27)
    title.add_theme_color_override("font_color", Color(0.2, 0.86, 1.0))
    layer.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "EXPLORE  •  JUMP  •  BUILD"
    subtitle.position = Vector2(24, 136)
    subtitle.add_theme_font_size_override("font_size", 13)
    subtitle.add_theme_color_override("font_color", Color(0.72, 0.83, 0.92))
    layer.add_child(subtitle)

func _update_hud() -> void:
    if hud_label:
        var mode_text := "BUILD MODE" if build_mode else "EXPLORE MODE"
        hud_label.text = "WASD Move   SPACE Jump   B Build   ESC Release Mouse\n" + mode_text + "   |   Blocks placed: " + str(blocks_placed)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        elif build_mode:
            _place_block()
    elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        yaw -= event.relative.x * MOUSE_SENSITIVITY
        pitch = clamp(pitch - event.relative.y * MOUSE_SENSITIVITY, -0.9, 0.55)
        player.rotation.y = yaw
        camera_pivot.rotation.x = pitch
    elif event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        elif event.keycode == KEY_B:
            build_mode = not build_mode
            _update_hud()

func _physics_process(delta: float) -> void:
    if not is_instance_valid(player):
        return

    if not player.is_on_floor():
        player.velocity.y -= 20.0 * delta
    elif Input.is_key_pressed(KEY_SPACE):
        player.velocity.y = JUMP_VELOCITY

    var input_dir := Vector2.ZERO
    if Input.is_key_pressed(KEY_W):
        input_dir.y -= 1.0
    if Input.is_key_pressed(KEY_S):
        input_dir.y += 1.0
    if Input.is_key_pressed(KEY_A):
        input_dir.x -= 1.0
    if Input.is_key_pressed(KEY_D):
        input_dir.x += 1.0
    input_dir = input_dir.normalized()

    var forward := -player.global_transform.basis.z
    var right := player.global_transform.basis.x
    var direction := (right * input_dir.x + forward * input_dir.y).normalized()
    if direction.length() > 0.0:
        player.velocity.x = direction.x * MOVE_SPEED
        player.velocity.z = direction.z * MOVE_SPEED
    else:
        player.velocity.x = move_toward(player.velocity.x, 0.0, MOVE_SPEED * 5.0 * delta)
        player.velocity.z = move_toward(player.velocity.z, 0.0, MOVE_SPEED * 5.0 * delta)

    player.move_and_slide()
    if player.global_position.y < -8.0:
        player.global_position = Vector3(0, 2, 3)
        player.velocity = Vector3.ZERO

func _place_block() -> void:
    var target := camera.global_position + (-camera.global_transform.basis.z * 5.0)
    target.x = round(target.x / BLOCK_SIZE.x) * BLOCK_SIZE.x
    target.y = max(0.8, round(target.y / BLOCK_SIZE.y) * BLOCK_SIZE.y)
    target.z = round(target.z / BLOCK_SIZE.z) * BLOCK_SIZE.z
    _make_box("Player Block", target, BLOCK_SIZE, Color(0.12, 0.72, 1.0))
    blocks_placed += 1
    _update_hud()
