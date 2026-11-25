extends Node
## Progreso guardado: monedas, tienda (personajes, disfraces, accesorios), misiones y logros.

const SAVE_PATH := "user://fuga_en_el_tropico.json"
const TABS := ["char", "costume", "head", "face", "back"]

const CHARACTERS := [
	{"id": "mateo", "name": "Mateo", "cost": 0, "desc": "El corredor de la playa.", "shirt": "ff6b35", "pants": "2b4c7e", "skin": "c68642", "hair": "2b1b0e", "style": "short"},
	{"id": "lola", "name": "Lola", "cost": 300, "desc": "Rápida, alegre y con melena larga.", "shirt": "ff4d8d", "pants": "fff3b0", "skin": "8d5524", "hair": "1a1a1a", "style": "long"},
	{"id": "tito", "name": "Tito", "cost": 500, "desc": "Pescador de buen humor.", "shirt": "2ec4b6", "pants": "5c4033", "skin": "e0ac69", "hair": "6b6b6b", "style": "short"},
	{"id": "yara", "name": "Yara", "cost": 800, "desc": "Guerrera de la selva.", "shirt": "7b2cbf", "pants": "ffb703", "skin": "a9743b", "hair": "0d0d0d", "style": "bun"},
	{"id": "santi", "name": "Santi", "cost": 1000, "desc": "Rey del afro y del ritmo.", "shirt": "3a86ff", "pants": "f8f9fa", "skin": "6f4518", "hair": "141414", "style": "afro"},
	{"id": "luna", "name": "Luna", "cost": 1500, "desc": "Corre bajo la luz de la luna.", "shirt": "9d4edd", "pants": "240046", "skin": "f1c27d", "hair": "7b2cbf", "style": "long"},
]

const COSTUMES := [
	{"id": "none", "name": "Ropa normal", "cost": 0, "desc": "El look de siempre.", "shirt": "", "pants": "", "extra": ""},
	{"id": "pirata", "name": "Pirata", "cost": 400, "desc": "Camiseta a rayas y a navegar.", "shirt": "e8e8e8", "pants": "1f2937", "extra": "stripes"},
	{"id": "surfista", "name": "Surfista", "cost": 350, "desc": "Listo para la ola perfecta.", "shirt": "00b4d8", "pants": "ffb703", "extra": ""},
	{"id": "explorador", "name": "Explorador", "cost": 450, "desc": "Chaleco para la selva.", "shirt": "d9c9a3", "pants": "6b705c", "extra": "vest"},
	{"id": "carnaval", "name": "Carnaval", "cost": 700, "desc": "Colores y fiesta.", "shirt": "ff006e", "pants": "8338ec", "extra": "sash"},
	{"id": "futbolista", "name": "Futbolista", "cost": 500, "desc": "Camiseta número 10.", "shirt": "ffd60a", "pants": "1d4ed8", "extra": "number"},
	{"id": "gala", "name": "De gala", "cost": 900, "desc": "Elegante hasta corriendo.", "shirt": "111827", "pants": "111827", "extra": "bowtie"},
]

const ACCESSORIES := {
	"head": [
		{"id": "none", "name": "Sin gorro", "cost": 0, "desc": "Cabeza libre."},
		{"id": "flower", "name": "Flor", "cost": 120, "desc": "Una flor tropical."},
		{"id": "cap", "name": "Gorra", "cost": 180, "desc": "Gorra deportiva."},
		{"id": "feather", "name": "Plumas", "cost": 200, "desc": "Diadema con plumas."},
		{"id": "pirate", "name": "Sombrero pirata", "cost": 250, "desc": "Con calavera incluida."},
		{"id": "straw", "name": "Sombrero de paja", "cost": 150, "desc": "Fresco y clásico."},
		{"id": "sombrero", "name": "Sombrero charro", "cost": 300, "desc": "Grande y con estilo."},
		{"id": "crown", "name": "Corona", "cost": 800, "desc": "Para el rey de la carrera."},
	],
	"face": [
		{"id": "none", "name": "Sin accesorio", "cost": 0, "desc": "Cara limpia."},
		{"id": "moustache", "name": "Bigote", "cost": 120, "desc": "Bigote clásico."},
		{"id": "sunglasses", "name": "Gafas de sol", "cost": 150, "desc": "Para el solazo."},
		{"id": "eyepatch", "name": "Parche", "cost": 200, "desc": "Aire de capitán."},
		{"id": "mask", "name": "Antifaz", "cost": 250, "desc": "Misterio y carnaval."},
	],
	"back": [
		{"id": "none", "name": "Sin espalda", "cost": 0, "desc": "Ligero como el viento."},
		{"id": "backpack", "name": "Mochila", "cost": 150, "desc": "Para cargar de todo."},
		{"id": "surfboard", "name": "Tabla de surf", "cost": 300, "desc": "Siempre contigo."},
		{"id": "cape", "name": "Capa", "cost": 450, "desc": "Ondea al correr."},
		{"id": "wings", "name": "Alas", "cost": 600, "desc": "Alas de colores."},
	],
}

