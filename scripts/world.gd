extends Node3D
## Mundo: suelo por segmentos, escenografía por zona, obstáculos, monedas y power-ups.

const Toon = preload("res://scripts/toon.gd")

signal event_warning(text: String)

const LANE_W := 2.2
const SEG_LEN := 24.0
const SEG_COUNT := 10
const SPAWN_AHEAD := 150.0
const ZONE_LEN := 500.0
const PLAT_H := 1.4
const RAMP_LEN := 4.0

var ZONES: Array = [
	{"name": "Playa Dorada", "sky_top": Color("2f9bff"), "sky_hor": Color("c4f1ff"), "fog": Color("d3f4ff"),
		"track": Color("e3c88f"), "left": Color("33c9d9"), "right": Color("f3d98e"),
		"crate": Color("c98a3a"), "accent": Color("ff6b6b"), "event": "¡LLUVIA DE COCOS!", "ball": Color("6b4423")},
	{"name": "Selva Esmeralda", "sky_top": Color("2a9d7a"), "sky_hor": Color("b9f0c8"), "fog": Color("c4ecd2"),
		"track": Color("8d6b46"), "left": Color("1f7a3d"), "right": Color("2b8f48"),
		"crate": Color("7a5230"), "accent": Color("ffd93d"), "event": "¡ESTAMPIDA DE ROCAS!", "ball": Color("8d99ae")},
	{"name": "Ciudad Colonial", "sky_top": Color("ff7e5f"), "sky_hor": Color("ffd6a5"), "fog": Color("ffe3c7"),
		"track": Color("8c8fa8"), "left": Color("d98c5f"), "right": Color("e0a070"),
		"crate": Color("b5651d"), "accent": Color("4cc9f0"), "event": "¡BARRILES DESBOCADOS!", "ball": Color("a0522d")},
]

var PICKS := {
	"magnet": [Color("3a86ff"), "IMÁN"],
	"shield": [Color("2ec4b6"), "ESCUDO"],
	"x2": [Color("ffbe0b"), "x2"],
	"fly": [Color("ff006e"), "VUELO"],
}

var env: Environment
var sky_mat: ProceduralSkyMaterial
var sun: DirectionalLight3D
var cur: Dictionary = {}
var target_zone := 0
var segs: Array = []
var ents: Array = []
var coins: Array = []
var picks: Array = []
var next_z := -45.0
var event_done: Dictionary = {}
var pending_events: Array = []
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	_build_environment()
	for i in SEG_COUNT:
		var s := _make_segment()
		add_child(s)
		segs.append(s)
	reset()


func zone_name(level: int) -> String:
	return ZONES[level % ZONES.size()].name


func _build_environment() -> void:
	cur = {"sky_top": ZONES[0].sky_top, "sky_hor": ZONES[0].sky_hor, "fog": ZONES[0].fog}
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky_mat = ProceduralSkyMaterial.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.9, 1.0)
	env.ambient_light_energy = 0.75
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = 70.0
	env.fog_depth_end = 170.0
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.05
	add_child(sun)
	_apply_visual()


func _apply_visual() -> void:
	sky_mat.sky_top_color = cur.sky_top
	sky_mat.sky_horizon_color = cur.sky_hor
	sky_mat.ground_horizon_color = cur.sky_hor
	sky_mat.ground_bottom_color = cur.fog
	env.fog_light_color = cur.fog


func set_zone(level: int) -> void:
	target_zone = level % ZONES.size()


func _ease_visual(delta: float) -> void:
	var k := 1.0 - exp(-1.6 * delta)
	var z: Dictionary = ZONES[target_zone]
	for key in cur:
		cur[key] = (cur[key] as Color).lerp(z[key], k)
	_apply_visual()


