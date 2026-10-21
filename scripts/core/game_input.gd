class_name GameInput
extends Node
## Input global. Letak satu node ni dalam scene utama.
## Daftar kekunci papan kekunci untuk uji di PC, dan kumpul seretan kamera
## dari skrin sentuh atau tetikus.

## Kekunci untuk setiap aksi. Kawalan sentuh guna aksi yang sama.
const KEYS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"cast": [KEY_SPACE],
	"reel": [KEY_SHIFT, KEY_E],
	"toggle_camera": [KEY_V],
}

## Seretan kamera (piksel) yang terkumpul sejak kali terakhir dibaca.
static var look_delta := Vector2.ZERO


func _ready() -> void:
	for action in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for key in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


func _input(event: InputEvent) -> void:
	# Di PC: tahan butang kanan tetikus dan gerak untuk pusing kamera.
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
		look_delta += event.relative


## Ambil seretan kamera dan kosongkan semula.
static func consume_look() -> Vector2:
	var d := look_delta
	look_delta = Vector2.ZERO
	return d