const RUN_POOL := {
	"coins": {"text": "Recoge %d monedas", "base": 25},
	"jumps": {"text": "Salta %d veces", "base": 8},
	"slides": {"text": "Deslízate %d veces", "base": 6},
	"dist": {"text": "Recorre %d m", "base": 400},
	"powerups": {"text": "Recoge %d power-ups", "base": 1},
}

const DAILY_POOL := [
	{"stat": "coins", "target": 150, "reward": 60, "text": "Recoge %d monedas hoy"},
	{"stat": "dist", "target": 3000, "reward": 70, "text": "Recorre %d m hoy"},
	{"stat": "jumps", "target": 40, "reward": 50, "text": "Salta %d veces hoy"},
	{"stat": "slides", "target": 30, "reward": 50, "text": "Deslízate %d veces hoy"},
	{"stat": "runs", "target": 3, "reward": 40, "text": "Juega %d carreras hoy"},
	{"stat": "zone", "target": 2, "reward": 80, "text": "Llega a la zona %d en una carrera"},
	{"stat": "powerups", "target": 5, "reward": 60, "text": "Recoge %d power-ups hoy"},
]

const ACHIEVEMENTS := [
	{"id": "a1", "name": "Primeros pasos", "desc": "Recorre 1.000 m en total", "stat": "total_dist", "target": 1000, "reward": 50},
	{"id": "a2", "name": "Trotamundos", "desc": "Recorre 10.000 m en total", "stat": "total_dist", "target": 10000, "reward": 200},
	{"id": "a3", "name": "Maratonista", "desc": "Recorre 50.000 m en total", "stat": "total_dist", "target": 50000, "reward": 600},
	{"id": "a4", "name": "Cazador de monedas", "desc": "Recoge 500 monedas en total", "stat": "total_coins", "target": 500, "reward": 100},
	{"id": "a5", "name": "Coleccionista", "desc": "Recoge 3.000 monedas en total", "stat": "total_coins", "target": 3000, "reward": 300},
	{"id": "a6", "name": "Millonario", "desc": "Recoge 10.000 monedas en total", "stat": "total_coins", "target": 10000, "reward": 800},
	{"id": "a7", "name": "Saltarín", "desc": "Salta 200 veces", "stat": "jumps", "target": 200, "reward": 100},
	{"id": "a8", "name": "Resorte", "desc": "Salta 1.500 veces", "stat": "jumps", "target": 1500, "reward": 350},
	{"id": "a9", "name": "Deslizador", "desc": "Deslízate 150 veces", "stat": "slides", "target": 150, "reward": 100},
	{"id": "a10", "name": "Explorador", "desc": "Llega a la zona 2", "stat": "best_zone2", "target": 2, "reward": 120},
	{"id": "a11", "name": "Aventurero", "desc": "Llega a la zona 3", "stat": "best_zone2", "target": 3, "reward": 250},
	{"id": "a12", "name": "Maestro del trópico", "desc": "Llega a la zona 5", "stat": "best_zone2", "target": 5, "reward": 500},
	{"id": "a13", "name": "Intocable", "desc": "Corre 600 m sin tropezar", "stat": "max_clean", "target": 600, "reward": 150},
	{"id": "a14", "name": "Imparable", "desc": "Corre 1.500 m sin tropezar", "stat": "max_clean", "target": 1500, "reward": 400},
	{"id": "a15", "name": "Buen comienzo", "desc": "Consigue 1.000 puntos", "stat": "best", "target": 1000, "reward": 100},
	{"id": "a16", "name": "Campeón", "desc": "Consigue 10.000 puntos", "stat": "best", "target": 10000, "reward": 500},
	{"id": "a17", "name": "Poderoso", "desc": "Recoge 25 power-ups", "stat": "total_powerups", "target": 25, "reward": 200},
	{"id": "a18", "name": "Amigo de la moda", "desc": "Compra 3 artículos", "stat": "items", "target": 3, "reward": 150},
	{"id": "a19", "name": "Fashionista", "desc": "Compra 10 artículos", "stat": "items", "target": 10, "reward": 500},
	{"id": "a20", "name": "Veterano", "desc": "Juega 25 carreras", "stat": "runs", "target": 25, "reward": 200},
]

