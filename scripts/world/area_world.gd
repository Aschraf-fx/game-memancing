@tool
class_name AreaWorld
extends Node3D
## Jana kawasan memancing low-poly ikut FishingArea: kolam, sungai, tasik,
## muara, pesisir pantai atau laut. Tanah, air, pokok, batu, pangkalan dan
## kenderaan (kayak, sampan, bot) semua dibina dengan kod, jadi tiada fail
## model dan saiz game web kekal kecil.
## Dalam editor: pilih kawasan dalam Inspector dan tekan "Regenerate".

## Lapisan fizik lantai dan pagar bot: pemain boleh pijak, pelampung dan kamera tembus.
const BOAT_LAYER := 16
## Lapisan kabin/konsol bot: pemain dan kamera tak boleh tembus, pelampung boleh.
const CABIN_LAYER := 32

## Bentuk tanah ikut jenis kawasan (indeks = FishingArea.Kind).
##   depth     = dalam air paling dalam (m)
##   shelf     = jarak dari tebing sampai air paling dalam (m)
##   slope     = kecuraman tanah naik dari tebing
##   hill_from = jarak dari tebing bukit mula naik, hill_h = tinggi bukit
##   bank      = lebar jalur pasir/lumpur/batu di tebing
##   island_h  = tinggi bukit atas pulau
const SHAPES := [
	{"depth": 2.2, "shelf": 8.0, "slope": 0.03, "hill_from": 24.0, "hill_h": 7.0, "bank": 2.5, "island_h": 0.0},
	{"depth": 3.0, "shelf": 5.0, "slope": 0.06, "hill_from": 14.0, "hill_h": 12.0, "bank": 3.0, "island_h": 0.0},
	{"depth": 6.0, "shelf": 10.0, "slope": 0.08, "hill_from": 8.0, "hill_h": 14.0, "bank": 4.0, "island_h": 5.0},
	{"depth": 3.0, "shelf": 10.0, "slope": 0.008, "hill_from": 45.0, "hill_h": 3.0, "bank": 2.0, "island_h": 0.0},
	{"depth": 6.0, "shelf": 25.0, "slope": 0.015, "hill_from": 32.0, "hill_h": 10.0, "bank": 14.0, "island_h": 9.0},
	{"depth": 25.0, "shelf": 30.0, "slope": 0.05, "hill_from": 4.0, "hill_h": 6.0, "bank": 4.0, "island_h": 14.0},
]

## Warna tanah: dasar air, tebing, rumput, bukit.
const PALETTES := [
	[Color(0.42, 0.36, 0.24), Color(0.80, 0.70, 0.48), Color(0.36, 0.62, 0.26), Color(0.24, 0.48, 0.22)],
	[Color(0.40, 0.36, 0.28), Color(0.62, 0.58, 0.50), Color(0.24, 0.52, 0.22), Color(0.16, 0.40, 0.20)],
	[Color(0.36, 0.30, 0.22), Color(0.72, 0.46, 0.30), Color(0.30, 0.56, 0.24), Color(0.18, 0.42, 0.22)],
	[Color(0.36, 0.32, 0.24), Color(0.46, 0.38, 0.28), Color(0.32, 0.50, 0.24), Color(0.26, 0.44, 0.22)],
	[Color(0.70, 0.64, 0.46), Color(0.94, 0.86, 0.64), Color(0.40, 0.62, 0.28), Color(0.26, 0.48, 0.22)],
	[Color(0.40, 0.40, 0.36), Color(0.86, 0.80, 0.62), Color(0.34, 0.58, 0.26), Color(0.30, 0.50, 0.24)],
]

## Pulau (x, z, jejari) untuk tasik, pantai dan laut.
const ISLANDS := {
	FishingArea.Kind.TASIK: [Vector3(-28, -34, 9), Vector3(26, -46, 7), Vector3(-42, 12, 6)],
	FishingArea.Kind.PANTAI: [Vector3(-30, -55, 10), Vector3(34, -62, 12)],
	FishingArea.Kind.LAUT: [Vector3(-48, -62, 12)],
}

@export var area: FishingArea
## 0 kaki, 1 kayak, 2 sampan, 3 bot kecil, 4 bot laut dalam.
@export_range(0, 4) var vehicle_tier := 0
## Air (kawasan ikan): saiz, warna dan senarai ikan ditetapkan ikut kawasan.
@export var water: FishPool
@export var environment: WorldEnvironment
@export var world_size := 160.0
@export var cell_size := 2.0
@export var world_seed := 7
@export_tool_button("Regenerate") var regenerate_action = regenerate

## Tempat dan arah pemain mula (diisi bila kawasan dibina).
var spawn := Transform3D.IDENTITY

