extends CanvasLayer
## Interfaz: HUD de carrera, menú, personajes, misiones, logros, pausa y fin de partida.

signal play_pressed
signal retry_pressed
signal menu_pressed
signal pause_pressed
signal resume_pressed
signal look_preview(look: Dictionary)
signal page_opened(page: String)
signal update_pressed

const TAB_NAMES := {"char": "Personajes", "costume": "Disfraces", "head": "Gorros", "face": "Cara", "back": "Espalda"}

const W := 540.0
const H := 960.0

var C_TEAL := Color("14b8a6")
var C_CORAL := Color("ff6b6b")
var C_SUN := Color("ffc233")
var C_PANEL := Color(0.05, 0.13, 0.21, 0.94)
var C_MUTED := Color("a7c4d9")
var C_GREEN := Color("4ade80")

var root: Control
var pages: Dictionary = {}

# HUD de juego
var coin_lbl: Label
var score_lbl: Label
var mult_lbl: Label
var power_lbl: Label
var banner_lbl: Label
var toast_lbl: Label
var hint_lbl: Label
var mission_lbls: Array = []
var banner_tween: Tween
var toast_q: Array = []
var toast_t := 0.0

# menú
var menu_coins: Label
var menu_best: Label

# tienda
var shop_tab := "char"
var shop_idx := 0
var shop_box: VBoxContainer
var shop_coins: Label
var update_box: Control
var update_lbl: Label
var music_btn: Button
var sfx_btn: Button
var menu_ach_btn: Button

# otras páginas con contenido dinámico
var missions_box: VBoxContainer
var ach_box: VBoxContainer
var over_box: VBoxContainer


func _ready() -> void:
	layer = 10
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_game()
	_build_menu()
	_build_shop()
	_build_missions()
	_build_ach()
	_build_over()
	_build_pause()
	show_menu()


# ---------- Utilidades de UI ----------
func _lbl(text: String, size: int = 22, color: Color = Color.WHITE, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.03, 0.09, 0.16, 0.95))
	l.add_theme_constant_override("outline_size", maxi(2, int(size * 0.14)))
	l.horizontal_alignment = align as HorizontalAlignment
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _place(c: Control, x: float, y: float, w: float, h: float) -> void:
	c.position = Vector2(x, y)
	c.size = Vector2(w, h)


func _sb(bg: Color, radius: int = 18, border: Color = Color(0, 0, 0, 0), bw: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(bw)
	return s


func _btn(text: String, color: Color, size: int = 26, w: float = 300.0, h: float = 64.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, h)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_stylebox_override("normal", _sb(color, 22, color.lightened(0.4), 3))
	b.add_theme_stylebox_override("hover", _sb(color.lightened(0.12), 22, color.lightened(0.55), 3))
	b.add_theme_stylebox_override("pressed", _sb(color.darkened(0.22), 22, color.lightened(0.2), 3))
	b.add_theme_stylebox_override("disabled", _sb(Color(0.28, 0.34, 0.4), 22, Color(0.4, 0.46, 0.52), 2))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(0.78, 0.83, 0.88))
	b.pressed.connect(func(): Sfx.play("click"))
	return b


func _page(id: String) -> Control:
	var p := Control.new()
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(p)
	pages[id] = p
	return p


func _panel(parent: Control, rect: Rect2, bg: Color) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(bg, 28, Color(1, 1, 1, 0.14), 2))
	parent.add_child(p)
	_place(p, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 22)
	p.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	m.add_child(v)
	return v


func _clear(box: Control) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _bar(value: int, target: int, color: Color) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.max_value = maxf(1.0, float(target))
	pb.value = float(value)
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 14)
	pb.add_theme_stylebox_override("background", _sb(Color(1, 1, 1, 0.12), 7))
	pb.add_theme_stylebox_override("fill", _sb(color, 7))
	return pb


