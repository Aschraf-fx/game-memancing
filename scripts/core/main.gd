extends Node3D
## Sambung semua bahagian: kira syiling, tunjuk ikan yang dapat,
## dan selamatkan pemain kalau terjatuh dalam kolam.

@export var rod: FishingRod
@export var angler: Angler
@export var hud: HUD

var coins := 0
var catches: Array[Dictionary] = []

var _spawn: Transform3D


func _ready() -> void:
	_spawn = angler.global_transform
	rod.caught.connect(_on_caught)


func _physics_process(_delta: float) -> void:
	if angler.global_position.y < -1.0:
		angler.global_transform = _spawn
		angler.velocity = Vector3.ZERO
		hud.show_message("Eh, jangan terjun kolam!")


func _on_caught(fish: HookedFish) -> void:
	coins += fish.value()
	catches.append({"name": fish.species.display_name, "kg": fish.weight})
	hud.set_coins(coins)
	_show_fish(fish)


## Ikan tergantung di hujung joran sekejap, berpusing.
func _show_fish(fish: HookedFish) -> void:
	var model := FishModel.build(fish.species, fish.weight)
	angler.rod_tip.add_child(model)
	model.position = Vector3(0, -0.5, 0)
	model.rotation.x = -PI / 2
	var tw := create_tween()
	tw.tween_property(model, "rotation:y", TAU * 2.0, 2.5)
	tw.tween_callback(model.queue_free)
