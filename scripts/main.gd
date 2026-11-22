extends Node3D

const WolfScript = preload("res://scripts/wolf.gd")
const HudScript = preload("res://scripts/hud.gd")
const PreyScript = preload("res://scripts/prey.gd")
const FoodPickupScript = preload("res://scripts/food_pickup.gd")

func _ready() -> void:
    _build_environment()
    var wolf := CharacterBody3D.new()
    wolf.name = "PlayerWolf"
    wolf.set_script(WolfScript)
    add_child(wolf)
    wolf.position = Vector3(0, 0.12, 0)

    # Wildlife spawns around the starting clearing.
    var animal_spawns := [
        Vector3(9, 0.12, -10), Vector3(-12, 0.12, -8),
        Vector3(15, 0.12, 11), Vector3(-16, 0.12, 13),
        Vector3(3, 0.12, 19), Vector3(-20, 0.12, -17)
    ]
    for i in range(animal_spawns.size()):
        var animal := CharacterBody3D.new()
        animal.set_script(PreyScript)
        animal.animal_kind = "Заяц" if i % 3 == 0 else "Олень"
        animal.name = "Prey_" + str(i + 1)
        add_child(animal)
        animal.global_position = animal_spawns[i]

    var hud := CanvasLayer.new()
    hud.name = "HUD"
    hud.set_script(HudScript)
    add_child(hud)

func _build_environment() -> void:
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    env.sky.sky_material = ProceduralSkyMaterial.new()
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.62, 0.68, 0.58)
    env.ambient_light_energy = 0.8
    world_env.environment = env
    add_child(world_env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -32, 0)
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    add_child(sun)

    var ground := StaticBody3D.new()
    ground.name = "ForestGround"
    var ground_mesh := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(180, 180)
    ground_mesh.mesh = plane
    var grass := StandardMaterial3D.new()
    grass.albedo_color = Color(0.19, 0.29, 0.16)
    grass.roughness = 1.0
    ground_mesh.material_override = grass
    ground.add_child(ground_mesh)
    var col := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(180, 0.2, 180)
    col.shape = shape
    col.position.y = -0.1
    ground.add_child(col)
    add_child(ground)

    # A simple clearing with procedural low-poly trees around it.
    for x in range(-8, 9):
        for z in range(-8, 9):
            if abs(x) < 3 and abs(z) < 3:
                continue
            if (x * 17 + z * 31) % 3 == 0:
                _make_tree(Vector3(x * 5.0, 0, z * 5.0))

    # Stones and fallen logs add landmarks to the starting area.
    for i in range(18):
        var rock := MeshInstance3D.new()
        var m := SphereMesh.new()
        m.radius = 0.55 + float(i % 3) * 0.18
        m.height = m.radius * 1.25
        rock.mesh = m
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(0.27, 0.29, 0.25)
        rock.material_override = mat
        rock.position = Vector3(sin(i * 4.1) * 24.0, 0.3, cos(i * 2.7) * 24.0)
        rock.scale = Vector3(1.4, 0.7, 1.0)
        add_child(rock)

func _make_tree(pos: Vector3) -> void:
    var tree := StaticBody3D.new()
    tree.position = pos
    var trunk := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.22
    cylinder.bottom_radius = 0.38
    cylinder.height = 3.3
    trunk.mesh = cylinder
    var bark := StandardMaterial3D.new()
    bark.albedo_color = Color(0.24, 0.16, 0.10)
    trunk.material_override = bark
    trunk.position.y = 1.65
    tree.add_child(trunk)
    var crown := MeshInstance3D.new()
    var cone := PrismMesh.new()
    cone.size = Vector3(3.0, 4.4, 3.0)
    crown.mesh = cone
    var leaves := StandardMaterial3D.new()
    leaves.albedo_color = Color(0.10, 0.23, 0.12)
    crown.material_override = leaves
    crown.position.y = 4.0
    tree.add_child(crown)
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.48
    capsule.height = 3.5
    collision.shape = capsule
    collision.position.y = 1.7
    tree.add_child(collision)
    add_child(tree)

func spawn_food_drop(at_position: Vector3) -> void:
    var food := Area3D.new()
    food.name = "MeatPickup"
    food.set_script(FoodPickupScript)
    food.position = at_position + Vector3(0, 0.35, 0)
    add_child(food)