# ---------- Segmentos de suelo ----------
func _make_segment() -> Node3D:
	var s := Node3D.new()
	var mats: Array = []
	var specs: Array = [
		[Vector3(7.4, 0.6, SEG_LEN), Vector3(0, -0.3, 0)],
		[Vector3(40, 0.6, SEG_LEN), Vector3(-23.7, -0.45, 0)],
		[Vector3(40, 0.6, SEG_LEN), Vector3(23.7, -0.45, 0)],
		[Vector3(0.09, 0.02, SEG_LEN), Vector3(-1.1, 0.01, 0)],
		[Vector3(0.09, 0.02, SEG_LEN), Vector3(1.1, 0.01, 0)],
	]
	for sp in specs:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = sp[0]
		mi.mesh = bm
		mi.position = sp[1]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var m := StandardMaterial3D.new()
		m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		m.roughness = 1.0
		mi.material_override = m
		s.add_child(mi)
		mats.append(m)
	s.set_meta("mats", mats)
	var decor := Node3D.new()
	decor.name = "Decor"
	s.add_child(decor)
	return s


func _style_segment(s: Node3D, biome: int) -> void:
	var z: Dictionary = ZONES[biome]
	var mats: Array = s.get_meta("mats")
	mats[0].albedo_color = z.track
	mats[1].albedo_color = z.left
	mats[2].albedo_color = z.right
	mats[3].albedo_color = (z.track as Color).lightened(0.4)
	mats[4].albedo_color = (z.track as Color).lightened(0.4)
	_fill_decor(s, biome)


func _fill_decor(s: Node3D, biome: int) -> void:
	var d: Node3D = s.get_node("Decor")
	for c in d.get_children():
		c.queue_free()
	for side in [-1.0, 1.0]:
		for i in 3:
			var x: float = side * rng.randf_range(6.0, 15.0)
			var zz := (float(i) + rng.randf()) * (SEG_LEN / 3.0) - SEG_LEN * 0.5
			match biome:
				0: _palm(d, Vector3(x, 0, zz))
				1: _jungle_tree(d, Vector3(x, 0, zz))
				2: _house(d, Vector3(side * rng.randf_range(7.5, 11.0), 0, zz), side)
		match biome:
			0:
				if rng.randf() < 0.5:
					_umbrella(d, Vector3(side * rng.randf_range(4.8, 6.0), 0, rng.randf_range(-10, 10)))
			1:
				_bush(d, Vector3(side * rng.randf_range(4.4, 5.4), 0, rng.randf_range(-10, 10)))
			2:
				_lamp(d, Vector3(side * 4.3, 0, rng.randf_range(-6, 6)))


func _palm(p: Node3D, pos: Vector3) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = rng.randf() * TAU
	p.add_child(n)
	var h := rng.randf_range(3.6, 4.9)
	Toon.part(n, Toon.cyl(0.16, 0.26, h), Color("b07c42"), Vector3(0, h * 0.5, 0), Vector3(0, 0, rng.randf_range(-0.1, 0.1)))
	var top := Node3D.new()
	top.position = Vector3(0, h, 0)
	n.add_child(top)
	Toon.part(top, Toon.sphere(0.2), Color("6b4423"), Vector3(0.12, -0.15, 0), Vector3.ZERO, false)
	Toon.part(top, Toon.sphere(0.2), Color("6b4423"), Vector3(-0.1, -0.15, 0.1), Vector3.ZERO, false)
	for i in 5:
		var pv := Node3D.new()
		pv.rotation.y = i * TAU / 5.0
		top.add_child(pv)
		Toon.part(pv, Toon.box(Vector3(2.0, 0.08, 0.55)), Color("3bb273") if i % 2 == 0 else Color("2fa564"), Vector3(1.0, -0.05, 0), Vector3(0, 0, -0.45), false)


func _jungle_tree(p: Node3D, pos: Vector3) -> void:
	var n := Node3D.new()
	n.position = pos
	p.add_child(n)
	var h := rng.randf_range(4.5, 6.5)
	Toon.part(n, Toon.cyl(0.3, 0.45, h), Color("6b4a2b"), Vector3(0, h * 0.5, 0))
	Toon.part(n, Toon.sphere(1.9), Color("2d6a4f"), Vector3(0, h + 0.6, 0))
	Toon.part(n, Toon.sphere(1.3), Color("40916c"), Vector3(1.1, h + 1.2, 0.4), Vector3.ZERO, false)
	Toon.part(n, Toon.sphere(1.1), Color("52b788"), Vector3(-1.0, h + 0.2, -0.5), Vector3.ZERO, false)


