class_name AreaCatalog
extends RefCounted
## Senarai semua kawasan memancing, ikut susunan dalam PETA.
## Dimuat bila mula diperlukan (bukan preload): preload kawasan dalam const
## buat Godot tersangkut kalau skrip FishingArea belum dimuat.

const PATHS := [
	"res://data/areas/kolam.tres",
	"res://data/areas/sungai.tres",
	"res://data/areas/tasik.tres",
	"res://data/areas/muara.tres",
	"res://data/areas/pantai.tres",
	"res://data/areas/laut.tres",
]

static var _areas: Array[FishingArea] = []


static func all() -> Array[FishingArea]:
	if _areas.is_empty():
		for path in PATHS:
			_areas.append(load(path))
	return _areas


static func find(id: String) -> FishingArea:
	for area in all():
		if area.id == id:
			return area
	return null


static func first() -> FishingArea:
	return all()[0]
