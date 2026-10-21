extends Node3D
## Sambung semua bahagian: data pemain (syiling, beg, peralatan), simpan
## automatik, tunjuk ikan yang dapat, dan selamatkan pemain kalau terjatuh
## dalam kolam.

@export var rod: FishingRod
@export var angler: Angler
@export var hud: HUD
@export var menu: GameMenu

var data: PlayerData

var _spawn: Transform3D


func _ready() -> void:
	_spawn = angler.global_transform
	rod.caught.connect(_on_caught)
	rod.bait_taken.connect(_on_bait_taken)
	menu.reset_requested.connect(reset_progress)
	_use_data(SaveGame.load_data())


## Padam simpanan dan mula semula dari kosong.
func reset_progress() -> void:
	SaveGame.erase()
	_use_data(PlayerData.new())
	SaveGame.save(data)


func _use_data(d: PlayerData) -> void:
	data = d
	data.changed.connect(_on_data_changed)
	menu.setup(data)
	_apply()


## Setiap kali data berubah: kemas kini joran, HUD, dan simpan terus.
func _on_data_changed() -> void:
	_apply()
	SaveGame.save(data)


func _apply() -> void:
	rod.rod = data.build_stats()
	hud.refresh(data)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and data:
		SaveGame.save(data)


func _physics_process(_delta: float) -> void:
	if angler.global_position.y < -1.0:
		angler.global_transform = _spawn
		angler.velocity = Vector3.ZERO
		angler.reset_physics_interpolation()
		hud.show_message("Eh, jangan terjun kolam!")


func _on_bait_taken() -> void:
	var bait := data.equipped_item(GearItem.Slot.UMPAN).display_name
	if data.use_bait():
		hud.show_message("%s dah habis. Tukar ke cacing." % bait)


func _on_caught(fish: HookedFish) -> void:
	var fish_name := fish.species.display_name
	_show_fish(fish)
	if data.bag_full():
		hud.show_message("Beg penuh! %s dilepaskan. Jual ikan dulu (BEG)." % fish_name)
		return
	var record := data.add_catch(fish)
	var text := "Dapat %s %.2f kg (%s, %d syiling)" % [
		fish_name, fish.weight, FishSpecies.RARITY_NAMES[fish.species.rarity], fish.value()]
	hud.show_message(text + ("  REKOD BARU!" if record else ""))


## Ikan tergantung di hujung joran sekejap, berpusing.
func _show_fish(fish: HookedFish) -> void:
	var model := FishModel.build(fish.species, fish.weight)
	angler.rod_tip.add_child(model)
	model.position = Vector3(0, -0.5, 0)
	model.rotation.x = -PI / 2
	var tw := create_tween()
	tw.tween_property(model, "rotation:y", TAU * 2.0, 2.5)
	tw.tween_callback(model.queue_free)
