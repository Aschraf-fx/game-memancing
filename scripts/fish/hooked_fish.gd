class_name HookedFish
extends RefCounted
## Ikan yang sedang terkena mata kail (logik sahaja, tiada model).

var species: FishSpecies
var weight: float
var stamina_left: float

var _surge_timer := 0.0
var _current_pull := 0.0


## size_bias datang dari mata kail: nilai lebih rendah = lebih kerap ikan besar.
func _init(s: FishSpecies, size_bias := 2.2) -> void:
	species = s
	# Taburan condong ke saiz kecil; ikan besar jarang dapat.
	weight = lerpf(s.min_weight, s.max_weight, pow(randf(), size_bias))
	var size01 := inverse_lerp(s.min_weight, s.max_weight, weight)
	stamina_left = s.stamina * lerpf(0.8, 1.4, size01)


func is_exhausted() -> bool:
	return stamina_left <= 0.0


func value() -> int:
	return species.price_for(weight)


## Tarikan ikan (Newton) untuk frame ini. Ikan meronta secara rawak dan
## makin lemah bila letih.
func tick(delta: float) -> float:
	_surge_timer -= delta
	if _surge_timer <= 0.0:
		var surge := randf() < species.aggression
		var size_factor := 0.6 + weight / maxf(0.01, species.max_weight)
		var strength := randf_range(1.2, 1.8) if surge else randf_range(0.3, 0.8)
		_current_pull = species.pull_strength * size_factor * strength
		_surge_timer = randf_range(0.6, 1.5) if surge else randf_range(0.8, 2.5)
	var fatigue := clampf(stamina_left / species.stamina, 0.0, 1.0)
	return _current_pull * lerpf(0.25, 1.0, fatigue)
