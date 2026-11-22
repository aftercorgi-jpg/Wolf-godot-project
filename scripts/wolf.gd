extends CharacterBody3D

@export var walk_speed := 4.2
@export var run_speed := 7.2
@export var acceleration := 12.0
@export var turn_speed := 9.0
var hunger := 100.0
var thirst := 100.0
var stamina := 100.0
var health := 100.0
var food_count := 0
var _attack_requested := false
var _pickup_requested := false
var _attack_cooldown := 0.0
var _visual: Node3D
var _camera_pivot: Node3D
var _camera: Camera3D
var _move_input := Vector2.ZERO
var _mobile_move := Vector2.ZERO
var _mobile_sprint := false
var _jump_requested := false

func _ready() -> void:
    name = "PlayerWolf"
    _create_body()
    _create_camera()
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.48
    capsule.height = 1.45
    collision.shape = capsule
    collision.position.y = 0.72
    add_child(collision)

func _physics_process(delta: float) -> void:
    hunger = maxf(0.0, hunger - delta * 0.045)
    thirst = maxf(0.0, thirst - delta * 0.075)
    _attack_cooldown = maxf(0.0, _attack_cooldown - delta)
    if _attack_requested:
        _attack_nearest_prey()
    if _pickup_requested:
        _pick_up_nearest_food()
    _attack_requested = false
    _pickup_requested = false
    var keys := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    if _mobile_move.length() > keys.length():
        keys = _mobile_move
    _move_input = keys
    # Convert screen joystick axes into camera-relative world movement.
    # Stick up is negative Y, so it maps to the camera's forward (-Z) direction.
    var camera_right := _camera.global_transform.basis.x
    var camera_forward := -_camera.global_transform.basis.z
    camera_right.y = 0.0
    camera_forward.y = 0.0
    camera_right = camera_right.normalized()
    camera_forward = camera_forward.normalized()
    var direction := camera_right * keys.x + camera_forward * (-keys.y)
    if direction.length() > 0.05:
        direction = direction.normalized()
        var target_angle := atan2(-direction.x, -direction.z)
        rotation.y = lerp_angle(rotation.y, target_angle, turn_speed * delta)
    var running := (Input.is_action_pressed("sprint") or _mobile_sprint) and stamina > 1.0 and direction.length() > 0.1
    var speed := run_speed if running else walk_speed
    if running:
        stamina = maxf(0.0, stamina - delta * 18.0)
    else:
        stamina = minf(100.0, stamina + delta * 11.0)
    var target_velocity := direction * speed
    velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
    velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
    if not is_on_floor():
        velocity.y -= 22.0 * delta
    elif Input.is_action_just_pressed("jump") or _jump_requested:
        velocity.y = 5.0
    else:
        velocity.y = -0.2
    _jump_requested = false
    move_and_slide()
    if _camera_pivot:
        _camera_pivot.global_position = global_position + Vector3(0, 1.65, 0)
    if _visual:
        var moving := direction.length() > 0.1
        _visual.position.y = 0.04 * sin(Time.get_ticks_msec() * 0.012) if moving else 0.0

func set_mobile_move(value: Vector2) -> void:
    _mobile_move = value.limit_length(1.0)

func set_mobile_sprint(value: bool) -> void:
    _mobile_sprint = value

func request_mobile_jump() -> void:
    _jump_requested = true

func request_mobile_attack() -> void:
    _attack_requested = true

func request_mobile_pickup() -> void:
    _pickup_requested = true

func eat_food() -> bool:
    if food_count <= 0:
        return false
    food_count -= 1
    hunger = minf(100.0, hunger + 35.0)
    health = minf(100.0, health + 15.0)
    return true

func get_status() -> Dictionary:
    return {"health": health, "hunger": hunger, "thirst": thirst, "stamina": stamina, "food": food_count}