func _bush(p: Node3D, pos: Vector3) -> void:
	Toon.part(p, Toon.sphere(0.8, 1.1), Color("52b788"), pos + Vector3(0, 0.45, 0))
	Toon.part(p, Toon.sphere(0.55, 0.8), Color("74c69d"), pos + Vector3(0.6, 0.3, 0.3), Vector3.ZERO, false)


func _umbrella(p: Node3D, pos: Vector3) -> void:
	var n := Node3D.new()
	n.position = pos
	p.add_child(n)
	Toon.part(n, Toon.cyl(0.05, 0.05, 2.3), Color("f1f1f1"), Vector3(0, 1.15, 0), Vector3.ZERO, false)
	Toon.part(n, Toon.cyl(0.05, 1.3, 0.55), Color("ff6b6b") if rng.randf() < 0.5 else Color("ffd166"), Vector3(0, 2.45, 0))


func _house(p: Node3D, pos: Vector3, side: float) -> void:
	var n := Node3D.new()
	n.position = pos
	p.add_child(n)
	var cols := ["ff6b6b", "ffd166", "06d6a0", "4cc9f0", "f78c6b", "c77dff"]
	var w := rng.randf_range(3.2, 4.4)
	var h := rng.randf_range(3.6, 6.2)
	var wall := Color(cols[rng.randi() % cols.size()])
	Toon.part(n, Toon.box(Vector3(w, h, 4.2)), wall, Vector3(0, h * 0.5, 0))
	Toon.part(n, Toon.box(Vector3(w + 0.5, 0.45, 4.7)), Color("9d4b3a"), Vector3(0, h + 0.22, 0))
	var fx := -side * (w * 0.5 + 0.03)
	for zz in [-1.1, 1.1]:
		Toon.part(n, Toon.box(Vector3(0.1, 0.9, 0.7)), Color("264653"), Vector3(fx, h * 0.62, zz), Vector3.ZERO, false)
	Toon.part(n, Toon.box(Vector3(0.1, 1.6, 0.8)), Color("5c3d2e"), Vector3(fx, 0.8, 0), Vector3.ZERO, false)


func _lamp(p: Node3D, pos: Vector3) -> void:
	Toon.part(p, Toon.cyl(0.07, 0.09, 3.6), Color("2b2d42"), pos + Vector3(0, 1.8, 0))
	Toon.part(p, Toon.sphere(0.25), Color("ffe66d"), pos + Vector3(0, 3.7, 0), Vector3.ZERO, false)


# ---------- Reinicio ----------
func reset() -> void:
	for e in ents:
		e.node.queue_free()
	ents.clear()
	for c in coins:
		c.queue_free()
	coins.clear()
	for p in picks:
		p.node.queue_free()
	picks.clear()
	event_done.clear()
	pending_events.clear()
	next_z = -45.0
	target_zone = 0
	cur = {"sky_top": ZONES[0].sky_top, "sky_hor": ZONES[0].sky_hor, "fog": ZONES[0].fog}
	_apply_visual()
	for i in segs.size():
		segs[i].position = Vector3(0, 0, 36.0 - i * SEG_LEN)
		_style_segment(segs[i], 0)