var _kind := FishingArea.Kind.KOLAM
var _shape: Dictionary = SHAPES[0]
var _islands: Array = []
## Kawasan (x, z) yang mesti kosong: laluan lontaran dan pangkalan.
var _keep_clear: Array[Rect2] = []
var _noise := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()
var _mats := {}


func _ready() -> void:
	# Masa main, Main panggil build() dengan kawasan dari fail simpanan.
	if Engine.is_editor_hint():
		regenerate()


func build(a: FishingArea, tier: int) -> void:
	area = a
	vehicle_tier = tier
	regenerate()


func regenerate() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_mats.clear()
	_keep_clear.clear()
	if area == null:
		area = load("res://data/areas/kolam.tres")
	_kind = area.kind
	_shape = SHAPES[_kind]
	_islands = ISLANDS.get(_kind, [])
	_noise.seed = world_seed + _kind * 101
	_noise.frequency = 0.04
	_rng.seed = world_seed + _kind * 101

	_build_ground()
	_build_bounds()
	match _kind:
		FishingArea.Kind.KOLAM:
			_build_kolam()
		FishingArea.Kind.SUNGAI:
			_build_sungai()
		FishingArea.Kind.TASIK:
			_build_tasik()
		FishingArea.Kind.MUARA:
			_build_muara()
		FishingArea.Kind.PANTAI:
			_build_pantai()
		FishingArea.Kind.LAUT:
			_build_laut()
	_setup_water()


# --- Bentuk tanah ---------------------------------------------------------------

## Jarak anggaran (meter) ke tebing: negatif dalam air, positif atas darat.
func shore(x: float, z: float) -> float:
	var w := _noise.get_noise_2d(x * 0.5 + 100.0, z * 0.5)
	match _kind:
		FishingArea.Kind.KOLAM:
			return (Vector2(x / 24.0, z / 18.0).length() - 1.0) * 20.0 + w * 2.4
		FishingArea.Kind.SUNGAI:
			return absf(x - _river_x(z)) - 10.0 + w * 2.0
		FishingArea.Kind.TASIK:
			var lake := (Vector2(x / 58.0, (z + 10.0) / 48.0).length() - 1.0) * 50.0 + w * 4.0
			return maxf(lake, -_island_d(x, z, w))
		FishingArea.Kind.MUARA:
			# Sungai makin lebar bila sampai ke laut (z < -45).
			var sea := z + 45.0 + w * 4.0
			var half_width := lerpf(28.0, 11.0, smoothstep(-45.0, 40.0, z))
			return minf(sea, absf(x - _muara_x(z)) - half_width + w * 2.0)
		FishingArea.Kind.PANTAI:
			var coast := z - 14.0 - sin(x * 0.045) * 7.0 + w * 3.0
			return maxf(coast, -_island_d(x, z, w))
	return maxf(-60.0, -_island_d(x, z, w))


## Ketinggian tanah pada (x, z). Paras air = 0.
func height_at(x: float, z: float) -> float:
	var s := shore(x, z)
	if s < 0.0:
		return lerpf(0.3, -_shape.depth, smoothstep(0.0, _shape.shelf, -s))
	var n := _noise.get_noise_2d(x, z) * 0.8 * smoothstep(0.0, 8.0, s)
	var hills: float = smoothstep(_shape.hill_from, _shape.hill_from + 28.0, s) * _shape.hill_h
	var island := 0.0
	if not _islands.is_empty():
		island = smoothstep(0.0, 10.0, -_island_d(x, z, 0.0)) * _shape.island_h
	return maxf(0.25, 0.3 + s * _shape.slope + n + hills + island)


func _river_x(z: float) -> float:
	return sin(z * 0.045) * 12.0 + sin(z * 0.11 + 1.0) * 3.0


func _muara_x(z: float) -> float:
	return _river_x(z) * 0.6


## Jarak ke pulau paling dekat (negatif = atas pulau).
func _island_d(x: float, z: float, w: float) -> float:
	var best := 1e9
	for isl in _islands:
		best = minf(best, Vector2(x - isl.x, z - isl.y).length() - isl.z + w * 2.0)
	return best


func _build_ground() -> void:
	var n := int(world_size / cell_size)
	var half := world_size * 0.5
	var heights := PackedFloat32Array()
	heights.resize((n + 1) * (n + 1))
	for ix in n + 1:
		for iz in n + 1:
			heights[ix * (n + 1) + iz] = height_at(-half + ix * cell_size, -half + iz * cell_size)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ix in n:
		for iz in n:
			var x0 := -half + ix * cell_size
			var z0 := -half + iz * cell_size
			var x1 := x0 + cell_size
			var z1 := z0 + cell_size
			var a := Vector3(x0, heights[ix * (n + 1) + iz], z0)
			var b := Vector3(x1, heights[(ix + 1) * (n + 1) + iz], z0)
			var c := Vector3(x0, heights[ix * (n + 1) + iz + 1], z1)
			var d := Vector3(x1, heights[(ix + 1) * (n + 1) + iz + 1], z1)
			_tri(st, a, b, c, _ground_color(a, b, c))
			_tri(st, b, d, c, _ground_color(b, d, c))
	var mesh := st.commit()
	mesh.surface_set_material(0, _vertex_color_mat())

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


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	st.set_normal((c - a).cross(b - a).normalized())
	# Warna vertex mesti linear; tukar sendiri supaya sama di semua renderer (web & fon).
	st.set_color(col.srgb_to_linear())
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