func _attack_nearest_prey() -> void:
    if _attack_cooldown > 0.0:
        return
    var nearest: Node3D = null
    var nearest_distance := 2.8
    for animal in get_tree().get_nodes_in_group("prey"):
        var distance := global_position.distance_to(animal.global_position)
        if distance < nearest_distance:
            nearest = animal
            nearest_distance = distance
    if nearest and nearest.has_method("take_damage"):
        nearest.take_damage(30.0)
        _attack_cooldown = 0.75

func _pick_up_nearest_food() -> void:
    var nearest: Node3D = null
    var nearest_distance := 2.5
    for item in get_tree().get_nodes_in_group("food_pickups"):
        var distance := global_position.distance_to(item.global_position)
        if distance < nearest_distance:
            nearest = item
            nearest_distance = distance
    if nearest:
        food_count += 1
        nearest.queue_free()

func _create_camera() -> void:
    _camera_pivot = Node3D.new()
    _camera_pivot.top_level = true
    _camera_pivot.global_position = global_position + Vector3(0, 1.65, 0)
    add_child(_camera_pivot)
    _camera = Camera3D.new()
    _camera.position = Vector3(0, 2.3, 6.8)
    _camera.rotation_degrees.x = -13
    _camera.current = true
    _camera.fov = 72
    _camera_pivot.add_child(_camera)

func _create_body() -> void:
    _visual = Node3D.new()
    _visual.name = "WolfVisual"
    add_child(_visual)
    var grey := _mat(Color(0.34, 0.36, 0.35))
    var dark := _mat(Color(0.16, 0.18, 0.18))
    var pale := _mat(Color(0.66, 0.65, 0.59))
    var eye := _mat(Color(0.95, 0.67, 0.12), 0.1)
    _part("Torso", Vector3(0, 0.88, 0.05), Vector3(0.62, 0.52, 1.18), grey)
    _part("Chest", Vector3(0, 0.92, -0.57), Vector3(0.57, 0.63, 0.55), pale)
    _part("Neck", Vector3(0, 1.16, -0.72), Vector3(0.48, 0.56, 0.58), grey)
    _part("Head", Vector3(0, 1.38, -1.02), Vector3(0.48, 0.43, 0.56), grey)
    _part("Muzzle", Vector3(0, 1.24, -1.43), Vector3(0.29, 0.22, 0.48), pale)
    _part("Nose", Vector3(0, 1.28, -1.68), Vector3(0.13, 0.12, 0.12), dark)
    _part("EarL", Vector3(-0.28, 1.78, -0.91), Vector3(0.18, 0.42, 0.17), dark, Vector3(-12, 0, -12))
    _part("EarR", Vector3(0.28, 1.78, -0.91), Vector3(0.18, 0.42, 0.17), dark, Vector3(-12, 0, 12))
    _part("EyeL", Vector3(-0.22, 1.48, -1.34), Vector3(0.07, 0.07, 0.045), eye)
    _part("EyeR", Vector3(0.22, 1.48, -1.34), Vector3(0.07, 0.07, 0.045), eye)
    for x in [-0.36, 0.36]:
        for z in [-0.62, 0.72]:
            _part("Leg", Vector3(x, 0.42, z), Vector3(0.19, 0.68, 0.22), grey)
            _part("Paw", Vector3(x, 0.12, z - 0.04), Vector3(0.24, 0.16, 0.32), dark)
    _part("Tail", Vector3(0, 0.95, 0.88), Vector3(0.24, 0.25, 0.72), dark, Vector3(-22, 0, 0))

func _part(label: String, pos: Vector3, size: Vector3, material: Material, rot := Vector3.ZERO) -> void:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = label
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    mesh_instance.mesh = mesh
    mesh_instance.position = pos
    mesh_instance.scale = size
    mesh_instance.rotation_degrees = rot
    mesh_instance.material_override = material
    _visual.add_child(mesh_instance)

func _mat(color: Color, metallic := 0.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.92
    material.metallic = metallic
    return material
