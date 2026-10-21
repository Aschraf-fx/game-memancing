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
## Makin jarang, makin mahal harga jual dan makin susah nak jumpa.
@export_enum("Biasa", "Luar Biasa", "Jarang", "Sangat Jarang") var rarity := 0

@export_group("Peluang")
## Pemberat peluang muncul berbanding ikan lain di kawasan yang sama.
@export var spawn_weight := 1.0


const RARITY_NAMES := ["Biasa", "Luar Biasa", "Jarang", "Sangat Jarang"]
const RARITY_PRICE := [1.0, 1.5, 2.5, 4.0]
const RARITY_COLORS := [Color(0.85, 0.85, 0.85), Color(0.45, 0.9, 0.45), Color(0.4, 0.7, 1.0), Color(1.0, 0.75, 0.2)]


## Nama fail tanpa sambungan, contoh "haruan". Dipakai dalam fail simpanan.
func id() -> String:
	return resource_path.get_file().get_basename()


## Harga jual: berat x syiling/kg x gandaan kejarangan, tambah bonus
## sampai +50% untuk ikan yang hampir saiz maksimum (ikan trofi).
func price_for(weight: float) -> int:
	var size01 := clampf(inverse_lerp(min_weight, max_weight, weight), 0.0, 1.0)
	return maxi(1, roundi(weight * coins_per_kg * RARITY_PRICE[rarity] * (1.0 + 0.5 * size01 * size01)))
