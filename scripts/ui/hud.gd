class_name HUD
extends CanvasLayer
## Paparan: syiling, umpan, mesej, bar charge, bar ketegangan tali dan "SENTAP!".

@export var rod: FishingRod
@export var message_duration := 3.0

var _coins: Label
var _bait: Label
var _message: Label
var _strike: Label
var _charge: ProgressBar
var _tension: ProgressBar
var _tension_info: Label
var _tension_fill := StyleBoxFlat.new()
var _message_timer := 0.0


func _ready() -> void:
	_coins = _label("Syiling: 0", 30, Vector2(24, 18))
	_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_bait = _label("", 22, Vector2(24, 132))
	_bait.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_message = _label("", 28, Vector2.ZERO)
	_message.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_message.offset_top = 24
	_message.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_strike = _label("SENTAP!", 72, Vector2.ZERO)
	_strike.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_strike.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_strike.grow_vertical = Control.GROW_DIRECTION_BOTH
	_strike.add_theme_color_override("font_color", Color(1, 0.85, 0.2))

	_charge = _bar(Color(0.3, 0.8, 1.0), 0.14)
	_tension = _bar(Color.GREEN, 0.14)
	_tension_fill.set_corner_radius_all(8)
	_tension.add_theme_stylebox_override("fill", _tension_fill)
	_tension_info = _label("", 24, Vector2.ZERO)
	_tension_info.anchor_left = 0.3
	_tension_info.anchor_right = 0.7
	_tension_info.anchor_top = 0.14
	_tension_info.anchor_bottom = 0.14
	_tension_info.offset_top = 32

	rod.message.connect(show_message)


func refresh(data: PlayerData) -> void:
	_coins.text = "Syiling: %d" % data.coins
	var bait := data.equipped_item(GearItem.Slot.UMPAN)
	var left := data.bait_count()
	_bait.text = "%s  |  Umpan: %s%s" % [data.equipped_item(GearItem.Slot.JORAN).display_name,
		bait.display_name, " x%d" % left if left >= 0 else ""]


func show_message(text: String) -> void:
	_message.text = text
	_message.show()
	_message_timer = message_duration


func _process(delta: float) -> void:
	var s := rod.state
	_charge.visible = s == FishingRod.State.CHARGING
	_charge.value = rod.charge

	var fighting := s == FishingRod.State.FIGHTING
	_tension.visible = fighting
	_tension_info.visible = fighting
	if fighting:
		_tension.value = rod.tension
		# Hijau → kuning → merah ikut ketegangan.
		var t := rod.tension
		_tension_fill.bg_color = Color.GREEN.lerp(Color.YELLOW, t * 2.0) if t < 0.5 \
			else Color.YELLOW.lerp(Color.RED, (t - 0.5) * 2.0)
		var info := "Ikan dah letih!" if rod.fish.is_exhausted() else "%.1f m" % rod.line_length
		_tension_info.text = "Ketegangan tali  |  " + info

	_strike.visible = s == FishingRod.State.BITING

	if _message_timer > 0.0:
		_message_timer -= delta
		if _message_timer <= 0.0:
			_message.hide()


func _label(text: String, size: int, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _bar(color: Color, y_ratio: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = 1.0
	bar.show_percentage = false
	bar.anchor_left = 0.3
	bar.anchor_right = 0.7
	bar.anchor_top = y_ratio
	bar.anchor_bottom = y_ratio
	bar.offset_bottom = 28
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.45)
	bg.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("background", bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("fill", fill)
	bar.hide()
	add_child(bar)
	return bar
