extends SceneTree
## Ujian automatik ringkas: jalan, tukar kamera, lontar, sentap, tarik-tali,
## beg ikan, jual, kedai, umpan dan simpan/muat data.
## Jalankan: godot --headless --path . -s res://tests/test_flow.gd

var main: Node3D
var rod: FishingRod
var angler: Angler
var failures := 0


func _initialize() -> void:
	seed(20261021)  # ikan sama setiap kali supaya ujian stabil
	SaveGame.path = "user://ujian_simpanan.json"  # jangan kacau simpanan sebenar
	SaveGame.erase()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	rod = main.get_node("FishingRod")
	angler = main.get_node("Angler")
	_run.call_deferred()


func _run() -> void:
	await _frames(30)
	_check(angler.is_on_floor(), "pemain berdiri atas pangkalan")
	_check(main.get_node("Water").species.size() == 7, "kolam ada 7 spesies")
	_check(rod.rod.max_cast_distance == 22.0, "mula dengan Joran Buluh")
	_check(main.data.coins == PlayerData.START_COINS, "syiling permulaan")

	var start := angler.global_position
	Input.action_press("move_forward")
	for i in 30:
		await physics_frame
	Input.action_release("move_forward")
	_check(angler.global_position.z < start.z - 0.5, "pemain boleh berjalan ke depan")

	# Sentuhan dua jari: jalan dengan joystick sambil seret kamera.
	var touch: Control = main.get_node("Touch/TouchControls")
	var lay: Dictionary = touch._layout()
	var stick: Vector2 = lay["stick"][0]
	var look_start := Vector2(touch.size.x * 0.75, touch.size.y * 0.4)
	_touch(0, stick, true)
	_drag(0, stick + Vector2(0, -lay["stick"][1]))
	_touch(1, look_start, true)
	var yaw0 := angler.rotation.y
	var pos0 := angler.global_position
	for i in 20:
		_drag(1, look_start + Vector2(4 * (i + 1), 0))
		await physics_frame
	var turned := absf(angle_difference(yaw0, angler.rotation.y))
	_check(angler.global_position.distance_to(pos0) > 0.3, "jalan dengan joystick sambil seret kamera")
	_check(turned > deg_to_rad(5) and turned < deg_to_rad(40), "kamera pusing ikut seretan (%.1f darjah)" % rad_to_deg(turned))
	var yaw1 := angler.rotation.y
	_drag(1, look_start + Vector2(900, 0))  # lompatan palsu dari browser
	await physics_frame
	await physics_frame
	_check(absf(angle_difference(yaw1, angler.rotation.y)) < deg_to_rad(1), "lompatan seretan besar diabaikan")
	_touch(1, look_start, false)
	_touch(0, stick, false)
	await physics_frame

	var mode := angler.cam_mode
	Input.action_press("toggle_camera")
	await _frames(2)
	Input.action_release("toggle_camera")
	_check(angler.cam_mode != mode, "tukar kamera FPV/TPV")

	# Lontar dengan charge separuh.
	Input.action_press("cast")
	await _frames(40)
	Input.action_release("cast")
	await _frames(2)
	_check(rod.state == FishingRod.State.FLYING, "pelampung terbang selepas lontar")
	await _until(func(): return rod.state != FishingRod.State.FLYING, 300)
	_check(rod.state == FishingRod.State.WAITING, "pelampung jatuh dalam air (state=%s)" % FishingRod.State.keys()[rod.state])
	print("  jarak lontaran: %.1f m" % rod.line_length)

	# Percepat gigitan ikan.
	rod._timer = 0.1
	await _until(func(): return rod.state == FishingRod.State.BITING, 60)
	_check(rod.state == FishingRod.State.BITING, "ikan menggigit")
	Input.action_press("reel")
	await _frames(2)
	_check(rod.state == FishingRod.State.FIGHTING, "sentap berjaya, mula tarik-tali")
	print("  ikan: %s %.2f kg" % [rod.fish.species.display_name, rod.fish.weight])

	# Strategi mudah: gulung bila tegang < 0.75, lepas bila lebih.
	var got := [false]
	rod.caught.connect(func(_f): got[0] = true)
	var frames := 0
	while rod.state == FishingRod.State.FIGHTING and frames < 60 * 120:
		if rod.tension > 0.75:
			Input.action_release("reel")
		elif rod.tension < 0.45:
			Input.action_press("reel")
		await process_frame
		frames += 1
	Input.action_release("reel")
	_check(rod.state == FishingRod.State.IDLE, "tarik-tali tamat")
	print("  keputusan: %s selepas %.1f s" % ["DAPAT" if got[0] else "terlepas", frames / 60.0])
	_check(got[0], "strategi gulung-lepas dapat ikan")
	await _economy()

	# Lontar ke darat (pusing belakang) mesti tarik balik.
	angler.rotate_y(PI)
	Input.action_press("cast")
	await _frames(20)
	Input.action_release("cast")
	await _until(func(): return rod.state == FishingRod.State.IDLE, 600)
	_check(rod.state == FishingRod.State.IDLE, "lontar ke darat, pelampung digulung balik")

	SaveGame.erase()
	print("SELESAI: %d gagal" % failures)
	quit(1 if failures else 0)