# ---------- Bucle ----------
func advance(delta: float, speed: float, dist: float, ppos: Vector3, magnet: bool) -> void:
	var move := speed * delta
	_ease_visual(delta)

	for s in segs:
		s.position.z += move
	for s in segs:
		if s.position.z > SEG_LEN * 2.5:
			var far := 0.0
			for o in segs:
				far = minf(far, o.position.z)
			s.position.z = far - SEG_LEN
			_style_segment(s, int((dist - s.position.z) / ZONE_LEN) % ZONES.size())

	for i in range(ents.size() - 1, -1, -1):
		var e: Dictionary = ents[i]
		var n: Node3D = e.node
		n.position.z += move + float(e.extra) * delta
		if e.has("roller"):
			(e.roller as Node3D).rotation.x += (speed + float(e.extra)) * delta / 0.55
		if n.position.z > 14.0:
			n.queue_free()
			ents.remove_at(i)

	var center := ppos + Vector3(0, 0.95, 0)
	for i in range(coins.size() - 1, -1, -1):
		var c: Node3D = coins[i]
		c.position.z += move
		c.rotation.y += 3.2 * delta
		if magnet:
			var d := center - c.position
			if d.length() < 8.0 and d.length() > 0.05:
				c.position += d.normalized() * minf(d.length(), 30.0 * delta)
		if c.position.z > 12.0:
			c.queue_free()
			coins.remove_at(i)

	for i in range(picks.size() - 1, -1, -1):
		var pk: Dictionary = picks[i]
		var n: Node3D = pk.node
		n.position.z += move
		n.rotation.y += 2.0 * delta
		(pk.orb as Node3D).position.y = 0.15 * sin(Time.get_ticks_msec() * 0.005)
		if n.position.z > 12.0:
			n.queue_free()
			picks.remove_at(i)

	for i in range(pending_events.size() - 1, -1, -1):
		if dist >= float(pending_events[i].at):
			event_warning.emit(pending_events[i].text)
			pending_events.remove_at(i)

	next_z += move
	while next_z > -SPAWN_AHEAD:
		var sd := dist - next_z
		var plen := _spawn_pattern(next_z, sd)
		var level := int(sd / ZONE_LEN)
		var gap := clampf(19.0 - level * 2.0 - sd * 0.001, 9.0, 19.0)
		next_z -= plen + gap


# ---------- Consultas ----------
func ground_height(x: float) -> float:
	var h := 0.0
	for e in ents:
		if e.kind != "plat":
			continue
		if absf((int(e.lanes[0]) - 1) * LANE_W - x) > 0.95:
			continue
		var depth: float = e.node.position.z
		if depth < 0.0:
			continue
		if depth <= RAMP_LEN:
			h = maxf(h, PLAT_H * depth / RAMP_LEN)
		elif depth <= RAMP_LEN + float(e.length):
			h = maxf(h, PLAT_H)
	return h


func check_hit(px: float, py: float, head: float) -> Dictionary:
	for e in ents:
		if e.kind == "plat":
			continue
		var z: float = e.node.position.z
		if absf(z) > float(e.half) + 0.35:
			continue
		var in_lane := false
		for l in e.lanes:
			if absf((int(l) - 1) * LANE_W - px) < 0.8:
				in_lane = true
		if not in_lane:
			continue
		if e.kind == "low":
			if py < float(e.top) - 0.05:
				return e
		elif e.kind == "beam":
			if py + head > float(e.bottom) and py < float(e.top):
				return e
	return {}


func remove_entity(e: Dictionary) -> void:
	var i := ents.find(e)
	if i >= 0:
		e.node.queue_free()
		ents.remove_at(i)


func collect(p: Vector3) -> Dictionary:
	var got := 0
	var kinds: Array = []
	var center := p + Vector3(0, 0.95, 0)
	for i in range(coins.size() - 1, -1, -1):
		var c: Node3D = coins[i]
		var d := c.position - center
		if absf(d.x) < 0.95 and absf(d.y) < 1.25 and absf(d.z) < 0.9:
			got += 1
			c.queue_free()
			coins.remove_at(i)
	for i in range(picks.size() - 1, -1, -1):
		var pk: Dictionary = picks[i]
		var d: Vector3 = (pk.node as Node3D).position + Vector3(0, 0.6, 0) - center
		if absf(d.x) < 1.0 and absf(d.y) < 1.4 and absf(d.z) < 1.0:
			kinds.append(pk.kind)
			(pk.node as Node3D).queue_free()
			picks.remove_at(i)
	return {"coins": got, "picks": kinds}


