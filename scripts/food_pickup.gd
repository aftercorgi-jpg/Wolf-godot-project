extends Area3D

func _ready() -> void:
    add_to_group("food_pickups")
    var mesh_instance := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.24
    mesh.height = 0.38
    mesh_instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.62, 0.16, 0.12)
    material.roughness = 0.85
    mesh_instance.material_override = material
    add_child(mesh_instance)
    var glow := OmniLight3D.new()
    glow.light_color = Color(1.0, 0.25, 0.12)
    glow.light_energy = 0.35
    glow.omni_range = 2.0
    add_child(glow)
