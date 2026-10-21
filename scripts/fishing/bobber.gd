class_name Bobber
extends RigidBody3D
## Pelampung + umpan. Terbang ikut fizik bila dilontar, kemudian terapung
## (dikawal oleh skrip) bila kena air.

signal landed_in_water(pool: FishPool)
signal landed_on_ground

@export var splash: CPUParticles3D

## Kolam tempat pelampung terapung sekarang (null kalau tak dalam air).
var pool: FishPool
var flying := false

var _nibble_timer := 0.0
var _t := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func launch(from: Vector3, velocity: Vector3) -> void:
	pool = null
	flying = true
	freeze = true
	global_position = from
	show()
	freeze = false
	linear_velocity = velocity
	angular_velocity = Vector3.ZERO


## Dipanggil oleh FishPool bila pelampung masuk air.
func enter_water(p: FishPool) -> void:
	if not flying:
		return
	flying = false
	pool = p
	set_deferred("freeze", true)
	set_deferred("linear_velocity", Vector3.ZERO)
	if splash:
		splash.global_position = Vector3(global_position.x, p.water_height(), global_position.z)
		splash.restart()
	landed_in_water.emit(p)


## Gerak pelampung ke arah sasaran (masa gulung / bertarung dengan ikan).
func drive_towards(target: Vector3, max_step: float) -> void:
	freeze = true
	global_position = global_position.move_toward(target, max_step)


## Pelampung terhenjut-henjut bila ikan makan umpan.
func nibble(duration: float) -> void:
	_nibble_timer = duration


func hide_bobber() -> void:
	pool = null
	flying = false
	freeze = true
	hide()


func _process(delta: float) -> void:
	_t += delta
	if pool == null or not freeze:
		return
	_nibble_timer = maxf(_nibble_timer - delta, 0.0)
	var bob := sin(_t * 2.0) * 0.015
	var dip := absf(sin(_t * 22.0)) * 0.08 if _nibble_timer > 0.0 else 0.0
	global_position.y = pool.water_height() + bob - dip


func _on_body_entered(_body: Node) -> void:
	if flying:
		flying = false
		landed_on_ground.emit()
