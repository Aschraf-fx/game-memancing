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


func roll_species() -> FishSpecies:
	var total := 0.0
	for s in species:
		total += s.spawn_weight
	var r := randf() * total
	for s in species:
		r -= s.spawn_weight
		if r <= 0.0:
			return s
	return species.back()


func roll_bite_delay() -> float:
	return randf_range(bite_delay.x, bite_delay.y)


func _on_body_entered(body: Node3D) -> void:
	if body is Bobber:
		body.enter_water(self)
