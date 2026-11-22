extends CanvasLayer

var wolf: CharacterBody3D
var bars: Dictionary = {}
var joystick: Control
var sprint_button: Button
var jump_button: Button
var inventory_label: Label
var eat_button: Button

func _ready() -> void:
    wolf = get_parent().get_node("PlayerWolf")
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(root)

    var title := Label.new()
    title.text = "WOLF SURVIVAL  •  ДИКАЯ ПРИРОДА"
    title.position = Vector2(24, 14)
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color.WHITE)
    root.add_child(title)

    var stats_panel := PanelContainer.new()
    stats_panel.position = Vector2(22, 52)
    stats_panel.custom_minimum_size = Vector2(260, 168)
    root.add_child(stats_panel)
    var stats_column := VBoxContainer.new()
    stats_column.add_theme_constant_override("separation", 6)
    stats_panel.add_child(stats_column)
    _add_stat(stats_column, "Здоровье", "health")
    _add_stat(stats_column, "Голод", "hunger")
    _add_stat(stats_column, "Жажда", "thirst")
    _add_stat(stats_column, "Выносливость", "stamina")

    var inventory_panel := PanelContainer.new()
    inventory_panel.anchor_left = 1.0
    inventory_panel.anchor_right = 1.0
    inventory_panel.offset_left = -225
    inventory_panel.offset_right = -20
    inventory_panel.offset_top = 20
    inventory_panel.offset_bottom = 92
    root.add_child(inventory_panel)
    var inventory_column := VBoxContainer.new()
    inventory_panel.add_child(inventory_column)
    var inventory_title := Label.new()
    inventory_title.text = "ИНВЕНТАРЬ • ЕДА"
    inventory_title.add_theme_font_size_override("font_size", 17)
    inventory_column.add_child(inventory_title)
    inventory_label = Label.new()
    inventory_label.text = "Мясо: 0"
    inventory_column.add_child(inventory_label)

    var hint := Label.new()
    hint.text = "Подойди к животному, атакуй, подбери мясо и съешь его"
    hint.position = Vector2(0, 100)
    hint.size = Vector2(1280, 28)
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_color_override("font_color", Color.WHITE)
    hint.add_theme_font_size_override("font_size", 16)
    root.add_child(hint)

    _create_mobile_controls(root)

func _create_mobile_controls(root: Control) -> void:
    var joystick_script = load("res://scripts/mobile_joystick.gd")
    joystick = Control.new()
    joystick.set_script(joystick_script)
    joystick.name = "MobileJoystick"
    joystick.anchor_left = 0.025
    joystick.anchor_top = 1.0
    joystick.offset_left = 0
    joystick.offset_top = -190
    joystick.offset_right = 170
    joystick.offset_bottom = -20
    root.add_child(joystick)

    sprint_button = _make_button(root, "БЕГ", -155, -105, 125, 70)
    jump_button = _make_button(root, "ПРЫЖОК", -155, -190, 125, 70)
    var attack_button := _make_button(root, "АТАКА", -300, -190, 125, 70)
    var pickup_button := _make_button(root, "ВЗЯТЬ", -300, -105, 125, 70)
    eat_button = _make_button(root, "СЪЕСТЬ", -300, -275, 125, 70)

    sprint_button.button_down.connect(func(): wolf.set_mobile_sprint(true))
    sprint_button.button_up.connect(func(): wolf.set_mobile_sprint(false))
    jump_button.pressed.connect(func(): wolf.request_mobile_jump())
    attack_button.pressed.connect(func(): wolf.request_mobile_attack())
    pickup_button.pressed.connect(func(): wolf.request_mobile_pickup())
    eat_button.pressed.connect(func(): wolf.eat_food())

func _make_button(root: Control, caption: String, right_offset: float, bottom_offset: float, width: float, height: float) -> Button:
    var button := Button.new()
    button.text = caption
    button.anchor_left = 1.0
    button.anchor_top = 1.0
    button.anchor_right = 1.0
    button.anchor_bottom = 1.0
    button.offset_left = right_offset
    button.offset_top = bottom_offset
    button.offset_right = right_offset + width
    button.offset_bottom = bottom_offset + height
    button.add_theme_font_size_override("font_size", 18)
    button.add_theme_color_override("font_color", Color.WHITE)
    button.add_theme_stylebox_override("normal", _button_style(Color(0.13, 0.22, 0.13, 0.88)))
    button.add_theme_stylebox_override("pressed", _button_style(Color(0.32, 0.46, 0.23, 0.98)))
    button.add_theme_stylebox_override("hover", _button_style(Color(0.22, 0.34, 0.19, 0.92)))
    root.add_child(button)
    return button

func _button_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.corner_radius_top_left = 16
    style.corner_radius_top_right = 16
    style.corner_radius_bottom_left = 16
    style.corner_radius_bottom_right = 16
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.border_color = Color(0.85, 0.9, 0.78, 0.85)
    return style

func _add_stat(parent: VBoxContainer, caption: String, key: String) -> void:
    var row := HBoxContainer.new()
    parent.add_child(row)
    var label := Label.new()
    label.text = caption
    label.custom_minimum_size.x = 112
    row.add_child(label)
    var bar := ProgressBar.new()
    bar.custom_minimum_size = Vector2(125, 18)
    bar.max_value = 100
    bar.value = 100
    row.add_child(bar)
    bars[key] = bar

func _process(_delta: float) -> void:
    if not is_instance_valid(wolf):
        return
    var status: Dictionary = wolf.get_status()
    for key in bars:
        bars[key].value = status[key]
    inventory_label.text = "Мясо: " + str(status["food"])
    eat_button.disabled = int(status["food"]) <= 0
    if is_instance_valid(joystick):
        wolf.set_mobile_move(joystick.output)
