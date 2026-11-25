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
	{"id": "capitan", "name": "Capitán", "cost": 600, "desc": "Botones dorados y rumbo al mar.", "shirt": "1e3a8a", "pants": "f8fafc", "extra": "buttons"},
	{"id": "jaguar", "name": "Jaguar", "cost": 650, "desc": "Manchas de la selva.", "shirt": "f59e0b", "pants": "78350f", "extra": "spots"},
	{"id": "maya", "name": "Guerrero maya", "cost": 750, "desc": "Cinturón de jade y fuerza antigua.", "shirt": "0f766e", "pants": "b45309", "extra": "belt"},
	{"id": "salvavidas", "name": "Salvavidas", "cost": 550, "desc": "Listo para rescatar en la playa.", "shirt": "e63946", "pants": "f8fafc", "extra": "cross"},
	{"id": "chef", "name": "Chef", "cost": 500, "desc": "Cocina tropical a toda velocidad.", "shirt": "f8fafc", "pants": "374151", "extra": "collar"},
	{"id": "astronauta", "name": "Astronauta", "cost": 1100, "desc": "Corre como en la luna.", "shirt": "e5e7eb", "pants": "cbd5e1", "extra": "suit"},
	{"id": "poncho", "name": "Poncho", "cost": 600, "desc": "Colores de los Andes.", "shirt": "dc2626", "pants": "f1f5f9", "extra": "poncho"},
	{"id": "heroe", "name": "Superhéroe", "cost": 1000, "desc": "Emblema en el pecho.", "shirt": "2563eb", "pants": "dc2626", "extra": "emblem"},
	{"id": "neon", "name": "Corredor neón", "cost": 700, "desc": "Líneas de luz para la ciudad nocturna.", "shirt": "1e1b4b", "pants": "0f172a", "extra": "neon"},
	{"id": "hacker", "name": "Ciberladrón", "cost": 800, "desc": "Capucha y visor verde.", "shirt": "111827", "pants": "1f2937", "extra": "hood"},
	{"id": "caballero", "name": "Caballero estelar", "cost": 1200, "desc": "Túnica de las estrellas.", "shirt": "d6c7a1", "pants": "4b3a26", "extra": "robe"},
	{"id": "piloto", "name": "Piloto galáctico", "cost": 900, "desc": "Traje naranja de la flota.", "shirt": "f97316", "pants": "f8fafc", "extra": "belt"},
	{"id": "titan", "name": "Titán de acero", "cost": 1300, "desc": "Armadura roja y dorada.", "shirt": "b91c1c", "pants": "fbbf24", "extra": "armor"},
	{"id": "velocista", "name": "Velocista", "cost": 1000, "desc": "Rayo en el pecho.", "shirt": "dc2626", "pants": "991b1b", "extra": "bolt"},
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
		{"id": "chef", "name": "Gorro de chef", "cost": 200, "desc": "Alta cocina."},
		{"id": "tophat", "name": "Sombrero de copa", "cost": 350, "desc": "Elegancia total."},
		{"id": "headband", "name": "Cinta", "cost": 100, "desc": "Estilo deportivo."},
		{"id": "helmet", "name": "Casco", "cost": 400, "desc": "Protección de explorador."},
		{"id": "phones", "name": "Audífonos", "cost": 250, "desc": "Música al correr."},
		{"id": "visor", "name": "Visor neón", "cost": 300, "desc": "Brilla en la oscuridad."},
		{"id": "mask_h", "name": "Máscara de héroe", "cost": 350, "desc": "Identidad secreta."},
		{"id": "spacehelm", "name": "Casco espacial", "cost": 600, "desc": "Cúpula de cristal."},
	],
	"face": [
		{"id": "none", "name": "Sin accesorio", "cost": 0, "desc": "Cara limpia."},
		{"id": "moustache", "name": "Bigote", "cost": 120, "desc": "Bigote clásico."},
		{"id": "sunglasses", "name": "Gafas de sol", "cost": 150, "desc": "Para el solazo."},
		{"id": "eyepatch", "name": "Parche", "cost": 200, "desc": "Aire de capitán."},
		{"id": "mask", "name": "Antifaz", "cost": 250, "desc": "Misterio y carnaval."},
		{"id": "nose", "name": "Nariz de payaso", "cost": 100, "desc": "Para reír."},
		{"id": "beard", "name": "Barba", "cost": 220, "desc": "Barba de lobo de mar."},
		{"id": "heart", "name": "Gafas de corazón", "cost": 180, "desc": "Mira con amor."},
	],
	"back": [
		{"id": "none", "name": "Sin espalda", "cost": 0, "desc": "Ligero como el viento."},
		{"id": "backpack", "name": "Mochila", "cost": 150, "desc": "Para cargar de todo."},
		{"id": "surfboard", "name": "Tabla de surf", "cost": 300, "desc": "Siempre contigo."},
		{"id": "cape", "name": "Capa", "cost": 450, "desc": "Ondea al correr."},
		{"id": "wings", "name": "Alas", "cost": 600, "desc": "Alas de colores."},
		{"id": "guitar", "name": "Guitarra", "cost": 350, "desc": "Ritmo en la espalda."},
		{"id": "parrot", "name": "Loro", "cost": 500, "desc": "Un amigo con plumas."},
		{"id": "jetpack", "name": "Cohete", "cost": 700, "desc": "Con llamitas."},
		{"id": "saber", "name": "Espada láser", "cost": 650, "desc": "Zumbido de luz."},
		{"id": "shield_h", "name": "Escudo heroico", "cost": 550, "desc": "Estrella al frente."},
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
	{"id": "a12", "name": "Maestro del trópico", "desc": "Llega a la zona 6", "stat": "best_zone2", "target": 6, "reward": 500},
	{"id": "a13", "name": "Intocable", "desc": "Corre 600 m sin tropezar", "stat": "max_clean", "target": 600, "reward": 150},
	{"id": "a14", "name": "Imparable", "desc": "Corre 1.500 m sin tropezar", "stat": "max_clean", "target": 1500, "reward": 400},
	{"id": "a15", "name": "Buen comienzo", "desc": "Consigue 1.000 puntos", "stat": "best", "target": 1000, "reward": 100},
	{"id": "a16", "name": "Campeón", "desc": "Consigue 10.000 puntos", "stat": "best", "target": 10000, "reward": 500},
	{"id": "a17", "name": "Poderoso", "desc": "Recoge 25 power-ups", "stat": "total_powerups", "target": 25, "reward": 200},
	{"id": "a18", "name": "Amigo de la moda", "desc": "Compra 3 artículos", "stat": "items", "target": 3, "reward": 150},
	{"id": "a19", "name": "Fashionista", "desc": "Compra 10 artículos", "stat": "items", "target": 10, "reward": 500},
	{"id": "a20", "name": "Veterano", "desc": "Juega 25 carreras", "stat": "runs", "target": 25, "reward": 200},
	{"id": "a21", "name": "Destructor", "desc": "Rompe 30 obstáculos con armas", "stat": "destroyed", "target": 30, "reward": 120},
	{"id": "a22", "name": "Demoledor", "desc": "Rompe 250 obstáculos", "stat": "destroyed", "target": 250, "reward": 450},
	{"id": "a23", "name": "Aventurero de niveles", "desc": "Completa 5 niveles", "stat": "levels_done", "target": 5, "reward": 200},
	{"id": "a24", "name": "Conquistador", "desc": "Completa 20 niveles", "stat": "levels_done", "target": 20, "reward": 700},
	{"id": "a25", "name": "Estrellado", "desc": "Consigue 30 estrellas", "stat": "stars", "target": 30, "reward": 500},
	{"id": "a26", "name": "Viajero de mundos", "desc": "Llega a la zona 4", "stat": "best_zone2", "target": 4, "reward": 300},
	{"id": "a27", "name": "Luchador", "desc": "Derrota 25 enemigos", "stat": "enemies", "target": 25, "reward": 150},
	{"id": "a28", "name": "Cazador de villanos", "desc": "Derrota 150 enemigos", "stat": "enemies", "target": 150, "reward": 500},
	{"id": "a29", "name": "Veterano de guerra", "desc": "Llega al nivel de jugador 5", "stat": "plevel", "target": 5, "reward": 250},
	{"id": "a30", "name": "Leyenda", "desc": "Llega al nivel de jugador 10", "stat": "plevel", "target": 10, "reward": 800},
]

