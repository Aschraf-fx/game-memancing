extends SceneTree
## Ujian automatik ringkas: jalan, tukar kamera, lontar, sentap, tarik-tali.
## Jalankan: godot --headless --path . -s res://tests/test_flow.gd

var main: Node3D
var rod: FishingRod
var angler: Angler
var failures := 0


func _initialize() -> void:
	seed(20261021)  # ikan sama setiap kali supaya ujian stabil
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
