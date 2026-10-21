class_name GameMenu
extends CanvasLayer
## Butang BEG, KEDAI dan PETA di kiri atas, dan menu penuh skrin untuk:
##   BEG IKAN  = tengok dan jual ikan yang dapat
##   KEDAI     = beli dan pakai joran, kekili, tali, mata kail, umpan, kenderaan
##   PETA      = pilih kawasan memancing (kenderaan buka kawasan baru)
## Game berhenti sekejap (pause) bila menu dibuka.
## Semua butang besar supaya senang tekan dengan jari. Tiada scroll
## (senarai guna muka surat) supaya jari tak tertekan JUAL masa nak scroll.

signal reset_requested

enum Tab { BAG, SHOP, MAP }

## Aksi papan kekunci untuk buka setiap menu.
const TAB_ACTIONS := {Tab.BAG: "open_bag", Tab.SHOP: "open_shop", Tab.MAP: "open_map"}
const PAGE_SIZE := 4
const COL_BG := Color(0.07, 0.15, 0.17, 0.97)
const COL_ROW := Color(1, 1, 1, 0.07)
const COL_BUY := Color(0.93, 0.55, 0.12)
const COL_USE := Color(0.16, 0.6, 0.55)
const COL_TAB := Color(0.2, 0.3, 0.33)
const COL_RED := Color(0.75, 0.22, 0.2)
const COL_MAP := Color(0.2, 0.45, 0.75)

@export var rod: FishingRod
@export var hud: HUD
@export var touch: Control

var data: PlayerData
var tab := Tab.BAG
var shop_slot := GearItem.Slot.JORAN
var page := 0

var _bag_button: Button
var _overlay: Control
var _tab_buttons := {}
var _slot_bar: HBoxContainer
var _slot_buttons := {}
var _coins: Label
var _list: VBoxContainer
var _footer: HBoxContainer
var _status: Label
var _confirm_reset := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 3

	var top := HBoxContainer.new()
	top.position = Vector2(24, 64)
	top.add_theme_constant_override("separation", 12)
	add_child(top)
	_bag_button = _button("BEG", COL_TAB, func(): open(Tab.BAG))
	var shop := _button("KEDAI", COL_BUY, func(): open(Tab.SHOP))
	var map := _button("PETA", COL_MAP, func(): open(Tab.MAP))
	for b in [_bag_button, shop, map]:
		b.custom_minimum_size = Vector2(150, 60)
		top.add_child(b)

	_build_overlay()
	_overlay.hide()


func setup(d: PlayerData) -> void:
	if data and data.changed.is_connected(_refresh):
		data.changed.disconnect(_refresh)
	data = d
	data.changed.connect(_refresh)
	_refresh()


func is_open() -> bool:
	return _overlay.visible


func open(which: Tab) -> void:
	if rod.state != FishingRod.State.IDLE:
		hud.show_message("Habiskan pancingan dulu.")
		return
	tab = which
	page = 0
	_confirm_reset = false
	_status.text = ""
	touch.release_all()
	get_tree().paused = true
	_overlay.show()
	_refresh()


func close() -> void:
	_overlay.hide()
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if is_open():
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed(TAB_ACTIONS[tab]):
			close()
			get_viewport().set_input_as_handled()
		return
	for t in TAB_ACTIONS:
		if event.is_action_pressed(TAB_ACTIONS[t]):
			open(t)
			return


# --- Bina menu -------------------------------------------------------------

func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.04
	panel.anchor_right = 0.96
	panel.anchor_top = 0.04
	panel.anchor_bottom = 0.96
	panel.add_theme_stylebox_override("panel", _box(COL_BG, 18, 18))
	_overlay.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	# Kepala: tab, syiling, tutup.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	col.add_child(head)
	_tab_buttons[Tab.BAG] = _button("BEG IKAN", COL_TAB, func(): _switch(Tab.BAG))
	_tab_buttons[Tab.SHOP] = _button("KEDAI", COL_TAB, func(): _switch(Tab.SHOP))
	_tab_buttons[Tab.MAP] = _button("PETA", COL_TAB, func(): _switch(Tab.MAP))
	for t in _tab_buttons:
		_tab_buttons[t].custom_minimum_size.x = 170
		head.add_child(_tab_buttons[t])
	_coins = _label("", 28, Color(1, 0.86, 0.3))
	_coins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(_coins)
	var x := _button("TUTUP", COL_RED, close)
	x.custom_minimum_size.x = 140
	head.add_child(x)

	# Jenis barang kedai.
	_slot_bar = HBoxContainer.new()
	_slot_bar.add_theme_constant_override("separation", 8)
	col.add_child(_slot_bar)
	for slot in GearItem.Slot.values():
		var b := _button(GearItem.SLOT_NAMES[slot].to_upper(), COL_TAB, func(): _switch_slot(slot))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 54
		b.add_theme_font_size_override("font_size", 22)
		_slot_buttons[slot] = b
		_slot_bar.add_child(b)

	_list = VBoxContainer.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	col.add_child(_list)

	_footer = HBoxContainer.new()
	_footer.add_theme_constant_override("separation", 10)
	col.add_child(_footer)
	_status = _label("", 22, Color(0.7, 1, 0.75))
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _switch(t: Tab) -> void:
	tab = t
	page = 0
	_status.text = ""
	_refresh()