func spawn_sky_coins(length: float) -> void:
	var lane := rng.randi_range(0, 2)
	var count := int(length / 2.2)
	for i in count:
		if i % 8 == 0:
			lane = rng.randi_range(0, 2)
		_add_coin(_x(lane), 4.4, -16.0 - i * 2.2)


# ---------- Constructores de entidades ----------
func _x(lane: int) -> float:
	return (lane - 1) * LANE_W


func _add_ent(node: Node3D, kind: String, lanes: Array, half: float, z: float, extra: float = 0.0, top: float = 0.95, bottom: float = 0.0, length: float = 0.0) -> Dictionary:
	var xs := (float(lanes.min()) + float(lanes.max())) * 0.5
	node.position = Vector3((xs - 1.0) * LANE_W, 0, z)
	add_child(node)
	var e := {"node": node, "kind": kind, "lanes": lanes, "half": half, "extra": extra, "top": top, "bottom": bottom, "length": length}
	ents.append(e)
	return e


func _add_coin(x: float, y: float, z: float) -> void:
	var n := Node3D.new()
	n.position = Vector3(x, y, z)
	Toon.part(n, Toon.cyl(0.36, 0.36, 0.1), Color("ffc400"), Vector3.ZERO, Vector3(PI / 2, 0, 0))
	add_child(n)
	coins.append(n)


func _coin_line(lane: int, z: float, count: int, y: float = 0.95, step: float = 2.0) -> void:
	for i in count:
		_add_coin(_x(lane), y, z - i * step)


func _add_pickup(kind: String, lane: int, z: float) -> void:
	var info: Array = PICKS[kind]
	var n := Node3D.new()
	n.position = Vector3(_x(lane), 1.0, z)
	var orb := Node3D.new()
	n.add_child(orb)
	var c: Color = info[0]
	Toon.part(orb, Toon.cyl(0.62, 0.62, 0.06), c.lightened(0.55), Vector3(0, 0.35, 0), Vector3(PI / 2, 0, 0), false)
	match kind:
		"magnet":
			Toon.part(orb, Toon.box(Vector3(0.15, 0.52, 0.15)), Color("e63946"), Vector3(-0.2, 0.36, 0))
			Toon.part(orb, Toon.box(Vector3(0.15, 0.52, 0.15)), Color("3a86ff"), Vector3(0.2, 0.36, 0))
			Toon.part(orb, Toon.box(Vector3(0.55, 0.15, 0.15)), Color("6b7280"), Vector3(0, 0.1, 0))
			Toon.part(orb, Toon.box(Vector3(0.15, 0.1, 0.16)), Color.WHITE, Vector3(-0.2, 0.64, 0), Vector3.ZERO, false)
			Toon.part(orb, Toon.box(Vector3(0.15, 0.1, 0.16)), Color.WHITE, Vector3(0.2, 0.64, 0), Vector3.ZERO, false)
		"shield":
			Toon.part(orb, Toon.cyl(0.36, 0.2, 0.14), c, Vector3(0, 0.36, 0), Vector3(PI / 2, 0, 0))
			Toon.part(orb, Toon.sphere(0.12), Color.WHITE, Vector3(0, 0.36, -0.1), Vector3.ZERO, false)
		"x2":
			Toon.part(orb, Toon.cyl(0.26, 0.26, 0.08), Color("ffc400"), Vector3(-0.14, 0.36, 0.05), Vector3(PI / 2, 0, 0))
			Toon.part(orb, Toon.cyl(0.26, 0.26, 0.08), Color("ffd84d"), Vector3(0.14, 0.36, -0.05), Vector3(PI / 2, 0, 0))
			Toon.part(orb, Toon.sphere(0.07), Color("e63946"), Vector3(0, 0.7, 0), Vector3.ZERO, false)
		"fly":
			Toon.part(orb, Toon.sphere(0.16), Color("ffd166"), Vector3(0, 0.36, 0))
			Toon.part(orb, Toon.box(Vector3(0.38, 0.12, 0.05)), Color("ff9ecd"), Vector3(-0.3, 0.44, 0), Vector3(0, 0, 0.45))
			Toon.part(orb, Toon.box(Vector3(0.38, 0.12, 0.05)), Color("7dd3fc"), Vector3(0.3, 0.44, 0), Vector3(0, 0, -0.45))
	add_child(n)
	picks.append({"node": n, "kind": kind, "orb": orb})


