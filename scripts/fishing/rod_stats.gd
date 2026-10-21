class_name RodStats
extends Resource
## Statistik joran + tali + kekili. Kedai (Fasa 2) akan jual variasi fail ni.

@export var display_name := "Joran Buluh"
## Jarak lontaran maksimum (meter).
@export var max_cast_distance := 22.0
## Masa (saat) untuk charge penuh.
@export var charge_time := 1.2
## Had ketegangan tali sebelum putus (Newton).
@export var line_break_tension := 60.0
## Kelajuan gulung kekili (meter/saat).
@export var reel_speed := 1.6
## Daya gulung (Newton) bila butang GULUNG ditekan.
@export var reel_force := 35.0
## Kekili mula lepaskan tali bila ketegangan melebihi nisbah ini.
@export_range(0.5, 1.0) var drag_threshold := 0.85
