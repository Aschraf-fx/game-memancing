extends SceneTree
## Ujian automatik ringkas: jalan, tukar kamera, lontar, sentap, tarik-tali.
## Jalankan: godot --headless --path . -s res://tests/test_flow.gd

var main: Node3D
var rod: FishingRod
var angler: Angler
var failures := 0


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	rod = main.get_node("FishingRod")
	angler = main.get_node("Angler")
	_run.call_deferred()


func _run() -> void:
	await _frames(30)
	_check(angler.is_on_floor(), "pemain berdiri atas pangkalan")
	_check(main.get_node("Water").species.size() == 6, "kolam ada 6 spesies")

	var start := angler.global_position
	Input.action_press("move_forward")
	for i in 30:
		await physics_frame
	Input.action_release("move_forward")
	_check(angler.global_position.z < start.z - 0.5, "pemain boleh berjalan ke depan")

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
	print("  keputusan: %s selepas %.1f s, syiling=%d" % ["DAPAT" if got[0] else "terlepas", frames / 60.0, main.coins])
	_check(got[0], "strategi gulung-lepas dapat ikan")

	# Lontar ke darat (pusing belakang) mesti tarik balik.
	angler.rotate_y(PI)
	Input.action_press("cast")
	await _frames(20)
	Input.action_release("cast")
	await _until(func(): return rod.state == FishingRod.State.IDLE, 600)
	_check(rod.state == FishingRod.State.IDLE, "lontar ke darat, pelampung digulung balik")

	print("SELESAI: %d gagal" % failures)
	quit(1 if failures else 0)


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
