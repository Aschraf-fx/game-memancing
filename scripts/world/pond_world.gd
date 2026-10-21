@tool
class_name PondWorld
extends Node3D
## Jana kawasan kolam kampung low-poly: tanah, pokok kelapa, pokok rendang,
## batu, rumput tebing, teratai, pangkalan kayu dan pondok.
## Ubah nilai dalam Inspector dan tekan "Regenerate" untuk tengok hasil.

@export var world_size := 160.0
@export var cell_size := 2.0
## Jejari kolam (x, z) dalam meter.
@export var pond_radius := Vector2(24.0, 18.0)
@export var pond_depth := 2.2
@export var world_seed := 7
@export_tool_button("Regenerate") var regenerate_action = regenerate

var _noise := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()
var _mats := {}


func _ready() -> void:
	regenerate()


func regenerate() -> void:
	for c in get_children():
		c.queue_free()
	_mats.clear()
	_noise.seed = world_seed
	_noise.frequency = 0.04
	_rng.seed = world_seed
	_build_ground()
	_build_bounds()
	_build_jetty()
	_build_hut(Vector3(20.0, 0.0, 28.0), deg_to_rad(-30.0))
	_scatter()


## Ketinggian tanah pada (x, z). Paras air = 0.
func height_at(x: float, z: float) -> float:
	var d := _pond_d(x, z)
	if d < 1.0:
		return lerpf(-pond_depth, 0.3, smoothstep(0.35, 1.0, d))
	var n := _noise.get_noise_2d(x, z) * 0.8 * smoothstep(1.0, 1.4, d)
	var hills := smoothstep(2.2, 3.6, d) * 7.0
	return 0.3 + (d - 1.0) * 0.6 + n + hills


## Jarak ternormal dari tengah kolam: < 1 dalam air, 1 = tebing.
func _pond_d(x: float, z: float) -> float:
	var d := Vector2(x / pond_radius.x, z / pond_radius.y).length()
	return d + _noise.get_noise_2d(x * 0.5 + 100.0, z * 0.5) * 0.12


func _build_ground() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := int(world_size / cell_size)
	var half := world_size * 0.5
	for ix in n:
		for iz in n:
			var x0 := -half + ix * cell_size
			var z0 := -half + iz * cell_size
			var x1 := x0 + cell_size
			var z1 := z0 + cell_size
			var a := Vector3(x0, height_at(x0, z0), z0)
			var b := Vector3(x1, height_at(x1, z0), z0)
			var c := Vector3(x0, height_at(x0, z1), z1)
			var d := Vector3(x1, height_at(x1, z1), z1)
			_tri(st, a, b, c)
			_tri(st, b, d, c)
	var mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, mat)

	var mi := MeshInstance3D.new()
	mi.name = "Ground"
	mi.mesh = mesh
	add_child(mi)

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var trimesh := mesh.create_trimesh_shape()
	trimesh.backface_collision = true
	shape.shape = trimesh
	body.add_child(shape)
	add_child(body)


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (c - a).cross(b - a).normalized()
	var h := (a.y + b.y + c.y) / 3.0
	var col := _ground_color(h, (a + b + c) / 3.0)
	st.set_normal(normal)
	# Warna vertex mesti linear; tukar sendiri supaya sama di semua renderer (web & fon).
	st.set_color(col.srgb_to_linear())
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


func _ground_color(h: float, p: Vector3) -> Color:
	var jitter := _noise.get_noise_2d(p.x * 3.0, p.z * 3.0) * 0.06
	var col: Color
	if h < -0.3:
		col = Color(0.42, 0.36, 0.24)  # lumpur dasar kolam
	elif h < 0.55:
		col = Color(0.80, 0.70, 0.48)  # pasir tebing
	elif h < 3.0:
		col = Color(0.36, 0.62, 0.26)  # rumput
	else:
		col = Color(0.24, 0.48, 0.22)  # bukit
	return col.lightened(jitter) if jitter > 0.0 else col.darkened(-jitter)


func _build_bounds() -> void:
	# Dinding halimunan supaya pemain tak keluar peta.
	var half := world_size * 0.5 - 6.0
	for i in 4:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(world_size, 40.0, 1.0)
		shape.shape = box
		body.add_child(shape)
		body.rotation.y = i * PI / 2.0
		body.position = Vector3(0, 10, half).rotated(Vector3.UP, i * PI / 2.0)
		add_child(body)