func _switch_slot(slot: GearItem.Slot) -> void:
	shop_slot = slot
	page = 0
	_refresh()


func _refresh() -> void:
	if data == null:
		return
	_bag_button.text = "BEG %d/%d" % [data.bag.size(), PlayerData.BAG_CAPACITY]
	if not is_open():
		return
	_coins.text = "Syiling: %d" % data.coins
	for t in _tab_buttons:
		_tint(_tab_buttons[t], COL_USE if t == tab else COL_TAB)
	_slot_bar.visible = tab == Tab.SHOP
	for slot in _slot_buttons:
		_tint(_slot_buttons[slot], COL_USE if slot == shop_slot else COL_TAB)

	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	for c in _footer.get_children():
		_footer.remove_child(c)
		if c != _status:
			c.queue_free()
	_footer.add_child(_status)

	match tab:
		Tab.BAG:
			_fill_bag()
		Tab.SHOP:
			_fill_shop()
		Tab.MAP:
			_fill_map()


## Pilih muka surat yang sah, tambah butang < > di bawah kalau lebih dari satu
## muka surat, dan pulangkan julat indeks untuk muka surat ni.
func _page_range(count: int) -> Array:
	var pages := maxi(1, ceili(count / float(PAGE_SIZE)))
	page = clampi(page, 0, pages - 1)
	if pages > 1:
		var prev := _button("<", COL_TAB, func(): page -= 1; _refresh())
		var next := _button(">", COL_TAB, func(): page += 1; _refresh())
		prev.disabled = page == 0
		next.disabled = page == pages - 1
		_footer.add_child(prev)
		_footer.add_child(_label("%d/%d" % [page + 1, pages], 24, Color.WHITE))
		_footer.add_child(next)
	return range(page * PAGE_SIZE, mini((page + 1) * PAGE_SIZE, count))


func _fill_bag() -> void:
	if data.bag.is_empty():
		_list.add_child(_label("Beg kosong. Pergi memancing dulu!", 26, Color(0.8, 0.85, 0.85)))
	for i in _page_range(data.bag.size()):
		var f: Dictionary = data.bag[i]
		var rarity: int = f.get("rarity", 0)
		var info := "%.2f kg  |  %s" % [f.kg, FishSpecies.RARITY_NAMES[rarity]]
		var sell := _button("JUAL  %d" % f.value, COL_BUY, _sell.bind(i))
		_list.add_child(_row(f.name, FishSpecies.RARITY_COLORS[rarity], info, "", [sell]))

	var all := _button("JUAL SEMUA  %d" % data.bag_value(), COL_BUY, _sell_all)
	all.disabled = data.bag.is_empty()
	all.custom_minimum_size.x = 300
	_footer.add_child(all)


func _fill_shop() -> void:
	var items := GearCatalog.in_slot(shop_slot)
	for i in _page_range(items.size()):
		var item := items[i]
		var buttons: Array[Button] = []
		var title := item.display_name
		if item.slot == GearItem.Slot.KENDERAAN and (data.owns(item) or data.vehicle_not_needed(item)):
			var b := _small_button("DIMILIKI" if data.owns(item) else "ADA YANG\nLEBIH BAIK", COL_USE)
			b.disabled = true
			buttons.append(b)
		elif item.pack_size > 0:
			var left: int = data.bait_left.get(item.id, 0)
			if left > 0:
				title += "  (baki %d)" % left
				buttons.append(_equip_button(item))
			var buy := _button("BELI  %d" % item.price, COL_BUY, _buy.bind(item))
			buy.disabled = data.coins < item.price
			buttons.append(buy)
		elif data.owns(item):
			buttons.append(_equip_button(item))
		else:
			var buy := _button("BELI  %d" % item.price, COL_BUY, _buy.bind(item))
			buy.disabled = data.coins < item.price
			buttons.append(buy)
		var color := Color(1, 0.86, 0.3) if data.is_equipped(item) else Color.WHITE
		_list.add_child(_row(title, color, item.stats_text(), item.description, buttons))

	var reset := _button("TEKAN LAGI UNTUK PADAM" if _confirm_reset else "PADAM SIMPANAN", COL_RED, _reset)
	reset.add_theme_font_size_override("font_size", 18)
	reset.custom_minimum_size = Vector2(0, 48)
	_footer.add_child(reset)


