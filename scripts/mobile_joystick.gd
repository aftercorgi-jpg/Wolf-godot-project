extends Control

var output := Vector2.ZERO
var _finger_id := -1
var _mouse_active := false
var _knob := Vector2.ZERO
const DEADZONE := 0.12
const RADIUS := 66.0

func _ready() -> void:
    custom_minimum_size = Vector2(170, 170)
    size = custom_minimum_size
    mouse_filter = Control.MOUSE_FILTER_STOP
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and _finger_id == -1:
            _finger_id = event.index
            _update_stick(event.position)
            accept_event()
        elif not event.pressed and event.index == _finger_id:
            _finger_id = -1
            _release_stick()
            accept_event()
    elif event is InputEventScreenDrag and event.index == _finger_id:
        _update_stick(event.position)
        accept_event()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        _mouse_active = event.pressed
        if _mouse_active:
            _update_stick(event.position)
        else:
            _release_stick()
        accept_event()
    elif event is InputEventMouseMotion and _mouse_active:
        _update_stick(event.position)
        accept_event()

func _update_stick(point: Vector2) -> void:
    var center := size * 0.5
    var delta := point - center
    _knob = delta.limit_length(RADIUS)
    output = _knob / RADIUS
    if output.length() < DEADZONE:
        output = Vector2.ZERO
    queue_redraw()

func _release_stick() -> void:
    output = Vector2.ZERO
    _knob = Vector2.ZERO
    queue_redraw()

func _draw() -> void:
    var center := size * 0.5
    draw_circle(center, RADIUS + 8.0, Color(0.03, 0.05, 0.04, 0.35))
    draw_circle(center, RADIUS, Color(0.16, 0.20, 0.16, 0.62))
    draw_arc(center, RADIUS, 0.0, TAU, 48, Color(0.82, 0.88, 0.78, 0.75), 3.0)
    draw_circle(center + _knob, 29.0, Color(0.78, 0.84, 0.72, 0.88))
    draw_arc(center + _knob, 29.0, 0.0, TAU, 32, Color(1, 1, 1, 0.9), 2.0)