var data: Dictionary = {}


func _ready() -> void:
	load_game()


func default_data() -> Dictionary:
	return {
		"coins": 0, "best": 0, "total_dist": 0, "total_coins": 0, "total_powerups": 0, "jumps": 0, "slides": 0, "runs": 0,
		"best_zone": 0, "max_clean": 0,
		"owned": ["char:mateo"],
		"equip": {"char": "mateo", "costume": "none", "head": "none", "face": "none", "back": "none"},
		"multiplier": 1, "rm_level": 0, "rm": [], "daily": {}, "ach_done": [], "ach_claimed": [],
		"music": true, "sfx": true,
	}


func load_game() -> void:
	data = default_data()
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				for k in parsed:
					data[k] = parsed[k]
	# compatibilidad con guardados antiguos
	if not (data.equip is Dictionary):
		data.equip = default_data().equip
	for k in ["char", "costume", "head", "face", "back"]:
		if not data.equip.has(k):
			data.equip[k] = "mateo" if k == "char" else "none"
	if not data.owned.has("char:mateo"):
		data.owned.append("char:mateo")
	_ensure_run_set()
	_ensure_daily()


func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


# ---------- Tienda ----------
func shop_items(tab: String) -> Array:
	match tab:
		"char": return CHARACTERS
		"costume": return COSTUMES
	return ACCESSORIES[tab]


func item_def(tab: String, id: String) -> Dictionary:
	for it in shop_items(tab):
		if it.id == id:
			return it
	return shop_items(tab)[0]


func owns(tab: String, id: String) -> bool:
	return id == "none" or data.owned.has("%s:%s" % [tab, id])


func equipped(tab: String) -> String:
	return String(data.equip[tab])


func buy(tab: String, id: String) -> bool:
	if owns(tab, id):
		return false
	var c := int(item_def(tab, id).cost)
	if int(data.coins) < c:
		return false
	data.coins = int(data.coins) - c
	data.owned.append("%s:%s" % [tab, id])
	data.equip[tab] = id
	check_achievements()
	save_game()
	return true


func equip(tab: String, id: String) -> void:
	if owns(tab, id):
		data.equip[tab] = id
		save_game()


func look(preview: Dictionary = {}) -> Dictionary:
	var l: Dictionary = (data.equip as Dictionary).duplicate()
	for k in preview:
		l[k] = preview[k]
	return l


func items_owned() -> int:
	var n := 0
	for o in data.owned:
		if not String(o).begins_with("char:"):
			n += 1
	return n


func chars_owned() -> int:
	return data.owned.size() - items_owned()


# ---------- Misiones de carrera ----------
func _ensure_run_set() -> void:
	if data.rm.size() == 3:
		return
	var keys: Array = RUN_POOL.keys()
	keys.shuffle()
	var lvl := int(data.rm_level)
	data.rm = []
	for i in 3:
		var k: String = keys[i]
		var base: int = RUN_POOL[k].base
		var target := int(round(base * (1.0 + lvl * 0.5)))
		if k == "powerups":
			target = 1 + lvl / 2
		data.rm.append({"type": k, "target": target, "done": false})


func mission_text(m: Dictionary) -> String:
	return String(RUN_POOL[m.type].text) % int(m.target)


func _run_value(type: String, r: Dictionary) -> int:
	match type:
		"coins": return int(r.coins)
		"jumps": return int(r.jumps)
		"slides": return int(r.slides)
		"dist": return int(r.dist)
		"powerups": return int(r.powerups)
	return 0


func run_progress(r: Dictionary) -> Array:
	var out: Array = []
	for m in data.rm:
		out.append({
			"text": mission_text(m),
			"value": mini(_run_value(m.type, r), int(m.target)),
			"target": int(m.target),
			"done": bool(m.done),
		})
	return out


func check_run_missions(r: Dictionary) -> Array:
	var msgs: Array = []
	var all_done := true
	for m in data.rm:
		if not m.done and _run_value(m.type, r) >= int(m.target):
			m.done = true
			msgs.append("¡Misión cumplida! " + mission_text(m))
		if not m.done:
			all_done = false
	if all_done:
		data.multiplier = mini(int(data.multiplier) + 1, 30)
		data.rm_level = int(data.rm_level) + 1
		data.rm = []
		_ensure_run_set()
		msgs.append("¡Multiplicador x%d!" % int(data.multiplier))
	if msgs.size() > 0:
		save_game()
	return msgs