func _ground_color(a: Vector3, b: Vector3, c: Vector3) -> Color:
	var p := (a + b + c) / 3.0
	var pal: Array = PALETTES[_kind]
	var jitter := _noise.get_noise_2d(p.x * 3.0, p.z * 3.0) * 0.06
	var col: Color
	if p.y < -0.3:
		col = pal[0]  # dasar air
	elif p.y < 0.55 or p.y < 2.0 and shore(p.x, p.z) < _shape.bank:
		col = pal[1]  # tebing: pasir, batu kerikil, tanah merah atau lumpur
	elif p.y < 3.0:
		col = pal[2]  # rumput
	else:
		col = pal[3]  # bukit
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


func _setup_water() -> void:
	if environment and environment.environment:
		environment.environment.fog_density = area.fog_density
	if water == null:
		return
	water.area_name = area.display_name
	water.species = area.species
	water.bite_delay = area.bite_delay
	# Laut terbentang sampai ufuk; kawasan darat cukup sebesar peta.
	var open_sea := _kind in [FishingArea.Kind.MUARA, FishingArea.Kind.PANTAI, FishingArea.Kind.LAUT]
	var surface := water.get_node_or_null("Surface") as MeshInstance3D
	if surface and surface.mesh is PlaneMesh:
		var plane := surface.mesh as PlaneMesh
		plane.size = Vector2.ONE * (420.0 if open_sea else world_size)
		plane.subdivide_width = 80 if open_sea else 48
		plane.subdivide_depth = plane.subdivide_width
		if plane.material is ShaderMaterial:
			plane.material.set_shader_parameter("water_color", area.water_color)
	var col := water.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col and col.shape is BoxShape3D:
		# Air "wujud" seluruh peta, tapi tanah sentiasa lebih tinggi dari air,
		# jadi pelampung kena tanah dulu kalau lontar ke darat.
		col.shape.size = Vector3(world_size, 3.0, world_size)


# --- Setiap kawasan ---------------------------------------------------------------

func _build_kolam() -> void:
	_keep_clear.append(Rect2(-3.5, 4.0, 7.0, 40.0))
	spawn = _build_jetty(Vector3(0.0, 0.0, 22.0), 0.0, 9.0)
	_build_hut(Vector3(20.0, 0.0, 28.0), deg_to_rad(-30.0))
	_place(10, 5.0, 20.0, _palm)
	_place(28, 12.0, 52.0, _round_tree)
	_place(16, -1.0, 6.0, _rock)
	_place(26, -2.4, 1.0, _reeds)
	_place(14, -12.0, -3.0, _lily)


func _build_sungai() -> void:
	# Pangkalan dari tebing timur, menghala ke barat merentas sungai.
	var bank_x := _find_shore(Vector2(_river_x(0.0), 0.0), Vector2.RIGHT)
	_keep_clear.append(Rect2(bank_x - 30.0, -7.0, 40.0, 14.0))
	spawn = _build_jetty(Vector3(bank_x + 3.0, 0.0, 0.0), PI / 2.0, 9.0)
	_place(10, -8.0, -1.5, _boulder)
	_place(14, -1.0, 3.0, _rock)
	_place(14, 3.0, 14.0, _bamboo)
	_place(7, 18.0, 60.0, _tall_tree)
	_place(34, 6.0, 60.0, _round_tree)
	_place(10, -1.5, 1.0, _reeds)


func _build_tasik() -> void:
	var pos := Vector3(0.0, 0.0, 16.0)
	_keep_clear.append(Rect2(-9.0, -40.0, 18.0, 64.0))
	spawn = _build_boat(pos, 0.0)
	_place(22, -30.0, -3.0, _dead_tree)
	_place(10, -1.0, 2.0, _rock)
	_place(40, 4.0, 60.0, _round_tree)
	_place(5, 8.0, 40.0, _tall_tree)
	_raft_house(Vector3(30.0, 0.0, 22.0), deg_to_rad(20.0))


