class_name FishModel
extends RefCounted
## Bina model ikan low-poly ringkas ikut warna spesies dan berat.


static func build(species: FishSpecies, weight: float) -> Node3D:
	var root := Node3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = species.color
	mat.roughness = 0.5

	var body := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radial_segments = 6
	sphere.rings = 3
	sphere.radius = 0.12
	sphere.height = 0.24
	sphere.material = mat
	body.mesh = sphere
	body.scale = Vector3(0.55, 1.0, 2.2)
	root.add_child(body)

	var tail := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.22, 0.18, 0.03)
	prism.material = mat
	tail.mesh = prism
	tail.position = Vector3(0, 0, 0.3)
	tail.rotation = Vector3(-PI / 2, 0, PI / 2)
	root.add_child(tail)

	# Saiz ikut berat (isipadu ~ panjang^3).
	var s := clampf(pow(weight, 1.0 / 3.0), 0.6, 2.6)
	root.scale = Vector3.ONE * s
	return root