func _build_jetty() -> void:
	# Pangkalan kayu dari tebing selatan masuk ke kolam.
	var wood := _mat(Color(0.55, 0.38, 0.22))
	var dark := _mat(Color(0.38, 0.26, 0.16))
	var deck_y := 0.55
	var z_start := 22.0
	var z_end := 13.0
	var length := z_start - z_end
	var center := Vector3(0.0, deck_y, (z_start + z_end) * 0.5)

	var planks := int(length / 0.4)
	for i in planks:
		var z := z_end + 0.2 + i * 0.4
		var tilt := _rng.randf_range(-0.02, 0.02)
		_box(Vector3(2.0, 0.08, 0.36), Vector3(0, deck_y - 0.04, z), wood if i % 3 else dark, Vector3(0, 0, tilt))
	for z in [z_end + 0.2, z_end + 3.0, z_end + 6.0, z_start - 0.4]:
		for x in [-0.95, 0.95]:
			_cylinder(0.08, 0.08, 3.0, Vector3(x, deck_y - 1.5, z), dark)

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 0.3, length)
	shape.shape = box
	body.position = center - Vector3(0, 0.15, 0)
	body.add_child(shape)
	add_child(body)


func _build_hut(pos: Vector3, rot_y: float) -> void:
	# Pondok rehat ringkas atas tiang.
	var root := Node3D.new()
	root.position = Vector3(pos.x, height_at(pos.x, pos.z), pos.z)
	root.rotation.y = rot_y
	add_child(root)
	var wood := _mat(Color(0.5, 0.34, 0.2))
	var attap := _mat(Color(0.62, 0.5, 0.3))
	for x in [-1.5, 1.5]:
		for z in [-1.2, 1.2]:
			_cylinder(0.1, 0.1, 2.6, Vector3(x, 1.3, z), wood, root)
	_box(Vector3(3.4, 0.15, 2.8), Vector3(0, 0.7, 0), wood, Vector3.ZERO, root)
	var roof := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(4.2, 1.4, 3.6)
	prism.material = attap
	roof.mesh = prism
	roof.position = Vector3(0, 3.3, 0)
	root.add_child(roof)

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.4, 0.8, 2.8)
	shape.shape = box
	body.position = Vector3(0, 0.4, 0)
	body.add_child(shape)
	root.add_child(body)


func _scatter() -> void:
	_place(10, 1.25, 2.0, _palm)
	_place(28, 1.6, 3.6, _round_tree)
	_place(16, 0.95, 1.3, _rock)
	_place(26, 0.88, 1.05, _reeds)
	_place_lilies(14)


## Letak objek secara rawak dalam gelang jarak [d_min, d_max] dari tengah kolam.
func _place(count: int, d_min: float, d_max: float, builder: Callable) -> void:
	var placed := 0
	var tries := 0
	while placed < count and tries < count * 30:
		tries += 1
		var ang := _rng.randf() * TAU
		var r := _rng.randf_range(d_min, d_max)
		var x := cos(ang) * pond_radius.x * r
		var z := sin(ang) * pond_radius.y * r
		# Jangan halang pangkalan dan laluan ke pondok.
		if absf(x) < 3.5 and z > 4.0:
			continue
		var d := _pond_d(x, z)
		if d < d_min or d > d_max:
			continue
		builder.call(Vector3(x, height_at(x, z), z))
		placed += 1


func _palm(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = _rng.randf() * TAU
	add_child(root)
	var trunk := _mat(Color(0.48, 0.38, 0.28))
	var leaf := _mat(Color(0.25, 0.55, 0.2))
	var lean := _rng.randf_range(0.05, 0.18)
	var top := Vector3.ZERO
	var seg_h := 1.4
	for i in 5:
		var seg := _cylinder(0.14 - i * 0.015, 0.16 - i * 0.015, seg_h, Vector3.ZERO, trunk, root)
		seg.rotation.x = lean * (i + 1) * 0.5
		seg.position = top + seg.basis.y * seg_h * 0.5
		top += seg.basis.y * seg_h
	for i in 7:
		var frond := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.5, 0.04, 2.4)
		bm.material = leaf
		frond.mesh = bm
		var pivot := Node3D.new()
		pivot.position = top
		pivot.rotation = Vector3(0, i * TAU / 7.0, 0)
		root.add_child(pivot)
		frond.position = Vector3(0, -0.4, 1.1)
		frond.rotation.x = deg_to_rad(28)
		pivot.add_child(frond)
	for i in 3:
		var nut := _sphere(0.12, top + Vector3(cos(i * 2.1), -0.2, sin(i * 2.1)) * 0.2, _mat(Color(0.35, 0.3, 0.12)), root)
		nut.position.y = top.y - 0.25
	_trunk_collider(root, 0.2, 7.0)