func _build_muara() -> void:
	var x := _muara_x(6.0)
	_keep_clear.append(Rect2(x - 9.0, -60.0, 18.0, 74.0))
	spawn = _build_boat(Vector3(x, 0.0, 6.0), 0.0)
	_place(30, -3.0, 10.0, _mangrove)
	_place(12, 0.0, 8.0, _nipah)
	_place(10, -20.0, -4.0, _pole)
	_place(3, 10.0, 20.0, _stilt_house)
	_place(24, 12.0, 60.0, _round_tree)


func _build_pantai() -> void:
	_keep_clear.append(Rect2(-9.0, -75.0, 18.0, 61.0))
	spawn = _build_boat(Vector3(0.0, 0.0, -22.0), 0.0)
	_place(18, 3.0, 16.0, _palm)
	_place(14, -4.0, 2.0, _boulder)
	_place(4, 16.0, 26.0, _stilt_house)
	_place(24, 18.0, 60.0, _round_tree)


func _build_laut() -> void:
	_keep_clear.append(Rect2(-9.0, -70.0, 18.0, 86.0))
	spawn = _build_boat(Vector3(0.0, 0.0, 10.0), 0.0)
	_place(6, 2.0, 10.0, _palm)
	_place(6, -3.0, 1.0, _boulder)
	_place(4, -60.0, -30.0, _buoy)
	_oil_rig(Vector3(58.0, 0.0, -66.0))


## Cari tebing: bergerak dari dalam air ke arah "dir" sampai jumpa darat.
func _find_shore(from: Vector2, dir: Vector2) -> float:
	var p := from
	for i in 200:
		if shore(p.x, p.y) >= 0.0:
			break
		p += dir * 0.25
	return p.x if absf(dir.x) > 0.0 else p.y


## Letak objek secara rawak di tempat yang jaraknya dari tebing antara
## s_min dan s_max (negatif = dalam air), kecuali dalam _keep_clear.
func _place(count: int, s_min: float, s_max: float, builder: Callable) -> void:
	var half := world_size * 0.5 - 8.0
	var placed := 0
	var tries := 0
	while placed < count and tries < count * 80:
		tries += 1
		var x := _rng.randf_range(-half, half)
		var z := _rng.randf_range(-half, half)
		if _cleared(x, z):
			continue
		var s := shore(x, z)
		if s < s_min or s > s_max:
			continue
		builder.call(Vector3(x, height_at(x, z), z))
		placed += 1


func _cleared(x: float, z: float) -> bool:
	for r in _keep_clear:
		if r.has_point(Vector2(x, z)):
			return true
	return false


# --- Pangkalan, pondok dan kenderaan ------------------------------------------------

## Pangkalan kayu dari darat ("land") ke arah air. yaw 0 = menghala ke -Z.
## Pulangkan tempat pemain berdiri di hujung pangkalan.
func _build_jetty(land: Vector3, yaw: float, length: float) -> Transform3D:
	var root := Node3D.new()
	root.position = Vector3(land.x, 0.0, land.z)
	root.rotation.y = yaw
	add_child(root)
	var wood := _mat(Color(0.55, 0.38, 0.22))
	var dark := _mat(Color(0.38, 0.26, 0.16))
	var deck_y := maxf(0.55, height_at(land.x, land.z) + 0.1)

	var planks := int(length / 0.4)
	for i in planks:
		var z := -length + 0.2 + i * 0.4
		var tilt := _rng.randf_range(-0.02, 0.02)
		_box(Vector3(2.0, 0.08, 0.36), Vector3(0, deck_y - 0.04, z), wood if i % 3 else dark, Vector3(0, 0, tilt), root)
	for z in [-length + 0.2, -length + 3.0, -length + 6.0, -0.4]:
		for x in [-0.95, 0.95]:
			_cylinder(0.08, 0.08, 3.0, Vector3(x, deck_y - 1.5, z), dark, root)

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 0.3, length)
	shape.shape = box
	body.position = Vector3(0, deck_y - 0.15, -length * 0.5)
	body.add_child(shape)
	root.add_child(body)
	return root.transform * Transform3D(Basis.IDENTITY, Vector3(0, deck_y + 0.05, -length + 1.6))


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
	_roof(Vector3(4.2, 1.4, 3.6), Vector3(0, 3.3, 0), attap, root)
	_solid(root, Vector3(3.4, 0.8, 2.8), Vector3(0, 0.4, 0))


