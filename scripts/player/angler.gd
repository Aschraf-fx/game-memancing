class_name Angler
extends CharacterBody3D
## Pemain: berjalan, pusing kamera dan tukar FPV/TPV.

enum CamMode { FIRST_PERSON, THIRD_PERSON }

@export var walk_speed := 2.5
## Darjah pusingan untuk setiap piksel seretan.
@export var look_sensitivity := 0.25
@export var min_pitch := -60.0
@export var max_pitch := 70.0
@export var cam_mode := CamMode.THIRD_PERSON
@export var tpv_distance := 3.5
@export var tpv_shoulder := 0.7

## Dikunci semasa lontar dan tarik-tali.
var movement_locked := false
## 0 - 1, diset oleh FishingRod supaya joran melentur ikut ketegangan tali.
var rod_bend := 0.0

@onready var head: Node3D = $Head
@onready var spring_arm: SpringArm3D = $Head/SpringArm3D
@onready var body: Node3D = $Body
@onready var rod_pivot: Node3D = $RodPivot
@onready var rod_tip: Marker3D = $RodPivot/RodTip

var _rod_rest_pitch := 0.0
var _walk_t := 0.0


func _ready() -> void:
	_rod_rest_pitch = rod_pivot.rotation.x
	spring_arm.add_excluded_object(get_rid())
	_apply_cam_mode()


func toggle_camera() -> void:
	cam_mode = CamMode.FIRST_PERSON if cam_mode == CamMode.THIRD_PERSON else CamMode.THIRD_PERSON
	_apply_cam_mode()


func _apply_cam_mode() -> void:
	var fpv := cam_mode == CamMode.FIRST_PERSON
	spring_arm.spring_length = 0.0 if fpv else tpv_distance
	spring_arm.position = Vector3.ZERO if fpv else Vector3(tpv_shoulder, 0.45, 0.0)
	# Dalam FPV badan disorok tapi bayang masih ada.
	for m in body.find_children("*", "GeometryInstance3D"):
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if fpv \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_camera"):
		toggle_camera()

	var look := GameInput.consume_look() * look_sensitivity
	rotate_y(deg_to_rad(-look.x))
	head.rotation.x = clampf(head.rotation.x - deg_to_rad(look.y), deg_to_rad(min_pitch), deg_to_rad(max_pitch))

	rod_pivot.rotation.x = _rod_rest_pitch - rod_bend * deg_to_rad(30.0)

	# Badan terangguk sikit masa berjalan.
	var speed := Vector2(velocity.x, velocity.z).length()
	_walk_t += delta * speed * 4.0
	body.position.y = absf(sin(_walk_t)) * 0.04 if speed > 0.1 else 0.0


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if not movement_locked:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := transform.basis * Vector3(input.x, 0.0, input.y)
	velocity.x = dir.x * walk_speed
	velocity.z = dir.z * walk_speed
	if is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= 9.8 * delta
	move_and_slide()
