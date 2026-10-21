class_name FishingRod
extends Node
## Otak memancing: charge → lontar → tunggu → sentap → tarik-tali → dapat / putus.

signal caught(fish: HookedFish)
## Ikan makan umpan (umpan berkurang satu).
signal bait_taken
signal message(text: String)

enum State { IDLE, CHARGING, FLYING, WAITING, BITING, FIGHTING, RETRIEVING }

@export var rod: RodStats
@export var angler: Angler
@export var bobber: Bobber
@export var line: FishingLine

@export_group("Lontaran")
@export var launch_angle := 32.0
## Ketepatan berkurang bila charge penuh (darjah).
@export var full_charge_spread := 4.0

@export_group("Tarik-tali")
## Jarak (meter) ikan dikira dah sampai ke tangan.
@export var land_distance := 2.0
## Tali kendur terlalu lama (saat) = ikan terlepas.
@export var slack_escape_time := 2.5
@export var slack_tension := 0.08

var state := State.IDLE
var charge := 0.0
## 0 - 1, nisbah ketegangan tali berbanding had putus.
var tension := 0.0
var fish: HookedFish
## Panjang tali mendatar (meter) dari hujung joran ke pelampung.
var line_length := 0.0

var _timer := 0.0
var _slack_timer := 0.0
var _pool: FishPool
var _wander := Vector3.ZERO


func _ready() -> void:
	bobber.hide_bobber()
	bobber.landed_in_water.connect(_on_landed_in_water)
	bobber.landed_on_ground.connect(_on_landed_on_ground)


func _process(delta: float) -> void:
	match state:
		State.IDLE:
			if Input.is_action_just_pressed("cast"):
				_enter(State.CHARGING)

		State.CHARGING:
			charge = minf(charge + delta / rod.charge_time, 1.0)
			if not Input.is_action_pressed("cast"):
				_cast()

		State.FLYING:
			# Tersangkut atau jatuh luar peta: tarik balik.
			_timer -= delta
			if _timer <= 0.0 or bobber.global_position.y < -20.0:
				_enter(State.RETRIEVING)

		State.WAITING:
			_timer -= delta
			if Input.is_action_pressed("reel"):
				_retrieve_step(rod.reel_speed * 0.8, delta)
			elif _timer <= 0.0:
				_start_bite()

		State.BITING:
			_timer -= delta
			if Input.is_action_just_pressed("reel"):
				_hook()
			elif _timer <= 0.0:
				message.emit("Ikan lari, tak sempat sentap!")
				fish = null
				_timer = _pool.roll_bite_delay(rod.bite_mult)
				state = State.WAITING

		State.FIGHTING:
			_fight(Input.is_action_pressed("reel"), delta)

		State.RETRIEVING:
			_retrieve_step(rod.reel_speed * 2.5, delta)

	var fighting := state == State.FIGHTING
	line.tension = tension if fighting else 0.1
	angler.rod_bend = lerpf(angler.rod_bend, tension if fighting else 0.0, 8.0 * delta)


## Batalkan pancingan (contoh bila pindah kawasan).
func reset() -> void:
	_enter(State.IDLE)


func _enter(s: State) -> void:
	state = s
	angler.movement_locked = s != State.IDLE
	if s == State.IDLE:
		charge = 0.0
		tension = 0.0
		fish = null
		bobber.hide_bobber()


func _cast() -> void:
	var dist := lerpf(3.0, rod.max_cast_distance, charge)
	var spread := full_charge_spread * charge * charge
	var forward := -angler.global_basis.z
	forward.y = 0.0
	forward = forward.normalized().rotated(Vector3.UP, deg_to_rad(randf_range(-spread, spread)))

	# Halaju projektil untuk capai jarak "dist" pada sudut tetap.
	var ang := deg_to_rad(launch_angle)
	var g: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var speed := sqrt(dist * g / sin(2.0 * ang))
	var vel := forward * cos(ang) * speed + Vector3.UP * sin(ang) * speed

	bobber.launch(angler.rod_tip.global_position, vel)
	_timer = 6.0
	_enter(State.FLYING)


func _on_landed_in_water(p: FishPool) -> void:
	_pool = p
	_timer = p.roll_bite_delay(rod.bite_mult)
	line_length = _flat_distance(bobber.global_position)
	_enter(State.WAITING)


func _on_landed_on_ground() -> void:
	message.emit("Kena darat. Gulung balik.")
	_enter(State.RETRIEVING)


func _start_bite() -> void:
	fish = HookedFish.new(_pool.roll_species(rod.rare_luck), rod.size_bias)
	_timer = rod.strike_window
	bobber.nibble(rod.strike_window)
	state = State.BITING
	bait_taken.emit()
	Input.vibrate_handheld(150)


func _hook() -> void:
	tension = 0.4
	_slack_timer = 0.0
	_wander = Vector3.ZERO
	message.emit("Dapat sambar! Jaga tali jangan putus.")
	state = State.FIGHTING


func _fight(reeling: bool, delta: float) -> void:
	var pull := fish.tick(delta)

	# Ketegangan sasaran: tarikan ikan + daya gulung bila butang ditekan.
	var target_n := pull + rod.reel_force * 0.6 if reeling else pull * 0.35
	var tension_n := lerpf(tension * rod.line_break_tension, target_n, 6.0 * delta)
	tension = tension_n / rod.line_break_tension

	# Drag kekili: lepaskan tali bila terlalu tegang supaya tak terus putus.
	var over := tension - rod.drag_threshold
	if over > 0.0:
		line_length += over * 6.0 * delta
		tension -= over * 3.0 * delta

	if tension >= 1.0:
		message.emit("Tali putus! %s terlepas." % fish.species.display_name)
		_enter(State.IDLE)
		return

	_slack_timer = _slack_timer + delta if tension < slack_tension else 0.0
	if _slack_timer > slack_escape_time:
		message.emit("Tali kendur, ikan lepas mata kail.")
		_enter(State.IDLE)
		return

	# Ikan cepat letih bila tali tegang.
	fish.stamina_left -= delta * (0.4 + tension * 1.2)

	# Gulung masuk lawan tarikan ikan; ikan bawa lari tali bila tak digulung.
	var pull_ratio := pull / (pull + rod.reel_force)
	if reeling:
		line_length -= rod.reel_speed * (1.0 - pull_ratio) * delta
	else:
		line_length += rod.reel_speed * 0.5 * pull_ratio * delta
	line_length = maxf(land_distance * 0.9, line_length)

	# Pelampung ikut ikan: meliuk kiri kanan.
	_wander = _wander.lerp(Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * 1.5, delta)
	var tip := angler.rod_tip.global_position
	var from_rod := bobber.global_position - tip
	from_rod.y = 0.0
	var dir := (from_rod.normalized() + _wander * 0.15).normalized()
	var target := tip + dir * line_length
	target.y = _pool.water_height()
	bobber.drive_towards(target, 4.0 * delta)

	if line_length <= land_distance:
		var f := fish
		_enter(State.IDLE)
		caught.emit(f)


func _retrieve_step(speed: float, delta: float) -> void:
	var target := angler.rod_tip.global_position
	if bobber.pool:
		target.y = bobber.pool.water_height()
	bobber.drive_towards(target, speed * delta)
	if _flat_distance(bobber.global_position) < land_distance:
		_enter(State.IDLE)


func _flat_distance(p: Vector3) -> float:
	var tip := angler.rod_tip.global_position
	return Vector2(p.x - tip.x, p.z - tip.z).length()
