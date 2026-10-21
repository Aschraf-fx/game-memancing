class_name FishingLine
extends MeshInstance3D
## Lukis tali pancing dari hujung joran ke pelampung. Tali melendut bila kendur.

@export var angler: Angler
@export var bobber: Bobber
@export var segments := 20
@export var width := 0.025
@export var max_sag := 1.2

## 0 = kendur, 1 = tegang habis. Diset oleh FishingRod.
var tension := 0.0

var _im := ImmediateMesh.new()


func _ready() -> void:
	mesh = _im
	top_level = true
	global_transform = Transform3D.IDENTITY
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.95, 0.95, 0.9, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = mat


func _process(_delta: float) -> void:
	_im.clear_surfaces()
	var cam := get_viewport().get_camera_3d()
	if not bobber.visible or cam == null:
		return

	var a := angler.rod_tip.get_global_transform_interpolated().origin
	var b := bobber.global_position + Vector3.UP * 0.06
	var sag := max_sag * (1.0 - tension) * clampf(a.distance_to(b) / 10.0, 0.0, 1.0)
	var mid := (a + b) * 0.5 + Vector3.DOWN * sag * 2.0

	# Reben nipis yang sentiasa menghadap kamera (garisan 1 piksel terlalu halus di fon).
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var prev := a
	for i in segments:
		var t := i / float(segments - 1)
		# Lengkung Bezier kuadratik
		var p := (1.0 - t) * (1.0 - t) * a + 2.0 * (1.0 - t) * t * mid + t * t * b
		var dir := (p - prev).normalized() if i > 0 else (mid - a).normalized()
		var side := dir.cross(cam.global_position - p).normalized() * width * 0.5
		_im.surface_add_vertex(p - side)
		_im.surface_add_vertex(p + side)
		prev = p
	_im.surface_end()