var data: Dictionary = {}


func _ready() -> void:
	load_game()


func default_data() -> Dictionary:
	return {
		"coins": 0, "best": 0, "total_dist": 0, "total_coins": 0, "total_powerups": 0, "jumps": 0, "slides": 0, "runs": 0,
		"best_zone": 0, "max_clean": 0, "destroyed": 0, "enemies": 0, "xp": -1, "boosts": {}, "lives": 5, "life_ts": 0, "levels": {}, "weapon_hint": false,
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
	if not can_buy(tab, id):
		return false
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
	data.destroyed = int(data.destroyed) + int(r.get("destroyed", 0))
	data.enemies = int(data.enemies) + int(r.get("enemies", 0))
	var gain := int(float(r.score) * 0.06) + int(r.coins) + int(r.get("enemies", 0)) * 6 + int(float(r.dist) / 20.0)
	r["xp_gain"] = gain
	msgs.append_array(add_xp(gain))

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
		"destroyed": return int(data.destroyed)
		"enemies": return int(data.enemies)
		"plevel": return player_level()
		"levels_done": return levels_done()
		"stars": return total_stars()
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


# ---------- Vidas ----------
const MAX_LIVES := 5
const LIFE_SECONDS := 900
const LIFE_COST := 60


func lives_tick() -> void:
	var l := int(data.lives)
	if l >= MAX_LIVES:
		data.lives = MAX_LIVES
		data.life_ts = 0
		return
	var now := int(Time.get_unix_time_from_system())
	if int(data.life_ts) <= 0 or int(data.life_ts) > now:
		data.life_ts = now
		return
	var gained := (now - int(data.life_ts)) / LIFE_SECONDS
	if gained > 0:
		l = mini(MAX_LIVES, l + gained)
		data.lives = l
		data.life_ts = 0 if l >= MAX_LIVES else int(data.life_ts) + gained * LIFE_SECONDS
		save_game()


func lives() -> int:
	lives_tick()
	return int(data.lives)


func life_seconds_left() -> int:
	lives_tick()
	if int(data.lives) >= MAX_LIVES:
		return 0
	return maxi(0, LIFE_SECONDS - (int(Time.get_unix_time_from_system()) - int(data.life_ts)))


func use_life() -> bool:
	lives_tick()
	if int(data.lives) <= 0:
		return false
	data.lives = int(data.lives) - 1
	if int(data.life_ts) <= 0:
		data.life_ts = int(Time.get_unix_time_from_system())
	save_game()
	return true


func add_life(n: int = 1) -> void:
	data.lives = mini(MAX_LIVES, int(data.lives) + n)
	if int(data.lives) >= MAX_LIVES:
		data.life_ts = 0
	save_game()


func buy_life() -> bool:
	lives_tick()
	if int(data.lives) >= MAX_LIVES or int(data.coins) < LIFE_COST:
		return false
	data.coins = int(data.coins) - LIFE_COST
	add_life(1)
	return true


# ---------- Niveles ----------
const MAX_LEVEL := 30
const WORLD_NAMES := ["Playa Dorada", "Selva Esmeralda", "Ciudad Colonial", "Ciudad Neón", "Galaxia Lejana", "Metrópolis Héroe"]


func level_stars(n: int) -> int:
	return int((data.levels as Dictionary).get(str(n), 0))


func level_unlocked(n: int) -> bool:
	return n <= 1 or level_stars(n - 1) > 0


func levels_done() -> int:
	var c := 0
	for k in data.levels:
		if int(data.levels[k]) > 0:
			c += 1
	return c


func total_stars() -> int:
	var c := 0
	for k in data.levels:
		c += int(data.levels[k])
	return c


func level_def(n: int) -> Dictionary:
	return {
		"n": n,
		"biome": (n - 1) / 5,
		"goal": 350.0 + n * 70.0,
		"speed": minf(11.5 + n * 0.55, 25.0),
		"gap": clampf(18.0 - n * 0.5, 7.5, 18.0),
		"diff": n,
		"coin_goal": 20 + n * 3,
		"reward": 40 + n * 8,
	}


## Devuelve mensajes. stars: 1-3.
func complete_level(n: int, stars: int) -> Array:
	var msgs: Array = []
	var old := level_stars(n)
	var def := level_def(n)
	var gain := int(def.reward)
	if stars > old:
		gain += (stars - old) * 20
		data.levels[str(n)] = stars
	data.coins = int(data.coins) + gain
	msgs.append("¡Nivel %d completado! +%d monedas" % [n, gain])
	msgs.append_array(add_xp(30 + n * 3))
	msgs.append_array(check_achievements())
	save_game()
	return msgs


# ---------- Poderes de traje ----------
const POWERS := {
	"barrage": {"name": "Triple disparo", "desc": "Lanza 3 cocos a la vez, uno por carril."},
	"dash": {"name": "Carrera veloz", "desc": "Invencible y más rápido durante 3 s."},
	"magnet": {"name": "Imán", "desc": "Atrae las monedas durante 9 s."},
	"coins": {"name": "Lluvia de monedas", "desc": "Aparecen monedas en los 3 carriles."},
	"shield": {"name": "Escudo", "desc": "Te protege durante 8 s."},
	"x2": {"name": "Doble", "desc": "Puntos y monedas x2 durante 10 s."},
	"blast": {"name": "Explosión", "desc": "Destruye todo lo que tengas enfrente."},
	"heal": {"name": "Respiro", "desc": "Calma al jaguar y te hace invencible 3 s."},
}

const COSTUME_POWER := {
	"pirata": "barrage", "surfista": "dash", "explorador": "magnet", "carnaval": "coins", "futbolista": "dash",
	"gala": "x2", "capitan": "barrage", "jaguar": "dash", "maya": "shield", "salvavidas": "heal", "chef": "coins",
	"astronauta": "shield", "poncho": "magnet", "heroe": "blast", "neon": "dash", "hacker": "x2",
	"caballero": "blast", "piloto": "barrage", "titan": "blast", "velocista": "dash",
}


func power_of(costume_id: String) -> String:
	return String(COSTUME_POWER.get(costume_id, ""))


# ---------- Experiencia y nivel de jugador ----------
func xp_total_for(level: int) -> int:
	return 50 * level * (level - 1)


func player_level() -> int:
	_ensure_xp()
	var l := 1
	while int(data.xp) >= xp_total_for(l + 1):
		l += 1
	return l


## [xp dentro del nivel, xp necesaria para el siguiente]
func xp_progress() -> Array:
	var l := player_level()
	var base := xp_total_for(l)
	return [int(data.xp) - base, xp_total_for(l + 1) - base]


func _ensure_xp() -> void:
	if int(data.xp) < 0:
		data.xp = int(data.total_dist) / 20 + int(data.total_coins) + int(data.runs) * 20


func add_xp(n: int) -> Array:
	var msgs: Array = []
	var before := player_level()
	data.xp = int(data.xp) + n
	var after := player_level()
	msgs.append("+%d XP" % n)
	for l in range(before + 1, after + 1):
		var bonus := 40 * l
		data.coins = int(data.coins) + bonus
		msgs.append("¡NIVEL %d! +%d monedas" % [l, bonus])
		for tab in TABS:
			for it in shop_items(tab):
				if item_req(tab, String(it.id)) == l and int(it.cost) > 0:
					msgs.append("Desbloqueado: %s" % it.name)
		if l == 2:
			msgs.append("Desbloqueado: arma Bumerán")
		if l == 4:
			msgs.append("Desbloqueado: arma Bomba")
	check_achievements()
	save_game()
	return msgs


func item_req(tab: String, id: String) -> int:
	var c := int(item_def(tab, id).cost)
	if c <= 0:
		return 1
	return clampi(1 + c / 250, 1, 10)


func can_buy(tab: String, id: String) -> bool:
	return player_level() >= item_req(tab, id)


# ---------- Potenciadores de inicio ----------
const BOOSTS := {
	"magnet": {"name": "Imán inicial", "cost": 50, "desc": "Empiezas absorbiendo monedas 12 s."},
	"x2": {"name": "Puntos x2", "cost": 60, "desc": "Empiezas con puntos dobles 15 s."},
	"shield": {"name": "Escudo inicial", "cost": 60, "desc": "Empiezas protegido 15 s."},
	"weapon": {"name": "Arma inicial", "cost": 70, "desc": "Empiezas con 4 bumeranes."},
	"fly": {"name": "Impulso", "cost": 90, "desc": "Empiezas volando 6 s sobre monedas."},
}


func boost_count(id: String) -> int:
	return int((data.boosts as Dictionary).get(id, 0))


func buy_boost(id: String) -> bool:
	var c := int(BOOSTS[id].cost)
	if int(data.coins) < c:
		return false
	data.coins = int(data.coins) - c
	data.boosts[id] = boost_count(id) + 1
	save_game()
	return true


func use_boost(id: String) -> bool:
	if boost_count(id) <= 0:
		return false
	data.boosts[id] = boost_count(id) - 1
	save_game()
	return true