## Kenderaan terbaik pemain berlabuh di "pos", haluan menghala ke -Z (yaw 0).
## Pulangkan tempat pemain berdiri.
func _build_boat(pos: Vector3, yaw: float) -> Transform3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	add_child(root)
	var tier := clampi(vehicle_tier, 1, 4)
	# panjang, lebar, tinggi dinding, dalam bawah air, lantai, warna badan, jalur, tempat berdiri (z)
	var spec: Array = [
		[3.6, 0.8, 0.26, 0.15, 0.08, Color(0.95, 0.5, 0.1), Color(1.0, 0.82, 0.2), 0.3],
		[5.2, 1.4, 0.42, 0.25, 0.12, Color(0.52, 0.36, 0.22), Color(0.18, 0.32, 0.55), 0.2],
		[6.4, 2.1, 0.62, 0.35, 0.2, Color(0.94, 0.94, 0.92), Color(0.15, 0.4, 0.75), -0.8],
		[10.0, 3.2, 0.95, 0.6, 0.35, Color(0.95, 0.95, 0.94), Color(0.12, 0.22, 0.45), -2.6],
	][tier - 1]
	var length: float = spec[0]
	var width: float = spec[1]
	var floor_y: float = spec[4]
	var hull := MeshInstance3D.new()
	hull.mesh = _hull_mesh(length, width, spec[2], spec[3], floor_y, spec[5], spec[6])
	root.add_child(hull)

	match tier:
		1:  # dayung melintang
			var paddle := _cylinder(0.025, 0.025, 2.2, Vector3(0, floor_y + 0.28, -0.5), _mat(Color(0.2, 0.2, 0.22)), root)
			paddle.rotation.z = PI / 2.0
			for x in [-1.1, 1.1]:
				_box(Vector3(0.36, 0.03, 0.16), Vector3(x, floor_y + 0.28, -0.5), _mat(Color(0.95, 0.85, 0.2)), Vector3.ZERO, root)
		2:  # papan duduk
			for z in [-1.4, 1.5]:
				_box(Vector3(1.0, 0.06, 0.3), Vector3(0, floor_y + 0.26, z), _mat(Color(0.42, 0.28, 0.16)), Vector3.ZERO, root)
		3:  # konsol stereng dan enjin sangkut
			_box(Vector3(0.8, 0.9, 0.6), Vector3(0, floor_y + 0.45, 1.2), _mat(Color(0.9, 0.9, 0.88)), Vector3.ZERO, root)
			_box(Vector3(0.8, 0.35, 0.04), Vector3(0, floor_y + 1.05, 0.92), _mat(Color(0.55, 0.75, 0.85)), Vector3(-0.3, 0, 0), root)
			_box(Vector3(0.45, 0.6, 0.5), Vector3(0, 0.85, length * 0.5 + 0.15), _mat(Color(0.15, 0.15, 0.17)), Vector3.ZERO, root)
			_cylinder(0.06, 0.06, 0.9, Vector3(0, 0.2, length * 0.5 + 0.2), _mat(Color(0.2, 0.2, 0.22)), root)
			_solid(root, Vector3(0.8, 0.9, 0.6), Vector3(0, floor_y + 0.45, 1.2), CABIN_LAYER)
		4:  # kabin, bumbung, tingkap, antena, pemegang joran
			# Kabin rendah sikit dari mata pemain supaya bumbung tak halang kamera.
			var cabin := Vector3(2.4, 1.6, 3.2)
			var cabin_pos := Vector3(0, floor_y + cabin.y * 0.5, 2.3)
			_box(cabin, cabin_pos, _mat(Color(0.96, 0.96, 0.95)), Vector3.ZERO, root)
			_box(Vector3(2.7, 0.14, 3.6), cabin_pos + Vector3(0, cabin.y * 0.5 + 0.07, 0), _mat(Color(0.12, 0.22, 0.45)), Vector3.ZERO, root)
			_box(Vector3(2.0, 0.6, 0.04), cabin_pos + Vector3(0, 0.35, -cabin.z * 0.5 - 0.01), _mat(Color(0.15, 0.22, 0.28)), Vector3.ZERO, root)
			_cylinder(0.03, 0.03, 2.2, cabin_pos + Vector3(0.8, cabin.y * 0.5 + 1.1, 0.8), _mat(Color(0.8, 0.8, 0.8)), root)
			for x in [-1.2, 1.2]:
				var holder := _cylinder(0.03, 0.03, 0.6, Vector3(x, floor_y + 0.9, 4.2), _mat(Color(0.75, 0.75, 0.78)), root)
				holder.rotation.x = -0.4
			_solid(root, cabin, cabin_pos, CABIN_LAYER)

	# Lantai dan pagar halimunan supaya pemain tak terjatuh ke air.
	var deck_w := maxf(width * 0.62, 0.8)  # cukup lebar untuk badan pemain
	var deck_l := length * 0.66
	_solid(root, Vector3(deck_w, 0.2, deck_l), Vector3(0, floor_y - 0.1, 0), BOAT_LAYER)
	for side in [-1.0, 1.0]:
		_solid(root, Vector3(0.1, 1.5, deck_l), Vector3(side * (deck_w * 0.5 + 0.05), floor_y + 0.75, 0), BOAT_LAYER)
		_solid(root, Vector3(deck_w, 1.5, 0.1), Vector3(0, floor_y + 0.75, side * (deck_l * 0.5 + 0.05)), BOAT_LAYER)
	return root.transform * Transform3D(Basis.IDENTITY, Vector3(0, floor_y + 0.05, spec[7]))