func _fill_map() -> void:
	var areas := AreaCatalog.all()
	for i in _page_range(areas.size()):
		var area := areas[i]
		var b: Button
		if area.id == data.area:
			b = _small_button("DI SINI", COL_USE)
			b.disabled = true
		elif data.can_visit(area):
			b = _button("PERGI", COL_MAP, _go.bind(area))
		else:
			b = _small_button("PERLU\n" + _vehicle_for(area).display_name.to_upper(), COL_TAB)
			b.disabled = true
		var color := Color(1, 0.86, 0.3) if area.id == data.area else Color.WHITE
		_list.add_child(_row(area.display_name, color, area.place, "Ikan: " + area.fish_names(), [b]))
	if _status.text == "":
		_status.text = "Beli kenderaan di KEDAI untuk buka kawasan baru."


func _vehicle_for(area: FishingArea) -> GearItem:
	for item in GearCatalog.in_slot(GearItem.Slot.KENDERAAN):
		if item.tier == area.vehicle_tier:
			return item
	return GearCatalog.starter(GearItem.Slot.KENDERAAN)


func _equip_button(item: GearItem) -> Button:
	if data.is_equipped(item):
		var b := _button("DIPAKAI", COL_USE, func(): pass)
		b.disabled = true
		return b
	return _button("PAKAI", COL_USE, _equip.bind(item))


# --- Tindakan -----------------------------------------------------------------

func _sell(index: int) -> void:
	var f: Dictionary = data.bag[index]
	_status.text = "Jual %s, dapat %d syiling." % [f.name, f.value]
	data.sell(index)


func _sell_all() -> void:
	var n := data.bag.size()
	_status.text = "Jual %d ekor ikan, dapat %d syiling." % [n, data.sell_all()]


func _buy(item: GearItem) -> void:
	if not data.buy(item):
		_status.text = "Syiling tak cukup."
		return
	if item.slot == GearItem.Slot.KENDERAAN:
		_status.text = "Beli %s! %s. Tekan PETA untuk pergi." % [item.display_name, item.stats_text()]
		return
	if item.pack_size > 0:
		_status.text = "Beli %d %s. Dah terus pakai." % [item.pack_size, item.display_name]
	else:
		_status.text = "Beli %s! Dah terus pakai." % item.display_name
	data.equip(item)


func _equip(item: GearItem) -> void:
	_status.text = "Pakai %s." % item.display_name
	data.equip(item)


func _go(area: FishingArea) -> void:
	if data.travel(area):
		close()


func _reset() -> void:
	if not _confirm_reset:
		_confirm_reset = true
		_refresh()
		return
	_confirm_reset = false
	reset_requested.emit()
	_status.text = "Simpanan dipadam. Mula baru."


# --- Pembantu UI ---------------------------------------------------------------

func _row(title: String, title_color: Color, info: String, desc: String, buttons: Array) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(COL_ROW, 12, 10))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	panel.add_child(h)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 0)
	h.add_child(v)
	v.add_child(_label(title, 26, title_color))
	v.add_child(_label(info, 20, Color(0.85, 0.92, 0.92)))
	if desc != "":
		var d := _label(desc, 17, Color(0.65, 0.72, 0.72))
		d.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(d)
	for b in buttons:
		b.custom_minimum_size = Vector2(170, 64)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(b)
	return panel


func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, color: Color, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 60)
	b.add_theme_font_size_override("font_size", 24)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(state, Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.45))
	_tint(b, color)
	b.pressed.connect(on_press)
	return b


## Butang dengan tulisan kecil (boleh dua baris).
func _small_button(text: String, color: Color) -> Button:
	var b := _button(text, color, func(): pass)
	b.add_theme_font_size_override("font_size", 17)
	return b


func _tint(b: Button, color: Color) -> void:
	b.add_theme_stylebox_override("normal", _box(color, 12, 8))
	b.add_theme_stylebox_override("hover", _box(color.lightened(0.12), 12, 8))
	b.add_theme_stylebox_override("pressed", _box(color.darkened(0.2), 12, 8))
	b.add_theme_stylebox_override("disabled", _box(color.darkened(0.45), 12, 8))


func _box(color: Color, radius: int, margin: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	return s