# ---------- Misiones diarias ----------
func _ensure_daily() -> void:
	var today := Time.get_date_string_from_system()
	var d: Dictionary = data.daily
	if d.get("date", "") == today and d.get("ids", []).size() == 3:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(today)
	var ids: Array = range(DAILY_POOL.size())
	for i in range(ids.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = ids[i]
		ids[i] = ids[j]
		ids[j] = t
	data.daily = {"date": today, "ids": ids.slice(0, 3), "progress": [0, 0, 0], "done": [false, false, false]}
	save_game()


func daily_list() -> Array:
	var out: Array = []
	var d: Dictionary = data.daily
	for i in 3:
		var def: Dictionary = DAILY_POOL[int(d.ids[i])]
		out.append({
			"text": String(def.text) % int(def.target),
			"value": mini(int(d.progress[i]), int(def.target)),
			"target": int(def.target),
			"reward": int(def.reward),
			"done": bool(d.done[i]),
		})
	return out


# ---------- Fin de carrera ----------
func finish_run(r: Dictionary) -> Array:
	var msgs: Array = []
	data.runs = int(data.runs) + 1
	data.total_dist = int(data.total_dist) + int(r.dist)
	data.total_coins = int(data.total_coins) + int(r.coins)
	data.total_powerups = int(data.total_powerups) + int(r.powerups)
	data.jumps = int(data.jumps) + int(r.jumps)
	data.slides = int(data.slides) + int(r.slides)
	data.coins = int(data.coins) + int(r.coins)
	data.best = maxi(int(data.best), int(r.score))
	data.best_zone = maxi(int(data.best_zone), int(r.zone))
	data.max_clean = maxi(int(data.max_clean), int(r.clean_best))

	_ensure_daily()
	var d: Dictionary = data.daily
	for i in 3:
		if d.done[i]:
			continue
		var def: Dictionary = DAILY_POOL[int(d.ids[i])]
		match def.stat:
			"coins": d.progress[i] = int(d.progress[i]) + int(r.coins)
			"dist": d.progress[i] = int(d.progress[i]) + int(r.dist)
			"jumps": d.progress[i] = int(d.progress[i]) + int(r.jumps)
			"slides": d.progress[i] = int(d.progress[i]) + int(r.slides)
			"runs": d.progress[i] = int(d.progress[i]) + 1
			"powerups": d.progress[i] = int(d.progress[i]) + int(r.powerups)
			"zone": d.progress[i] = maxi(int(d.progress[i]), int(r.zone) + 1)
		if int(d.progress[i]) >= int(def.target):
			d.done[i] = true
			data.coins = int(data.coins) + int(def.reward)
			msgs.append("Misión diaria: %s (+%d monedas)" % [String(def.text) % int(def.target), int(def.reward)])

	msgs.append_array(check_achievements())
	save_game()
	return msgs


# ---------- Logros ----------
func get_stat(stat: String) -> int:
	match stat:
		"total_dist": return int(data.total_dist)
		"total_coins": return int(data.total_coins)
		"total_powerups": return int(data.total_powerups)
		"jumps": return int(data.jumps)
		"slides": return int(data.slides)
		"runs": return int(data.runs)
		"best": return int(data.best)
		"best_zone2": return int(data.best_zone) + 1
		"max_clean": return int(data.max_clean)
		"items": return items_owned()
	return 0


func check_achievements() -> Array:
	var msgs: Array = []
	for a in ACHIEVEMENTS:
		if data.ach_done.has(a.id):
			continue
		if get_stat(a.stat) >= int(a.target):
			data.ach_done.append(a.id)
			msgs.append("Logro: %s. ¡Reclámalo en Logros!" % a.name)
	return msgs


func ach_ready() -> int:
	var n := 0
	for a in ACHIEVEMENTS:
		if data.ach_done.has(a.id) and not data.ach_claimed.has(a.id):
			n += 1
	return n


func claim_ach(id: String) -> int:
	for a in ACHIEVEMENTS:
		if a.id == id and data.ach_done.has(id) and not data.ach_claimed.has(id):
			data.ach_claimed.append(id)
			data.coins = int(data.coins) + int(a.reward)
			save_game()
			return int(a.reward)
	return 0


func claim_all() -> int:
	var total := 0
	for a in ACHIEVEMENTS:
		total += claim_ach(a.id)
	return total
