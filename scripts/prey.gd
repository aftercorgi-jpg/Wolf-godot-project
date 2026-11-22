extends CharacterBody3D

@export var animal_kind := "Олень"
@export var max_health := 60.0
var health := 60.0
var _wander_dir := Vector3.ZERO
var _change_timer := 0.0
var _visual: Node3D
var _health_label: Label3D
var _is_dead := false

func _ready() -> void:
    add_to_group("prey")
    health = max_health
    _build_animal()
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.42
    capsule.height = 1.15
    collision.shape = capsule
    collision.position.y = 0.58
    add_child(collision)
    _health_label = Label3D.new()
    _health_label.position = Vector3(0, 2.0, 0)
    _health_label.font_size = 32
    _health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    _health_label.text = animal_kind + "  " + str(int(health))
    add_child(_health_label)
    _pick_direction()

func _physics_process(delta: float) -> void:
    _change_timer -= delta
    if _change_timer <= 0.0:
        _pick_direction()
    velocity.x = move_toward(velocity.x, _wander_dir.x * 1.4, delta * 3.0)
    velocity.z = move_toward(velocity.z, _wander_dir.z * 1.4, delta * 3.0)
    if _wander_dir.length() > 0.1:
        rotation.y = lerp_angle(rotation.y, atan2(_wander_dir.x, _wander_dir.z), delta * 3.0)
    if not is_on_floor():
        velocity.y -= 22.0 * delta
    else:
        velocity.y = -0.2
    move_and_slide()

func _pick_direction() -> void:
    _change_timer = randf_range(2.0, 5.0)
    var angle := randf() * TAU
    _wander_dir = Vector3(cos(angle), 0, sin(angle))

func take_damage(amount: float) -> void:
    if _is_dead:
        return
    health = maxf(0.0, health - amount)
    if is_instance_valid(_health_label):
        _health_label.text = animal_kind + "  " + str(int(health))
    if health <= 0.0:
        _is_dead = true
        var scene := get_tree().current_scene
        if is_instance_valid(scene) and scene.has_method("spawn_food_drop"):
            # The wolf attacks from _physics_process. Defer adding the meat
            # until Godot has finished the current physics update.
            scene.call_deferred("spawn_food_drop", global_position)
        queue_free()

func _build_animal() -> void:
    _visual = Node3D.new()
    add_child(_visual)
    var brown := _material(Color(0.42, 0.25, 0.12) if animal_kind == "Олень" else Color(0.48, 0.40, 0.32))
    var cream := _material(Color(0.78, 0.68, 0.52))
    var dark := _material(Color(0.12, 0.10, 0.08))
    var scale_factor := 0.62 if animal_kind == "Заяц" else 1.0
    _shape("Body", Vector3(0, 0.85, 0), Vector3(0.62, 0.62, 1.05) * scale_factor, brown)
    _shape("Head", Vector3(0, 1.05, -0.72) * scale_factor, Vector3(0.42, 0.42, 0.42) * scale_factor, brown)
    _shape("Muzzle", Vector3(0, 0.94, -0.98) * scale_factor, Vector3(0.26, 0.20, 0.28) * scale_factor, cream)
    for x in [-0.22, 0.22]:
        _shape("Eye", Vector3(x, 1.14, -0.91) * scale_factor, Vector3(0.07, 0.07, 0.05) * scale_factor, dark)
    for x in [-0.22, 0.22]:
        for z in [-0.35, 0.36]:
            _shape("Leg", Vector3(x, 0.38, z) * scale_factor, Vector3(0.13, 0.58, 0.14) * scale_factor, brown)
    if animal_kind == "Олень":
        _shape("EarL", Vector3(-0.25, 1.35, -0.7), Vector3(0.12, 0.34, 0.12), cream, Vector3(0, 0, -25))
        _shape("EarR", Vector3(0.25, 1.35, -0.7), Vector3(0.12, 0.34, 0.12), cream, Vector3(0, 0, 25))
    else:
        _shape("EarL", Vector3(-0.14, 1.55, -0.67) * scale_factor, Vector3(0.13, 0.52, 0.12) * scale_factor, brown, Vector3(0, 0, -8))
        _shape("EarR", Vector3(0.14, 1.55, -0.67) * scale_factor, Vector3(0.13, 0.52, 0.12) * scale_factor, brown, Vector3(0, 0, 8))
    _shape("Tail", Vector3(0, 0.95, 0.58) * scale_factor, Vector3(0.20, 0.22, 0.28) * scale_factor, cream)

func _shape(label: String, pos: Vector3, size: Vector3, material: Material, rot := Vector3.ZERO) -> void:
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

func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.95
    return material