func _add_low(lanes: Array, z: float, biome: int) -> void:
	var zn: Dictionary = ZONES[biome]
	var n := Node3D.new()
	var width := (float(lanes.max()) - float(lanes.min())) * LANE_W + 1.7
	Toon.part(n, Toon.box(Vector3(width, 0.95, 0.9)), zn.crate, Vector3(0, 0.475, 0))
	Toon.part(n, Toon.box(Vector3(width + 0.02, 0.17, 0.93)), zn.accent, Vector3(0, 0.22, 0), Vector3.ZERO, false)
	Toon.part(n, Toon.box(Vector3(width + 0.02, 0.17, 0.93)), zn.accent, Vector3(0, 0.74, 0), Vector3.ZERO, false)
	_add_ent(n, "low", lanes, 0.45, z, 0.0, 0.95)


func _add_beam(lanes: Array, z: float, biome: int) -> void:
	var zn: Dictionary = ZONES[biome]
	var n := Node3D.new()
	var x0 := (float(lanes.min()) - float(lanes.max())) * 0.5 * LANE_W - 0.95
	var x1 := (float(lanes.max()) - float(lanes.min())) * 0.5 * LANE_W + 0.95
	var width := x1 - x0
	Toon.part(n, Toon.cyl(0.12, 0.14, 2.7), Color("5c4033"), Vector3(x0, 1.35, 0))
	Toon.part(n, Toon.cyl(0.12, 0.14, 2.7), Color("5c4033"), Vector3(x1, 1.35, 0))
	Toon.part(n, Toon.box(Vector3(width, 1.2, 0.22)), zn.accent, Vector3(0, 1.95, 0))
	Toon.part(n, Toon.box(Vector3(width - 0.3, 0.16, 0.24)), Color("ffffff"), Vector3(0, 1.95, 0), Vector3.ZERO, false)
	_add_ent(n, "beam", lanes, 0.2, z, 0.0, 2.6, 1.35)


func _add_platform(lane: int, z: float, length: float, biome: int) -> void:
	var zn: Dictionary = ZONES[biome]
	var n := Node3D.new()
	var ramp_len := sqrt(RAMP_LEN * RAMP_LEN + PLAT_H * PLAT_H)
	Toon.part(n, Toon.box(Vector3(1.9, 0.25, ramp_len)), zn.accent, Vector3(0, PLAT_H * 0.5 - 0.12, -RAMP_LEN * 0.5), Vector3(atan2(PLAT_H, RAMP_LEN), 0, 0))
	Toon.part(n, Toon.box(Vector3(1.9, PLAT_H, length)), zn.crate, Vector3(0, PLAT_H * 0.5, -RAMP_LEN - length * 0.5))
	Toon.part(n, Toon.box(Vector3(1.94, 0.14, length + 0.02)), zn.accent, Vector3(0, PLAT_H - 0.05, -RAMP_LEN - length * 0.5), Vector3.ZERO, false)
	_add_ent(n, "plat", [lane], 0.0, z, 0.0, PLAT_H, 0.0, length)
	# la entidad debe quedar con el nodo en el borde frontal (z = 0 del nodo)
	n.position.x = _x(lane)
	for i in 5:
		_add_coin(_x(lane), PLAT_H + 0.95, z - RAMP_LEN - 1.5 - i * 1.8)