func _row(title: String, value: int, target: int, right: String, done: bool) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	var h := HBoxContainer.new()
	var l := _lbl(title, 19, C_GREEN if done else Color.WHITE)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_child(l)
	h.add_child(_lbl(right, 17, C_SUN if not done else C_GREEN, HORIZONTAL_ALIGNMENT_RIGHT))
	v.add_child(h)
	v.add_child(_bar(value, target, C_GREEN if done else C_TEAL))
	return v


func _show(id: String) -> void:
	for k in pages:
		(pages[k] as Control).visible = (k == id)


# ---------- HUD de carrera ----------
func _build_game() -> void:
	var g := _page("game")
	var bar := Panel.new()
	bar.add_theme_stylebox_override("panel", _sb(Color(0.03, 0.1, 0.18, 0.55), 20))
	g.add_child(bar)
	_place(bar, 14, 14, W - 28, 62)

	coin_lbl = _lbl("● 0", 30, C_SUN)
	g.add_child(coin_lbl)
	_place(coin_lbl, 30, 22, 150, 46)

	score_lbl = _lbl("0", 34, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	g.add_child(score_lbl)
	_place(score_lbl, 170, 20, 200, 50)

	var pb := _btn("II", C_TEAL, 24, 54, 46)
	g.add_child(pb)
	_place(pb, W - 84, 22, 54, 46)
	pb.pressed.connect(func(): pause_pressed.emit())
	pb.mouse_filter = Control.MOUSE_FILTER_STOP

	mult_lbl = _lbl("x1", 20, C_CORAL, HORIZONTAL_ALIGNMENT_CENTER)
	g.add_child(mult_lbl)
	_place(mult_lbl, 0, 82, W, 28)

	power_lbl = _lbl("", 20, Color("7dd3fc"), HORIZONTAL_ALIGNMENT_CENTER)
	g.add_child(power_lbl)
	_place(power_lbl, 0, 112, W, 28)

	var mp := Panel.new()
	mp.add_theme_stylebox_override("panel", _sb(Color(0.03, 0.1, 0.18, 0.5), 14))
	g.add_child(mp)
	_place(mp, 14, 150, 300, 92)
	for i in 3:
		var l := _lbl("", 15, Color.WHITE)
		g.add_child(l)
		_place(l, 26, 156 + i * 28, 280, 26)
		mission_lbls.append(l)

	banner_lbl = _lbl("", 38, C_SUN, HORIZONTAL_ALIGNMENT_CENTER)
	banner_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	g.add_child(banner_lbl)
	_place(banner_lbl, 20, 290, W - 40, 130)
	banner_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_lbl.modulate.a = 0.0

	toast_lbl = _lbl("", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	toast_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	g.add_child(toast_lbl)
	_place(toast_lbl, 30, 430, W - 60, 70)
	toast_lbl.visible = false

	hint_lbl = _lbl("Desliza  ←  →  para moverte  ·  ↑ saltar  ·  ↓ deslizar", 18, Color(1, 1, 1, 0.9), HORIZONTAL_ALIGNMENT_CENTER)
	g.add_child(hint_lbl)
	_place(hint_lbl, 0, H - 70, W, 30)


func update_game(coins: int, score: int, mult: int, dist: int, timers: Dictionary, missions: Array) -> void:
	coin_lbl.text = "● %d" % coins
	score_lbl.text = str(score)
	mult_lbl.text = "x%d  ·  %d m" % [mult, dist]
	var parts: Array = []
	var names := {"magnet": "IMÁN", "shield": "ESCUDO", "x2": "x2", "fly": "VUELO"}
	for k in names:
		if float(timers[k]) > 0.0:
			parts.append("%s %ds" % [names[k], int(ceil(float(timers[k])))])
	power_lbl.text = "   ".join(parts)
	for i in 3:
		var m: Dictionary = missions[i]
		var mark := "✔ " if m.done else "• "
		mission_lbls[i].text = "%s%s  %d/%d" % [mark, m.text, m.value, m.target]
		mission_lbls[i].add_theme_color_override("font_color", C_GREEN if m.done else Color.WHITE)


func banner(text: String, color: Color = Color("ffc233")) -> void:
	banner_lbl.text = text
	banner_lbl.add_theme_color_override("font_color", color)
	if banner_tween:
		banner_tween.kill()
	banner_lbl.modulate.a = 0.0
	banner_tween = create_tween()
	banner_tween.tween_property(banner_lbl, "modulate:a", 1.0, 0.25)
	banner_tween.tween_interval(2.2)
	banner_tween.tween_property(banner_lbl, "modulate:a", 0.0, 0.6)


func toast(text: String) -> void:
	toast_q.append(text)


func _process(delta: float) -> void:
	if toast_t > 0.0:
		toast_t -= delta
		if toast_t <= 0.0:
			toast_lbl.visible = false
	if toast_t <= 0.0 and toast_q.size() > 0:
		toast_lbl.text = toast_q.pop_front()
		toast_lbl.visible = true
		toast_t = 2.3
	if hint_lbl and hint_lbl.visible and hint_lbl.modulate.a > 0.0 and pages["game"].visible:
		hint_lbl.modulate.a = maxf(0.0, hint_lbl.modulate.a - delta * 0.18)


# ---------- Menú ----------
func _build_menu() -> void:
	var m := _page("menu")
	var t1 := _lbl("FUGA EN EL", 40, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	m.add_child(t1)
	_place(t1, 0, 56, W, 54)
	var t2 := _lbl("TRÓPICO", 82, C_SUN, HORIZONTAL_ALIGNMENT_CENTER)
	t2.add_theme_color_override("font_outline_color", Color("c2410c"))
	t2.add_theme_constant_override("outline_size", 14)
	m.add_child(t2)
	_place(t2, 0, 104, W, 104)

	menu_coins = _lbl("", 26, C_SUN, HORIZONTAL_ALIGNMENT_LEFT)
	m.add_child(menu_coins)
	_place(menu_coins, 24, 226, 250, 36)
	menu_best = _lbl("", 22, C_MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	m.add_child(menu_best)
	_place(menu_best, W - 274, 230, 250, 36)

	music_btn = _btn("", Color("475569"), 16, 130, 40)
	m.add_child(music_btn)
	_place(music_btn, 24, 270, 130, 40)
	music_btn.pressed.connect(func():
		GameState.data.music = not GameState.data.music
		GameState.save_game()
		Sfx.refresh_settings()
		_refresh_toggles())
	sfx_btn = _btn("", Color("475569"), 16, 130, 40)
	m.add_child(sfx_btn)
	_place(sfx_btn, 162, 270, 130, 40)
	sfx_btn.pressed.connect(func():
		GameState.data.sfx = not GameState.data.sfx
		GameState.save_game()
		_refresh_toggles())

	update_box = Control.new()
	update_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(update_box)
	_place(update_box, 24, 322, W - 48, 64)
	var ub := Panel.new()
	ub.add_theme_stylebox_override("panel", _sb(Color(0.98, 0.45, 0.2, 0.92), 18, Color(1, 1, 1, 0.5), 2))
	update_box.add_child(ub)
	_place(ub, 0, 0, W - 48, 64)
	update_lbl = _lbl("", 18, Color.WHITE)
	update_box.add_child(update_lbl)
	_place(update_lbl, 16, 18, 270, 30)
	var upb := _btn("ACTUALIZAR", Color("14b8a6"), 16, 150, 44)
	update_box.add_child(upb)
	_place(upb, W - 48 - 166, 10, 150, 44)
	upb.pressed.connect(func(): update_pressed.emit())
	update_box.visible = false

	var vl := _lbl("v" + String(ProjectSettings.get_setting("application/config/version", "0.0.0")), 14, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_CENTER)
	m.add_child(vl)
	_place(vl, 0, H - 26, W, 20)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(vb)
	_place(vb, 90, H - 370, W - 180, 330)
	var play := _btn("JUGAR", C_TEAL, 36, 360, 84)
	play.pressed.connect(func(): play_pressed.emit())
	vb.add_child(play)
	var b1 := _btn("TIENDA", C_CORAL, 26, 360, 60)
	b1.pressed.connect(func(): open_page("shop"))
	vb.add_child(b1)
	var b2 := _btn("MISIONES", Color("3b82f6"), 26, 360, 60)
	b2.pressed.connect(func(): open_page("missions"))
	vb.add_child(b2)
	menu_ach_btn = _btn("LOGROS", Color("a855f7"), 26, 360, 60)
	menu_ach_btn.pressed.connect(func(): open_page("ach"))
	vb.add_child(menu_ach_btn)


func _refresh_toggles() -> void:
	music_btn.text = "Música: " + ("sí" if GameState.data.music else "no")
	sfx_btn.text = "Sonidos: " + ("sí" if GameState.data.sfx else "no")


func set_update(version: String) -> void:
	update_lbl.text = "Nueva versión %s disponible" % version
	update_box.visible = true


func show_menu() -> void:
	menu_coins.text = "● %d" % int(GameState.data.coins)
	menu_best.text = "Récord %d   ·   x%d" % [int(GameState.data.best), int(GameState.data.multiplier)]
	var n := GameState.ach_ready()
	menu_ach_btn.text = "LOGROS" + ("  (%d nuevos)" % n if n > 0 else "")
	_refresh_toggles()
	_show("menu")


func show_game() -> void:
	hint_lbl.modulate.a = 1.0
	_show("game")


func open_page(id: String) -> void:
	match id:
		"shop":
			shop_tab = "char"
			_shop_sync_idx()
			_refresh_shop()
			look_preview.emit(_preview_look())
		"missions":
			_refresh_missions()
		"ach":
			_refresh_ach()
	_show(id)
	page_opened.emit(id)


func close_page() -> void:
	look_preview.emit(GameState.look())
	show_menu()
	page_opened.emit("menu")


# ---------- Tienda ----------
func _build_shop() -> void:
	var p := _page("shop")
	shop_box = _panel(p, Rect2(14, H - 442, W - 28, 428), C_PANEL)
	shop_coins = _lbl("", 28, C_SUN, HORIZONTAL_ALIGNMENT_RIGHT)
	p.add_child(shop_coins)
	_place(shop_coins, W - 224, 24, 200, 40)


func _shop_sync_idx() -> void:
	shop_idx = 0
	var items: Array = GameState.shop_items(shop_tab)
	for i in items.size():
		if items[i].id == GameState.equipped(shop_tab):
			shop_idx = i


func _preview_look() -> Dictionary:
	var items: Array = GameState.shop_items(shop_tab)
	return GameState.look({shop_tab: String(items[shop_idx].id)})


func _shop_set_tab(t: String) -> void:
	shop_tab = t
	_shop_sync_idx()
	_refresh_shop()
	look_preview.emit(_preview_look())


func _shop_move(d: int) -> void:
	var n: int = GameState.shop_items(shop_tab).size()
	shop_idx = wrapi(shop_idx + d, 0, n)
	_refresh_shop()
	look_preview.emit(_preview_look())


func _refresh_shop(msg: String = "") -> void:
	_clear(shop_box)
	shop_coins.text = "● %d" % int(GameState.data.coins)
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 6)
	for t in GameState.TABS:
		var tb := _btn(String(TAB_NAMES[t]), C_TEAL if t == shop_tab else Color("334155"), 14, 94, 38)
		var tt: String = t
		tb.pressed.connect(func(): _shop_set_tab(tt))
		tabs.add_child(tb)
	shop_box.add_child(tabs)

	var items: Array = GameState.shop_items(shop_tab)
	var it: Dictionary = items[shop_idx]
	var tab := shop_tab
	var id: String = it.id
	shop_box.add_child(_lbl(String(it.name).to_upper(), 32, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	var d := _lbl(String(it.desc), 17, C_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_box.add_child(d)
	var status := ""
	var col := C_MUTED
	if GameState.owns(tab, id):
		status = "Equipado" if GameState.equipped(tab) == id else "Ya es tuyo"
		col = C_GREEN
	else:
		status = "Precio: ● %d" % int(it.cost)
		col = C_SUN
	if msg != "":
		status = msg
		col = C_CORAL
	shop_box.add_child(_lbl(status + "      %d / %d" % [shop_idx + 1, items.size()], 18, col, HORIZONTAL_ALIGNMENT_CENTER))

	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 14)
	var left := _btn("<", Color("475569"), 30, 70, 70)
	left.pressed.connect(func(): _shop_move(-1))
	nav.add_child(left)
	var act: Button
	if GameState.owns(tab, id):
		if GameState.equipped(tab) == id:
			act = _btn("EQUIPADO", Color("475569"), 24, 250, 70)
			act.disabled = true
		else:
			act = _btn("QUITAR" if id == "none" else "EQUIPAR", C_TEAL, 28, 250, 70)
			act.pressed.connect(func():
				GameState.equip(tab, id)
				look_preview.emit(_preview_look())
				_refresh_shop())
	else:
		act = _btn("COMPRAR  ● %d" % int(it.cost), C_CORAL, 24, 250, 70)
		act.pressed.connect(func():
			var short := int(it.cost) - int(GameState.data.coins)
			if short > 0:
				_refresh_shop("Te faltan %d monedas" % short)
			elif GameState.buy(tab, id):
				Sfx.play("buy")
				look_preview.emit(_preview_look())
				_refresh_shop())
	nav.add_child(act)
	var right := _btn(">", Color("475569"), 30, 70, 70)
	right.pressed.connect(func(): _shop_move(1))
	nav.add_child(right)
	shop_box.add_child(nav)

	var back := _btn("VOLVER", Color("3b82f6"), 24, 200, 56)
	back.pressed.connect(close_page)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(back)
	shop_box.add_child(hb)


# ---------- Misiones ----------
func _build_missions() -> void:
	var p := _page("missions")
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.07, 0.12, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.add_child(dim)
	missions_box = _panel(p, Rect2(24, 40, W - 48, H - 80), C_PANEL)


func _refresh_missions() -> void:
	_clear(missions_box)
	missions_box.add_child(_lbl("MISIONES", 38, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	missions_box.add_child(_lbl("Multiplicador actual: x%d" % int(GameState.data.multiplier), 24, C_CORAL, HORIZONTAL_ALIGNMENT_CENTER))
	missions_box.add_child(_lbl("Misiones de carrera", 22, C_SUN))
	missions_box.add_child(_lbl("Cumple las 3 para subir el multiplicador.", 16, C_MUTED))
	for m in GameState.run_progress({"coins": 0, "jumps": 0, "slides": 0, "dist": 0, "powerups": 0}):
		missions_box.add_child(_row(m.text, 0, m.target, "0/%d" % m.target, m.done))
	missions_box.add_child(_lbl("Misiones diarias", 22, C_SUN))
	for m in GameState.daily_list():
		missions_box.add_child(_row(m.text, m.value, m.target, ("COMPLETA" if m.done else "%d/%d  +%d" % [m.value, m.target, m.reward]), m.done))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	missions_box.add_child(sp)
	var back := _btn("VOLVER", Color("3b82f6"), 24, 200, 56)
	back.pressed.connect(close_page)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(back)
	missions_box.add_child(hb)


# ---------- Logros ----------
func _build_ach() -> void:
	var p := _page("ach")
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.07, 0.12, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.add_child(dim)
	ach_box = _panel(p, Rect2(24, 40, W - 48, H - 80), C_PANEL)


func _refresh_ach() -> void:
	_clear(ach_box)
	ach_box.add_child(_lbl("LOGROS", 38, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	var ready := GameState.ach_ready()
	ach_box.add_child(_lbl("Tus monedas: ● %d" % int(GameState.data.coins), 20, C_SUN, HORIZONTAL_ALIGNMENT_CENTER))
	if ready > 0:
		var all := _btn("RECLAMAR TODO  (%d)" % ready, C_SUN.darkened(0.25), 22, 320, 54)
		all.pressed.connect(func():
			var total := GameState.claim_all()
			Sfx.play("win")
			toast("¡+%d monedas!" % total)
			_refresh_ach())
		var hb0 := HBoxContainer.new()
		hb0.alignment = BoxContainer.ALIGNMENT_CENTER
		hb0.add_child(all)
		ach_box.add_child(hb0)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	sc.add_child(v)
	for a in GameState.ACHIEVEMENTS:
		var done: bool = GameState.data.ach_done.has(a.id)
		var claimed: bool = GameState.data.ach_claimed.has(a.id)
		var val := mini(GameState.get_stat(a.stat), int(a.target))
		var right := "RECLAMADO" if claimed else ("+%d" % int(a.reward))
		v.add_child(_row("%s — %s" % [a.name, a.desc], val, int(a.target), right, claimed))
		if done and not claimed:
			var aid: String = a.id
			var cb := _btn("Reclamar  +%d monedas" % int(a.reward), C_SUN.darkened(0.25), 18, 260, 42)
			cb.pressed.connect(func():
				GameState.claim_ach(aid)
				Sfx.play("win")
				_refresh_ach())
			v.add_child(cb)
	ach_box.add_child(sc)
	var back := _btn("VOLVER", Color("3b82f6"), 24, 200, 56)
	back.pressed.connect(close_page)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(back)
	ach_box.add_child(hb)


# ---------- Fin de carrera ----------
func _build_over() -> void:
	var p := _page("over")
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.05, 0.1, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.add_child(dim)
	over_box = _panel(p, Rect2(30, 120, W - 60, 720), C_PANEL)


func show_over(run: Dictionary, msgs: Array, new_best: bool) -> void:
	_clear(over_box)
	over_box.add_child(_lbl("¡FIN DE LA CARRERA!", 36, C_CORAL, HORIZONTAL_ALIGNMENT_CENTER))
	over_box.add_child(_lbl("%d" % int(run.score), 70, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	over_box.add_child(_lbl("PUNTOS" + ("   ·   ¡NUEVO RÉCORD!" if new_best else ""), 20, C_SUN, HORIZONTAL_ALIGNMENT_CENTER))
	over_box.add_child(_lbl("● %d monedas    ·    %d m" % [int(run.coins), int(run.dist)], 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	over_box.add_child(_lbl("Total: ● %d    ·    Récord: %d" % [int(GameState.data.coins), int(GameState.data.best)], 18, C_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	sc.add_child(v)
	for m in msgs:
		var l := _lbl(String(m), 18, C_GREEN)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(430, 0)
		v.add_child(l)
	over_box.add_child(sc)
	var again := _btn("JUGAR DE NUEVO", C_TEAL, 28, 340, 70)
	again.pressed.connect(func(): retry_pressed.emit())
	var menu := _btn("MENÚ", Color("3b82f6"), 24, 340, 58)
	menu.pressed.connect(func(): menu_pressed.emit())
	for b in [again, menu]:
		var hb := HBoxContainer.new()
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		hb.add_child(b)
		over_box.add_child(hb)
	_show("over")


# ---------- Pausa ----------
func _build_pause() -> void:
	var p := _page("pause")
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.05, 0.1, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.add_child(dim)
	var box := _panel(p, Rect2(70, 300, W - 140, 340), C_PANEL)
	box.add_child(_lbl("PAUSA", 50, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	var r := _btn("CONTINUAR", C_TEAL, 28, 300, 70)
	r.pressed.connect(func(): resume_pressed.emit())
	var m := _btn("SALIR AL MENÚ", C_CORAL, 24, 300, 62)
	m.pressed.connect(func(): menu_pressed.emit())
	for b in [r, m]:
		var hb := HBoxContainer.new()
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		hb.add_child(b)
		box.add_child(hb)


func show_pause() -> void:
	_show("pause")