## Badan bot low-poly: haluan tajam di -Z, buritan rata di +Z, terbuka di atas.
func _hull_mesh(length: float, width: float, wall: float, draft: float, floor_y: float, body_col: Color, stripe_col: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var floor_col := body_col.darkened(0.25)
	var steps := 10
	var prev := {}
	for i in steps + 1:
		var t := float(i) / steps  # 0 haluan, 1 buritan
		var z := lerpf(-length * 0.5, length * 0.5, t)
		var half := width * 0.5 * pow(clampf(t / 0.45, 0.0, 1.0), 0.6) * lerpf(1.0, 0.85, smoothstep(0.75, 1.0, t))
		var top := floor_y + wall + 0.2 * (1.0 - t) * (1.0 - t) * length / 5.0  # haluan naik sikit
		var mid := top - minf(0.12, wall * 0.4)
		var cur := {
			"top": [Vector3(-half, top, z), Vector3(half, top, z)],
			"mid": [Vector3(-half * 0.96, mid, z), Vector3(half * 0.96, mid, z)],
			"bot": [Vector3(-half * 0.35, -draft, z), Vector3(half * 0.35, -draft, z)],
			"floor": [Vector3(-_wall_x(half, top, draft, floor_y), floor_y, z), Vector3(_wall_x(half, top, draft, floor_y), floor_y, z)],
		}
		if i > 0:
			for s in 2:
				_quad(st, prev.top[s], cur.top[s], cur.mid[s], prev.mid[s], stripe_col)
				_quad(st, prev.mid[s], cur.mid[s], cur.bot[s], prev.bot[s], body_col)
			_quad(st, prev.bot[0], cur.bot[0], cur.bot[1], prev.bot[1], body_col.darkened(0.3))
			_quad(st, prev.floor[0], cur.floor[0], cur.floor[1], prev.floor[1], floor_col)
		prev = cur
	# Papan buritan.
	_quad(st, prev.top[0], prev.top[1], prev.bot[1], prev.bot[0], body_col.darkened(0.1))
	var mesh := st.commit()
	mesh.surface_set_material(0, _vertex_color_mat())
	return mesh


## Lebar dinding bot pada paras lantai (dinding condong dari atas ke lunas).
func _wall_x(half: float, top: float, draft: float, floor_y: float) -> float:
	return lerpf(half * 0.35, half, inverse_lerp(-draft, top, floor_y)) * 0.98


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	_tri(st, a, b, c, col)
	_tri(st, a, c, d, col)


func _raft_house(pos: Vector3, rot_y: float) -> void:
	# Rumah rakit atas pelampung tong, macam di tasik empangan.
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = rot_y
	add_child(root)
	for x in [-1.8, 1.8]:
		var drum := _cylinder(0.4, 0.4, 5.6, Vector3(x, 0.05, 0), _mat(Color(0.2, 0.4, 0.65)), root)
		drum.rotation.x = PI / 2.0
	_box(Vector3(4.6, 0.15, 6.0), Vector3(0, 0.5, 0), _mat(Color(0.55, 0.38, 0.22)), Vector3.ZERO, root)
	_box(Vector3(3.4, 2.0, 3.4), Vector3(0, 1.55, 0.6), _mat(Color(0.72, 0.6, 0.42)), Vector3.ZERO, root)
	_roof(Vector3(4.2, 1.2, 4.2), Vector3(0, 3.15, 0.6), _mat(Color(0.65, 0.25, 0.18)), root)
	_solid(root, Vector3(4.6, 3.0, 6.0), Vector3(0, 1.5, 0))


func _stilt_house(pos: Vector3) -> void:
	# Rumah kampung atas tiang.
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = _rng.randf() * TAU
	add_child(root)
	var wood := _mat(Color(0.5, 0.34, 0.2))
	for x in [-1.6, 1.6]:
		for z in [-1.4, 1.4]:
			_cylinder(0.1, 0.1, 1.6, Vector3(x, 0.8, z), wood, root)
	var walls: Array[Color] = [Color(0.85, 0.75, 0.55), Color(0.6, 0.78, 0.7), Color(0.85, 0.6, 0.45)]
	_box(Vector3(3.6, 2.0, 3.2), Vector3(0, 2.6, 0), _mat(walls[_rng.randi() % walls.size()]), Vector3.ZERO, root)
	_roof(Vector3(4.4, 1.5, 3.8), Vector3(0, 4.35, 0), _mat(Color(0.6, 0.22, 0.16)), root)
	_solid(root, Vector3(3.6, 3.6, 3.2), Vector3(0, 1.8, 0))


func _oil_rig(pos: Vector3) -> void:
	# Pelantar minyak jauh di ufuk.
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	var steel := _mat(Color(0.55, 0.55, 0.5))
	for x in [-5.0, 5.0]:
		for z in [-5.0, 5.0]:
			_cylinder(0.6, 0.6, 14.0, Vector3(x, 2.0, z), steel, root)
	_box(Vector3(14.0, 1.2, 14.0), Vector3(0, 9.0, 0), _mat(Color(0.85, 0.65, 0.2)), Vector3.ZERO, root)
	_box(Vector3(5.0, 4.0, 5.0), Vector3(-2.5, 11.6, -2.5), _mat(Color(0.9, 0.9, 0.88)), Vector3.ZERO, root)
	var tower := _cylinder(0.4, 1.4, 12.0, Vector3(3.5, 15.6, 3.5), _mat(Color(0.8, 0.25, 0.2)), root)
	tower.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# --- Pokok, batu dan hiasan --------------------------------------------------------

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
	_fronds(root, top, 7, 2.4, leaf)
	for i in 3:
		var nut := _sphere(0.12, top + Vector3(cos(i * 2.1), -0.2, sin(i * 2.1)) * 0.2, _mat(Color(0.35, 0.3, 0.12)), root)
		nut.position.y = top.y - 0.25
	_trunk_collider(root, 0.2, 7.0)


func _fronds(root: Node3D, top: Vector3, count: int, length: float, mat: Material, droop := 28.0) -> void:
	for i in count:
		var frond := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.5, 0.04, length)
		bm.material = mat
		frond.mesh = bm
		var pivot := Node3D.new()
		pivot.position = top
		pivot.rotation = Vector3(0, i * TAU / count, 0)
		root.add_child(pivot)
		# Pangkal pelepah di "top", hujung condong ke bawah (droop > 0) atau ke atas.
		var d := deg_to_rad(droop)
		frond.position = Vector3(0, -sin(d), cos(d)) * length * 0.5
		frond.rotation.x = d
		pivot.add_child(frond)


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


