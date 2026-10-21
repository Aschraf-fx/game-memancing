class_name FishingArea
extends Resource
## Data satu kawasan memancing. Bentuk tanah dijana oleh AreaWorld ikut "kind".
## Kawasan baru: buat fail .tres dalam data/areas/ dan tambah dalam AreaCatalog.PATHS.

enum Kind { KOLAM, SUNGAI, TASIK, MUARA, PANTAI, LAUT }

## Nama unik, dipakai dalam fail simpanan. Jangan tukar lepas dah keluar.
@export var id := "kolam"
@export var display_name := "Kolam Kampung"
## Tempat sebenar yang jadi inspirasi (bukan peta tepat).
@export var place := ""
@export_multiline var description := ""
@export var kind := Kind.KOLAM
## Kenderaan paling rendah yang perlu: 0 kaki, 1 kayak, 2 sampan, 3 bot kecil, 4 bot laut dalam.
@export var vehicle_tier := 0

@export_group("Ikan")
@export var species: Array[FishSpecies] = []
## Julat masa (saat) sebelum ikan menyambar umpan.
@export var bite_delay := Vector2(3.0, 10.0)

@export_group("Rupa")
@export var water_color := Color(0.07, 0.3, 0.34, 0.88)
@export var fog_density := 0.0015


func fish_names() -> String:
	var names: Array[String] = []
	for s in species:
		names.append(s.display_name)
	return ", ".join(names)
