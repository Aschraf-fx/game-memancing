class_name FishSpecies
extends Resource
## Data satu spesies ikan. Buat baru: klik kanan folder data/fish > New Resource > FishSpecies.

@export var display_name := "Tilapia"
@export var color := Color(0.6, 0.6, 0.55)

@export_group("Saiz (kg)")
@export var min_weight := 0.3
@export var max_weight := 2.0

@export_group("Kelakuan")
## Kekuatan tarikan ikan (Newton). Lebih tinggi = lebih susah.
@export var pull_strength := 20.0
## Berapa kerap ikan meronta (0 - 1).
@export_range(0.0, 1.0) var aggression := 0.4
## Stamina ikan dalam saat sebelum letih.
@export var stamina := 12.0

@export_group("Ekonomi")
@export var coins_per_kg := 10

@export_group("Peluang")
## Pemberat peluang muncul berbanding ikan lain di kawasan yang sama.
@export var spawn_weight := 1.0