func _tall_tree(pos: Vector3) -> void:
	# Pokok hutan hujan yang tinggi melepasi pokok lain (macam pokok tualang).
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = _rng.randf() * TAU
	add_child(root)
	var h := _rng.randf_range(11.0, 15.0)
	_cylinder(0.3, 0.5, h, Vector3(0, h * 0.5, 0), _mat(Color(0.6, 0.55, 0.46)), root)
	var crown := _sphere(3.2, Vector3(0, h + 0.6, 0), _mat(Color(0.22, 0.46, 0.2)), root)
	crown.scale = Vector3(1.0, 0.45, 1.0)
	var crown2 := _sphere(2.0, Vector3(1.6, h + 1.2, 0.8), _mat(Color(0.26, 0.52, 0.22)), root)
	crown2.scale = Vector3(1.0, 0.5, 1.0)
	_trunk_collider(root, 0.45, h)


func _bamboo(pos: Vector3) -> void:
	var mat := _mat(Color(0.5, 0.65, 0.25))
	var leaf := _mat(Color(0.32, 0.58, 0.2))
	for i in _rng.randi_range(4, 7):
		var h := _rng.randf_range(4.0, 7.0)
		var off := Vector3(_rng.randf_range(-0.6, 0.6), h * 0.5, _rng.randf_range(-0.6, 0.6))
		var stalk := _cylinder(0.06, 0.08, h, pos + off, mat)
		stalk.rotation = Vector3(_rng.randf_range(-0.25, 0.25), 0, _rng.randf_range(-0.25, 0.25))
		stalk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 3:
		var a := i * TAU / 3.0 + _rng.randf()
		var tuft := _sphere(1.0, pos + Vector3(cos(a) * 0.8, 4.6 + i * 0.7, sin(a) * 0.8), leaf)
		tuft.scale = Vector3(1.0, 0.7, 1.0)


func _dead_tree(pos: Vector3) -> void:
	# Batang pokok mati yang tenggelam bila tasik empangan dibina.
	var root := Node3D.new()
	root.position = Vector3(pos.x, minf(pos.y, 0.0), pos.z)
	root.rotation.y = _rng.randf() * TAU
	add_child(root)
	var grey := _mat(Color(0.62, 0.6, 0.55))
	var h := _rng.randf_range(3.0, 7.0) - root.position.y
	var trunk := _cylinder(0.1, 0.22, h, Vector3(0, h * 0.5, 0), grey, root)
	trunk.rotation.z = _rng.randf_range(-0.12, 0.12)
	for i in _rng.randi_range(1, 3):
		var y := h * _rng.randf_range(0.55, 0.9)
		var a := i * 2.1
		_beam(Vector3(0, y, 0), Vector3(cos(a) * 1.3, y + 1.0, sin(a) * 1.3), 0.07, grey, root)
	_trunk_collider(root, 0.25, h)


