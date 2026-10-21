extends Control
## Kawalan sentuh untuk fon:
##   kiri bawah  = joystick berjalan
##   separuh kanan = seret untuk pusing kamera
##   kanan bawah = butang LONTAR dan GULUNG, kanan atas = KAMERA
## Setiap jari dijejak berasingan, jadi boleh jalan dan pusing serentak.
## Di PC, klik tetikus dikira sebagai sentuhan (emulate_touch_from_mouse).

@export var look_sensitivity := 1.0

const BUTTONS := {
	"cast": "LONTAR",
	"reel": "GULUNG",
	"toggle_camera": "KAMERA",
}

var _fingers := {}  # indeks jari -> peranan ("stick", "look", atau nama aksi)
var _stick := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _layout() -> Dictionary:
	var s := size
	var u := minf(s.x, s.y) / 720.0
	return {
		"stick": [Vector2(190 * u, s.y - 190 * u), 120.0 * u],
		"cast": [Vector2(s.x - 170 * u, s.y - 180 * u), 95.0 * u],
		"reel": [Vector2(s.x - 390 * u, s.y - 120 * u), 85.0 * u],
		"toggle_camera": [Vector2(s.x - 90 * u, 90 * u), 50.0 * u],
	}


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var role := _hit(event.position)
			if role == "":
				return
			_fingers[event.index] = role
			if role == "stick":
				_update_stick(event.position)
			elif role != "look":
				Input.action_press(role)
		else:
			var role: String = _fingers.get(event.index, "")
			_fingers.erase(event.index)
			if role == "stick":
				_update_stick(_layout()["stick"][0])
			elif role in BUTTONS:
				Input.action_release(role)
		queue_redraw()

	elif event is InputEventScreenDrag:
		var role: String = _fingers.get(event.index, "")
		if role == "stick":
			_update_stick(event.position)
			queue_redraw()
		elif role == "look":
			GameInput.look_delta += event.relative * look_sensitivity


func _hit(pos: Vector2) -> String:
	var lay := _layout()
	for role in BUTTONS:
		if pos.distance_to(lay[role][0]) <= lay[role][1]:
			return role
	if pos.distance_to(lay["stick"][0]) <= lay["stick"][1] * 1.5:
		return "stick"
	if pos.x > size.x * 0.4:
		return "look"
	return ""


func _update_stick(pos: Vector2) -> void:
	var lay := _layout()
	var center: Vector2 = lay["stick"][0]
	var radius: float = lay["stick"][1]
	_stick = ((pos - center) / radius).limit_length(1.0)
	_set_axis("move_right", "move_left", _stick.x)
	_set_axis("move_back", "move_forward", _stick.y)


func _set_axis(pos_action: String, neg_action: String, v: float) -> void:
	if v > 0.05:
		Input.action_press(pos_action, v)
		Input.action_release(neg_action)
	elif v < -0.05:
		Input.action_press(neg_action, -v)
		Input.action_release(pos_action)
	else:
		Input.action_release(pos_action)
		Input.action_release(neg_action)


func _draw() -> void:
	var lay := _layout()
	var font := ThemeDB.fallback_font
	var held := _fingers.values()

	var c: Vector2 = lay["stick"][0]
	var r: float = lay["stick"][1]
	draw_circle(c, r, Color(1, 1, 1, 0.15))
	draw_arc(c, r, 0, TAU, 40, Color(1, 1, 1, 0.4), 3.0)
	draw_circle(c + _stick * r, r * 0.42, Color(1, 1, 1, 0.5))

	for role in BUTTONS:
		var bc: Vector2 = lay[role][0]
		var br: float = lay[role][1]
		var on: bool = role in held
		draw_circle(bc, br, Color(1, 1, 1, 0.45) if on else Color(0, 0, 0, 0.3))
		draw_arc(bc, br, 0, TAU, 40, Color(1, 1, 1, 0.7), 3.0)
		var fs := int(br * 0.36)
		draw_string(font, bc + Vector2(-br, fs * 0.35), BUTTONS[role], HORIZONTAL_ALIGNMENT_CENTER, br * 2.0, fs)
