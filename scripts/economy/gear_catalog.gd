class_name GearCatalog
extends RefCounted
## Senarai semua barang kedai, ikut susunan dalam kedai.
## Barang baru: buat fail .tres dalam data/gear/ dan tambah satu baris di sini.

const ITEMS: Array[GearItem] = [
	preload("res://data/gear/joran_buluh.tres"),
	preload("res://data/gear/joran_gentian.tres"),
	preload("res://data/gear/joran_karbon.tres"),
	preload("res://data/gear/kekili_lama.tres"),
	preload("res://data/gear/kekili_spinning.tres"),
	preload("res://data/gear/kekili_baitcaster.tres"),
	preload("res://data/gear/tali_nilon_6.tres"),
	preload("res://data/gear/tali_nilon_12.tres"),
	preload("res://data/gear/tali_sulam_20.tres"),
	preload("res://data/gear/kail_10.tres"),
	preload("res://data/gear/kail_tajam_6.tres"),
	preload("res://data/gear/kail_circle_2.tres"),
	preload("res://data/gear/umpan_cacing.tres"),
	preload("res://data/gear/umpan_dedak.tres"),
	preload("res://data/gear/umpan_udang.tres"),
	preload("res://data/gear/umpan_anak_ikan.tres"),
]


static func find(id: String) -> GearItem:
	for item in ITEMS:
		if item.id == id:
			return item
	return null


static func in_slot(slot: GearItem.Slot) -> Array[GearItem]:
	var out: Array[GearItem] = []
	for item in ITEMS:
		if item.slot == slot:
			out.append(item)
	return out


## Barang percuma yang pemain baru dah ada (satu untuk setiap slot).
static func starter(slot: GearItem.Slot) -> GearItem:
	for item in in_slot(slot):
		if item.price == 0:
			return item
	return null