func _mangrove(pos: Vector3) -> void:
	# Pokok bakau: akar jangkang di atas air dan daun hijau gelap.
	var root := Node3D.new()
	root.position = Vector3(pos.x, maxf(pos.y, -0.4), pos.z)
	root.rotation.y = _rng.randf() * TAU
	var s := _rng.randf_range(0.8, 1.3)
	root.scale = Vector3.ONE * s
	add_child(root)
	var bark := _mat(Color(0.36, 0.28, 0.2))
	for i in 4:
		var a := i * TAU / 4.0 + 0.4
		_beam(Vector3(cos(a), -0.3, sin(a)) * 0.9, Vector3(0, 1.1, 0), 0.06, bark, root)
	_cylinder(0.1, 0.14, 2.0, Vector3(0, 2.0, 0), bark, root)
	var crown := _sphere(1.4, Vector3(0, 3.3, 0), _mat(Color(0.16, 0.38, 0.18)), root)
	crown.scale = Vector3(1.2, 0.7, 1.2)
	_trunk_collider(root, 0.6, 3.0)


func _nipah(pos: Vector3) -> void:
	# Pokok nipah: pelepah terus dari tanah, tiada batang.
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = _rng.randf() * TAU
	add_child(root)
	_fronds(root, Vector3(0, 0.4, 0), 6, 3.2, _mat(Color(0.3, 0.52, 0.2)), -40.0)


func _pole(pos: Vector3) -> void:
	# Pancang kayu nelayan dalam air.
	var p := _cylinder(0.08, 0.1, 3.0, Vector3(pos.x, 0.6, pos.z), _mat(Color(0.4, 0.3, 0.2)))
	p.rotation = Vector3(_rng.randf_range(-0.1, 0.1), 0, _rng.randf_range(-0.1, 0.1))


func _buoy(pos: Vector3) -> void:
	# Pelampung unjam: tempat ikan laut berkumpul.
	var at := Vector3(pos.x, 0.1, pos.z)
	_sphere(0.45, at, _mat(Color(0.95, 0.45, 0.1)))
	_cylinder(0.03, 0.03, 1.6, at + Vector3(0, 0.9, 0), _mat(Color(0.3, 0.3, 0.3)))
	_box(Vector3(0.02, 0.35, 0.5), at + Vector3(0, 1.5, 0.25), _mat(Color(0.9, 0.15, 0.12)))


func _rock(pos: Vector3) -> void:
	_stone(pos, _rng.randf_range(0.4, 1.3))


func _boulder(pos: Vector3) -> void:
	_stone(Vector3(pos.x, maxf(pos.y, -1.0), pos.z), _rng.randf_range(1.0, 2.2))


func _stone(pos: Vector3, s: float) -> void:
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


func _lily(pos: Vector3) -> void:
	var p := Vector3(pos.x, 0.03, pos.z)
	_cylinder(0.35, 0.35, 0.02, p, _mat(Color(0.25, 0.5, 0.2)))
	if _rng.randf() < 0.4:
		_sphere(0.1, p + Vector3(0, 0.08, 0), _mat(Color(0.95, 0.55, 0.75)))


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


## Kotak fizik halimunan (dinding, lantai bot, rumah).
func _solid(parent: Node3D, size: Vector3, pos: Vector3, layer := 1) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.position = pos
	body.add_child(shape)
	parent.add_child(body)


# --- Pembantu bina mesh ---

func _mat(color: Color) -> StandardMaterial3D:
	if not _mats.has(color):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.9
		_mats[color] = m
	return _mats[color]


func _vertex_color_mat() -> StandardMaterial3D:
	if not _mats.has("vertex"):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 1.0
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mats["vertex"] = m
	return _mats["vertex"]


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


func _roof(size: Vector3, pos: Vector3, mat: Material, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = size
	prism.material = mat
	mi.mesh = prism
	mi.position = pos
	parent.add_child(mi)
	return mi


## Silinder dari titik a ke titik b (akar bakau, dahan).
func _beam(a: Vector3, b: Vector3, r: float, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var mi := _cylinder(r * 0.7, r, a.distance_to(b), (a + b) * 0.5, mat, parent)
	var dir := (b - a).normalized()
	var up := Vector3.RIGHT if absf(dir.y) > 0.99 else Vector3.UP
	# Paksi silinder ialah Y; pusing supaya Y menghala ke "dir".
	mi.basis = Basis.looking_at(dir, up) * Basis(Vector3.RIGHT, -PI / 2.0)
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
