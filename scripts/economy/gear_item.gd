class_name GearItem
extends Resource
## Satu barang dalam kedai. Buat baru: klik kanan folder data/gear >
## New Resource > GearItem, kemudian tambah dalam GearCatalog.ITEMS.
## Hanya statistik untuk jenis (slot) barang tu yang dipakai.

enum Slot { JORAN, KEKILI, TALI, MATA_KAIL, UMPAN, KENDERAAN }

const SLOT_NAMES := ["Joran", "Kekili", "Tali", "Mata Kail", "Umpan", "Kenderaan"]

## Nama unik, dipakai dalam fail simpanan. Jangan tukar lepas dah keluar.
@export var id := "joran_buluh"
@export var display_name := "Joran Buluh"
@export var slot := Slot.JORAN
## Harga dalam syiling. 0 = barang permulaan (pemain dah ada).
@export var price := 0
@export_multiline var description := ""

@export_group("Joran")
@export var cast_distance := 22.0
@export var charge_time := 1.2
## Daya gulung (Newton).
@export var power := 35.0

@export_group("Kekili")
@export var reel_speed := 1.6
@export_range(0.5, 1.0) var drag_threshold := 0.85

@export_group("Tali")
## Had putus (Newton). Kira-kira 10 N = 1 kg.
@export var line_strength := 60.0

@export_group("Mata kail")
@export var strike_window := 1.1
@export var size_bias := 2.2

@export_group("Umpan")
@export var bite_mult := 1.0
@export var rare_luck := 1.0
## Bilangan umpan dalam satu pek. 0 = tak habis-habis.
@export var pack_size := 0

@export_group("Kenderaan")
## Tahap kenderaan: 0 kaki, 1 kayak, 2 sampan, 3 bot kecil, 4 bot laut dalam.
## Kawasan yang perlukan tahap ni (atau lebih rendah) boleh dilawat.
@export var tier := 0


## Satu baris statistik ringkas untuk kedai.
func stats_text() -> String:
	match slot:
		Slot.JORAN:
			return "Lontar %d m  |  Kuasa %d" % [cast_distance, power]
		Slot.KEKILI:
			return "Gulung %.1f m/s  |  Drag %d%%" % [reel_speed, roundi(drag_threshold * 100)]
		Slot.TALI:
			return "Tahan %d N (~%d kg)" % [line_strength, roundi(line_strength / 10.0)]
		Slot.MATA_KAIL:
			return "Masa sentap %.1f s  |  Ikan besar %s" % [strike_window, _stars(2.2 - size_bias, 0.4)]
		Slot.UMPAN:
			var faster := roundi((1.0 - bite_mult) * 100)
			var t := "Ikan gigit biasa"
			if faster != 0:
				t = "Gigit %d%% lebih %s" % [absi(faster), "cepat" if faster > 0 else "lambat"]
			t += "  |  Ikan jarang x%.1f" % rare_luck if rare_luck > 1.0 else ""
			t += "  |  %d biji/pek" % pack_size if pack_size > 0 else "  |  Tak habis"
			return t
		Slot.KENDERAAN:
			var names: Array[String] = []
			for area in AreaCatalog.all():
				if area.vehicle_tier == tier:
					names.append(area.display_name)
			return "Buka: " + ", ".join(names)
	return ""


func _stars(v: float, step: float) -> String:
	var n := clampi(roundi(v / step) + 1, 1, 4)
	return "*".repeat(n)