func _add_ball(lane: int, z: float, biome: int, extra: float) -> void:
	var zn: Dictionary = ZONES[biome]
	var n := Node3D.new()
	var roller := Node3D.new()
	roller.position = Vector3(0, 0.55, 0)
	n.add_child(roller)
	Toon.part(roller, Toon.sphere(0.55), zn.ball, Vector3.ZERO)
	Toon.part(roller, Toon.box(Vector3(0.3, 0.12, 0.3)), Color("00000033"), Vector3(0, 0.5, 0), Vector3(0.4, 0.2, 0.3), false)
	var e := _add_ent(n, "low", [lane], 0.55, z, extra, 1.0)
	e["roller"] = roller


# ---------- Patrones ----------
func _pick(w: Dictionary) -> String:
	var total := 0.0
	for k in w:
		total += float(w[k])
	var r := rng.randf() * total
	for k in w:
		r -= float(w[k])
		if r <= 0.0:
			return k
	return "coins"


func _spawn_pattern(z: float, sd: float) -> float:
	var level := int(sd / ZONE_LEN)
	var biome := level % ZONES.size()

	if fmod(sd, ZONE_LEN) > ZONE_LEN * 0.82 and not event_done.has(level):
		event_done[level] = true
		pending_events.append({"at": sd - 55.0, "text": ZONES[biome].event})
		return _spawn_event(z, biome)

	var w := {"coins": 2.0, "low": 4.0, "beam": 3.0}
	if sd > 150.0:
		w["plat"] = 1.5
	if sd > 300.0 or level >= 1:
		w["double"] = 2.5
		w["moving"] = 2.0
	if level >= 1:
		w["wide"] = 2.0
		w["plat"] = 2.0
	if level >= 2:
		w["double"] = 4.0
		w["moving"] = 3.5
		w["wide"] = 3.0

	var kind := _pick(w)
	var lane := rng.randi_range(0, 2)
	match kind:
		"coins":
			_coin_line(lane, z, 8)
			if rng.randf() < 0.22:
				var k: String = PICKS.keys()[rng.randi() % PICKS.size()]
				_add_pickup(k, (lane + 1) % 3, z - 6.0)
			return 18.0
		"low":
			_add_low([lane], z, biome)
			_add_coin(_x(lane), 1.9, z + 1.8)
			_add_coin(_x(lane), 2.3, z)
			_add_coin(_x(lane), 1.9, z - 1.8)
			_coin_line((lane + rng.randi_range(1, 2)) % 3, z + 2.0, 5)
			return 5.0
		"beam":
			_add_beam([lane], z, biome)
			_coin_line(lane, z + 4.0, 4, 0.8)
			return 6.0
		"double":
			var free_lane := lane
			for l in 3:
				if l == free_lane:
					continue
				if rng.randf() < 0.5:
					_add_low([l], z, biome)
				else:
					_add_beam([l], z, biome)
			_coin_line(free_lane, z + 4.0, 6)
			return 8.0
		"wide":
			if rng.randf() < 0.5:
				_add_low([0, 1, 2], z, biome)
				for l in 3:
					_add_coin(_x(l), 2.1, z)
			else:
				_add_beam([0, 1, 2], z, biome)
				for l in 3:
					_add_coin(_x(l), 0.8, z + 3.0)
			return 6.0
		"plat":
			var length := rng.randf_range(8.0, 13.0)
			_add_platform(lane, z, length, biome)
			return RAMP_LEN + length + 2.0
		"moving":
			_add_ball(lane, z, biome, 6.0)
			_coin_line((lane + 1) % 3, z + 2.0, 5)
			return 7.0
	return 6.0


func _spawn_event(z: float, biome: int) -> float:
	var rows := 7
	var lane := rng.randi_range(0, 2)
	for i in rows:
		lane = clampi(lane + rng.randi_range(-1, 1), 0, 2)
		var rz := z - i * 11.0
		for l in 3:
			if l != lane:
				_add_ball(l, rz, biome, 7.0)
		_coin_line(lane, rz + 3.0, 3, 0.95, 2.0)
	_add_pickup("shield", lane, z - rows * 11.0 - 4.0)
	return rows * 11.0 + 10.0