func _round_tree(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = _rng.randf() * TAU
	var s := _rng.randf_range(0.8, 1.4)
	root.scale = Vector3.ONE * s
	add_child(root)
	_cylinder(0.18, 0.25, 2.6, Vector3(0, 1.3, 0), _mat(Color(0.4, 0.28, 0.18)), root)
	var greens := [Color(0.2, 0.5, 0.2), Color(0.27, 0.56, 0.22), Color(0.18, 0.44, 0.24)]
	var g: Color = greens[_rng.randi() % greens.size()]
	for i in 3:
		var off := Vector3(_rng.randf_range(-0.6, 0.6), 2.9 + i * 0.5, _rng.randf_range(-0.6, 0.6))
		_sphere(_rng.randf_range(1.0, 1.4), off, _mat(g), root)
	_trunk_collider(root, 0.3, 3.0)


func _rock(pos: Vector3) -> void:
	var s := _rng.randf_range(0.4, 1.3)
	var m := _sphere(s, pos + Vector3(0, s * 0.2, 0), _mat(Color(0.5, 0.5, 0.48)))
	m.scale = Vector3(1.0, _rng.randf_range(0.5, 0.8), _rng.randf_range(0.8, 1.2))
	m.rotation.y = _rng.randf() * TAU
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = s * 0.7
	shape.shape = sph
	body.position = m.position
	body.add_child(shape)
	add_child(body)


func _reeds(pos: Vector3) -> void:
	var mat := _mat(Color(0.35, 0.55, 0.2))
	for i in _rng.randi_range(5, 9):
		var h := _rng.randf_range(0.6, 1.4)
		var off := Vector3(_rng.randf_range(-0.5, 0.5), h * 0.5, _rng.randf_range(-0.5, 0.5))
		var b := _box(Vector3(0.04, h, 0.04), pos + off, mat, Vector3(_rng.randf_range(-0.2, 0.2), 0, _rng.randf_range(-0.2, 0.2)))
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _place_lilies(count: int) -> void:
	var pad := _mat(Color(0.25, 0.5, 0.2))
	var flower := _mat(Color(0.95, 0.55, 0.75))
	for i in count:
		var ang := _rng.randf() * TAU
		var r := _rng.randf_range(0.45, 0.85)
		var p := Vector3(cos(ang) * pond_radius.x * r, 0.03, sin(ang) * pond_radius.y * r)
		if absf(p.x) < 2.5 and p.z > 4.0:
			continue
		_cylinder(0.35, 0.35, 0.02, p, pad)
		if _rng.randf() < 0.4:
			_sphere(0.1, p + Vector3(0, 0.08, 0), flower)


func _trunk_collider(root: Node3D, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	shape.shape = cyl
	shape.position.y = height * 0.5
	body.add_child(shape)
	root.add_child(body)


# --- Pembantu bina mesh ---

func _mat(color: Color) -> StandardMaterial3D:
	if not _mats.has(color):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.9
		_mats[color] = m
	return _mats[color]


func _box(size: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO, parent: Node3D = null) -> MeshInstance3D:
	if parent == null:
		parent = self
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = mat
	mi.mesh = bm
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


func _cylinder(top_r: float, bottom_r: float, h: float, pos: Vector3, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	if parent == null:
		parent = self
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bottom_r
	cm.height = h
	cm.radial_segments = 6
	cm.rings = 1
	cm.material = mat
	mi.mesh = cm
	mi.position = pos
	parent.add_child(mi)
	return mi


func _sphere(r: float, pos: Vector3, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	if parent == null:
		parent = self
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 7
	sm.rings = 4
	sm.material = mat
	mi.mesh = sm
	mi.position = pos
	parent.add_child(mi)
	return mi
