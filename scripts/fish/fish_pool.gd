class_name FishPool
extends Area3D
## Kawasan air yang ada ikan (kolam, sungai, tasik...).
## Permukaan air = kedudukan Y node ini. Bentuk collision mesti di bawahnya.

@export var area_name := "Kolam Kampung"
@export var species: Array[FishSpecies] = []
## Julat masa (saat) sebelum ikan menyambar umpan.
@export var bite_delay := Vector2(3.0, 10.0)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func water_height() -> float:
	return global_position.y


## rare_luck datang dari umpan: setiap tahap kejarangan didarab sekali lagi,
## jadi umpan "ikan jarang x2" buat ikan Sangat Jarang 8x lebih kerap.
func roll_species(rare_luck := 1.0) -> FishSpecies:
	var total := 0.0
	for s in species:
		total += _chance(s, rare_luck)
	var r := randf() * total
	for s in species:
		r -= _chance(s, rare_luck)
		if r <= 0.0:
			return s
	return species.back()


func _chance(s: FishSpecies, rare_luck: float) -> float:
	return s.spawn_weight * pow(rare_luck, s.rarity)


## bite_mult datang dari umpan: < 1 = ikan makan lebih cepat.
func roll_bite_delay(bite_mult := 1.0) -> float:
	return randf_range(bite_delay.x, bite_delay.y) * bite_mult


func _on_body_entered(body: Node3D) -> void:
	if body is Bobber:
		body.enter_water(self)
