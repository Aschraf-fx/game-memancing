class_name PlayerData
extends RefCounted
## Semua kemajuan pemain: syiling, beg ikan, peralatan dan rekod.
## Setiap perubahan pancar "changed", dan Main akan simpan ke fail.

signal changed

const START_COINS := 50
const BAG_CAPACITY := 20

var coins := START_COINS
## Ikan dalam beg. Setiap satu: {fish, name, kg, value, rarity}.
var bag: Array[Dictionary] = []
## id barang yang dah dibeli.
var owned: Array[String] = []
## Slot (int) -> id barang yang sedang dipakai.
var equipped := {}
## id umpan -> baki biji.
var bait_left := {}
## id ikan -> berat paling berat (kg).
var records := {}


func _init() -> void:
	for slot in GearItem.Slot.values():
		var item := GearCatalog.starter(slot)
		owned.append(item.id)
		equipped[slot] = item.id


func equipped_item(slot: GearItem.Slot) -> GearItem:
	return GearCatalog.find(equipped.get(slot, ""))


func bag_full() -> bool:
	return bag.size() >= BAG_CAPACITY


func bag_value() -> int:
	var total := 0
	for f in bag:
		total += f.value
	return total


## Masukkan ikan dalam beg. Pulangkan true kalau rekod berat baru.
func add_catch(fish: HookedFish) -> bool:
	var id := fish.species.id()
	bag.append({
		"fish": id,
		"name": fish.species.display_name,
		"kg": snappedf(fish.weight, 0.01),
		"value": fish.value(),
		"rarity": fish.species.rarity,
	})
	# Ikan pertama spesies ni bukan "rekod baru", cuma rekod pertama.
	var record: bool = records.has(id) and fish.weight > records[id]
	if fish.weight > records.get(id, 0.0):
		records[id] = snappedf(fish.weight, 0.01)
	changed.emit()
	return record


func sell(index: int) -> int:
	var f: Dictionary = bag.pop_at(index)
	coins += f.value
	changed.emit()
	return f.value


func sell_all() -> int:
	var total := bag_value()
	coins += total
	bag.clear()
	changed.emit()
	return total


func owns(item: GearItem) -> bool:
	return item.id in owned


func is_equipped(item: GearItem) -> bool:
	return equipped.get(item.slot) == item.id


## Beli barang. Umpan boleh dibeli berulang kali (tambah satu pek).
func buy(item: GearItem) -> bool:
	if coins < item.price:
		return false
	if item.pack_size == 0 and owns(item):
		return false
	coins -= item.price
	if not owns(item):
		owned.append(item.id)
	if item.pack_size > 0:
		bait_left[item.id] = bait_left.get(item.id, 0) + item.pack_size
	changed.emit()
	return true


func equip(item: GearItem) -> void:
	if not owns(item):
		return
	equipped[item.slot] = item.id
	changed.emit()


## Baki umpan yang sedang dipakai, -1 kalau tak habis-habis.
func bait_count() -> int:
	var bait := equipped_item(GearItem.Slot.UMPAN)
	return bait_left.get(bait.id, 0) if bait.pack_size > 0 else -1


## Ikan makan umpan: tolak satu. Kalau habis, tukar balik ke umpan percuma.
## Pulangkan true kalau umpan baru habis.
func use_bait() -> bool:
	var bait := equipped_item(GearItem.Slot.UMPAN)
	if bait.pack_size == 0:
		return false
	bait_left[bait.id] = maxi(bait_left.get(bait.id, 0) - 1, 0)
	var empty: bool = bait_left[bait.id] == 0
	if empty:
		equipped[GearItem.Slot.UMPAN] = GearCatalog.starter(GearItem.Slot.UMPAN).id
	changed.emit()
	return empty


## Gabung statistik semua barang yang dipakai untuk FishingRod.
func build_stats() -> RodStats:
	var s := RodStats.new()
	var rod := equipped_item(GearItem.Slot.JORAN)
	s.display_name = rod.display_name
	s.max_cast_distance = rod.cast_distance
	s.charge_time = rod.charge_time
	s.reel_force = rod.power
	var reel := equipped_item(GearItem.Slot.KEKILI)
	s.reel_speed = reel.reel_speed
	s.drag_threshold = reel.drag_threshold
	s.line_break_tension = equipped_item(GearItem.Slot.TALI).line_strength
	var hook := equipped_item(GearItem.Slot.MATA_KAIL)
	s.strike_window = hook.strike_window
	s.size_bias = hook.size_bias
	var bait := equipped_item(GearItem.Slot.UMPAN)
	s.bite_mult = bait.bite_mult
	s.rare_luck = bait.rare_luck
	return s


func to_dict() -> Dictionary:
	var eq := {}
	for slot in equipped:
		eq[GearItem.SLOT_NAMES[slot]] = equipped[slot]
	return {
		"versi": 1,
		"syiling": coins,
		"beg": bag,
		"barang": owned,
		"dipakai": eq,
		"umpan": bait_left,
		"rekod": records,
	}


## Baca semula dari fail simpanan. Barang yang dah tak wujud diabaikan.
static func from_dict(d: Dictionary) -> PlayerData:
	var p := PlayerData.new()
	p.coins = int(d.get("syiling", START_COINS))
	for f in d.get("beg", []):
		if f is Dictionary and f.has_all(["fish", "name", "kg", "value"]):
			p.bag.append({
				"fish": str(f.fish), "name": str(f.name), "kg": float(f.kg),
				"value": int(f.value), "rarity": int(f.get("rarity", 0)),
			})
	for id in d.get("barang", []):
		if GearCatalog.find(str(id)) and not str(id) in p.owned:
			p.owned.append(str(id))
	var eq: Dictionary = d.get("dipakai", {})
	for slot in GearItem.Slot.values():
		var item := GearCatalog.find(str(eq.get(GearItem.SLOT_NAMES[slot], "")))
		if item and item.slot == slot and p.owns(item):
			p.equipped[slot] = item.id
	var baits: Dictionary = d.get("umpan", {})
	for id in baits:
		p.bait_left[str(id)] = int(baits[id])
	if p.bait_count() == 0:
		p.equipped[GearItem.Slot.UMPAN] = GearCatalog.starter(GearItem.Slot.UMPAN).id
	var recs: Dictionary = d.get("rekod", {})
	for id in recs:
		p.records[str(id)] = float(recs[id])
	return p