func _economy() -> void:
	var data: PlayerData = main.data
	var menu: GameMenu = main.get_node("Menu")
	_check(data.bag.size() == 1, "ikan masuk beg")
	var fish: Dictionary = data.bag[0]
	print("  dalam beg: %s %.2f kg = %d syiling" % [fish.name, fish.kg, fish.value])
	_check(fish.value > 0, "ikan ada harga")

	# Harga: lebih berat dan lebih jarang = lebih mahal.
	var tilapia: FishSpecies = load("res://data/fish/tilapia.tres")
	var toman: FishSpecies = load("res://data/fish/toman.tres")
	_check(tilapia.price_for(1.4) > tilapia.price_for(0.4), "ikan berat lebih mahal")
	_check(toman.price_for(3.0) > toman.coins_per_kg * 3.0 * 3.9, "ikan sangat jarang dapat gandaan harga")

	# Umpan jarang buat ikan jarang lebih kerap.
	var pool: FishPool = main.get_node("Water")
	var count := func(luck: float) -> int:
		var n := 0
		for i in 3000:
			if pool.roll_species(luck).rarity >= 2:
				n += 1
		return n
	var plain: int = count.call(1.0)
	var lucky: int = count.call(3.0)
	print("  ikan jarang per 3000: cacing=%d, umpan jarang=%d" % [plain, lucky])
	_check(lucky > plain * 2, "umpan jarang tambah peluang ikan jarang")

	# Menu buka = game pause. Tak boleh buka masa memancing.
	menu.open(GameMenu.Tab.BAG)
	await _frames(2)
	_check(menu.is_open() and paused, "buka beg, game pause")
	var coins0 := data.coins
	menu._sell(0)
	await _frames(2)
	_check(data.bag.is_empty() and data.coins == coins0 + fish.value, "jual ikan dapat syiling")

	# Kedai: syiling tak cukup, kemudian cukup.
	var gentian := GearCatalog.find("joran_gentian")
	data.coins = 10
	menu._buy(gentian)
	_check(not data.owns(gentian), "tak boleh beli kalau syiling tak cukup")
	data.coins = 1000
	menu._buy(gentian)
	_check(data.owns(gentian) and data.coins == 1000 - gentian.price, "beli joran gentian")
	_check(rod.rod.max_cast_distance == gentian.cast_distance, "joran baru terus dipakai (lontar %d m)" % rod.rod.max_cast_distance)
	menu._buy(gentian)
	_check(data.coins == 1000 - gentian.price, "tak boleh beli joran sama dua kali")
	menu._buy(GearCatalog.find("tali_nilon_12"))
	_check(rod.rod.line_break_tension == 90.0, "tali baru tambah had putus")

	var dedak := GearCatalog.find("umpan_dedak")
	menu._buy(dedak)
	_check(data.bait_count() == dedak.pack_size and rod.rod.bite_mult < 1.0, "beli dan pakai umpan dedak")
	for i in dedak.pack_size - 1:
		data.use_bait()
	_check(data.bait_count() == 1, "umpan berkurang bila ikan makan")
	data.use_bait()
	_check(data.equipped_item(GearItem.Slot.UMPAN).id == "umpan_cacing", "umpan habis, tukar balik ke cacing")

	for slot in GearItem.Slot.values():
		menu.shop_slot = slot
		menu._switch(GameMenu.Tab.SHOP)
		await process_frame
	menu.close()
	await _frames(2)
	_check(not paused, "tutup menu, game sambung")

	# Simpan dan muat semula.
	var gold := data.coins
	var loaded := SaveGame.load_data()
	_check(loaded.coins == gold, "simpanan: syiling sama")
	_check(loaded.owns(gentian) and loaded.equipped_item(GearItem.Slot.JORAN) == gentian, "simpanan: joran dipakai sama")
	_check(loaded.build_stats().line_break_tension == 90.0, "simpanan: statistik sama")
	var broken := FileAccess.open(SaveGame.path, FileAccess.WRITE)
	broken.store_string("{rosak")
	broken.close()
	_check(SaveGame.load_data().coins == PlayerData.START_COINS, "fail rosak, mula baru tanpa crash")
	SaveGame.save(data)

	menu.open(GameMenu.Tab.SHOP)
	menu._reset()
	menu._reset()
	_check(main.data.coins == PlayerData.START_COINS and main.data.owned.size() == 5, "padam simpanan, mula baru")
	menu.close()

	# Tak boleh buka kedai masa ikan sedang menggigit.
	rod.state = FishingRod.State.BITING
	menu.open(GameMenu.Tab.SHOP)
	_check(not menu.is_open(), "kedai tak boleh buka masa memancing")
	rod._enter(FishingRod.State.IDLE)
	await _frames(2)


func _touch(index: int, pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = index
	ev.position = root.get_final_transform() * pos  # koordinat skrin sebenar
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _drag(index: int, pos: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = index
	ev.position = root.get_final_transform() * pos
	Input.parse_input_event(ev)


func _check(ok: bool, what: String) -> void:
	print(("  OK   " if ok else "  GAGAL ") + what)
	if not ok:
		failures += 1


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _until(cond: Callable, max_frames: int) -> void:
	for i in max_frames:
		if cond.call():
			return
		await process_frame
